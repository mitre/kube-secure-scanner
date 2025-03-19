#!/bin/bash
# scan-with-sidecar.sh - Deploy and scan a target container using a scanner sidecar with shared process namespace
# Usage: ./scan-with-sidecar.sh <namespace> <target-image> <profile-path> [threshold_file]

set -e

# Check arguments
if [ "$#" -lt 3 ]; then
  echo "Usage: $0 <namespace> <target-image> <profile-path> [threshold_file]"
  echo "Example: $0 inspec-test busybox:latest ~/cinc-profiles/linux-baseline /path/to/threshold.yml"
  echo ""
  echo "Parameters:"
  echo "  namespace       - Kubernetes namespace for the pod"
  echo "  target-image    - Container image to scan (e.g., busybox:latest, myapp:1.0)"
  echo "  profile-path    - Path to the CINC Auditor profile"
  echo "  threshold_file  - Optional: Path to threshold.yml or threshold.json file"
  echo "                    If not provided, a default threshold of 70% compliance will be used"
  exit 1
fi

NAMESPACE=$1
TARGET_IMAGE=$2
PROFILE_PATH=$3
THRESHOLD_FILE=$4
RUN_ID=$(date +%s)
POD_NAME="sidecar-scanner-${RUN_ID}"
CINC_PROFILE_NAME=$(basename "${PROFILE_PATH}")
TARGET_PROCESS="sleep 3600"  # Default process to look for
RESULTS_DIR="./scan-results-${RUN_ID}"
THRESHOLD_CONFIG_FILE="${RESULTS_DIR}/threshold.yml"

# Create results directory
mkdir -p "${RESULTS_DIR}"

# Check if namespace exists, create if not
kubectl get namespace "${NAMESPACE}" > /dev/null 2>&1 || kubectl create namespace "${NAMESPACE}"

# Create ConfigMap for CINC profile
echo "Creating ConfigMap for CINC Auditor profile..."
if [ -d "${PROFILE_PATH}" ]; then
  kubectl create configmap "inspec-profile-${RUN_ID}" --from-file="${PROFILE_PATH}" -n "${NAMESPACE}"
  PROFILE_MOUNT_PATH="/opt/profiles"
  PROFILE_REF="${CINC_PROFILE_NAME}"
else
  # Single file profile
  PROFILE_BASE=$(basename "${PROFILE_PATH}")
  kubectl create configmap "inspec-profile-${RUN_ID}" --from-file="${PROFILE_BASE}=${PROFILE_PATH}" -n "${NAMESPACE}"
  PROFILE_MOUNT_PATH="/opt/profiles"
  PROFILE_REF="${PROFILE_BASE}"
fi

# Create ConfigMap for threshold
if [ -n "${THRESHOLD_FILE}" ] && [ -f "${THRESHOLD_FILE}" ]; then
  # Use provided threshold file
  echo "Creating ConfigMap for threshold configuration..."
  kubectl create configmap "inspec-threshold-${RUN_ID}" --from-file="threshold.yml=${THRESHOLD_FILE}" -n "${NAMESPACE}"
else
  # Create a default threshold configuration with 70% compliance minimum
  echo "No threshold file provided. Using default threshold (70% compliance)..."
  cat > "${THRESHOLD_CONFIG_FILE}" << EOF
compliance:
  min: 70
failed:
  critical:
    max: 0
EOF
  kubectl create configmap "inspec-threshold-${RUN_ID}" --from-file="threshold.yml=${THRESHOLD_CONFIG_FILE}" -n "${NAMESPACE}"
fi

echo "Deploying pod with scanner sidecar..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
  namespace: ${NAMESPACE}
  labels:
    app: scanner-pod
    run-id: "${RUN_ID}"
spec:
  shareProcessNamespace: true  # Enable shared process namespace
  containers:
  # Target container to be scanned
  - name: target
    image: ${TARGET_IMAGE}
    command: ["sleep", "3600"]
    
  # CINC Auditor scanner sidecar
  - name: scanner
    image: ruby:3.0-slim
    command: 
    - "/bin/bash"
    - "-c"
    - |
      # Install dependencies
      apt-get update
      apt-get install -y curl gnupg procps nodejs npm
      
      # Install CINC Auditor
      curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor
      
      # Install SAF CLI
      npm install -g @mitre/saf
      
      # Wait for the main container to start
      sleep 10
      
      echo "Starting CINC Auditor scan..."
      
      # Find the main process of the target container
      TARGET_PID=\$(ps aux | grep -v grep | grep "${TARGET_PROCESS}" | head -1 | awk '{print \$2}')
      
      if [ -z "\$TARGET_PID" ]; then
        echo "ERROR: Could not find target process"
        exit 1
      fi
      
      echo "Target process identified: PID \$TARGET_PID"
      
      # Run CINC Auditor against the target filesystem
      cd /
      cinc-auditor exec ${PROFILE_MOUNT_PATH}/${PROFILE_REF} \
        -b os=linux \
        --target=/proc/\$TARGET_PID/root \
        --reporter cli json:/results/scan-results.json
      
      SCAN_EXIT_CODE=\$?
      
      echo "Scan completed with exit code: \$SCAN_EXIT_CODE"
      
      # Process results with SAF
      if [ -f "/results/scan-results.json" ]; then
        echo "Processing results with SAF CLI..."
        saf summary --input /results/scan-results.json --output-md /results/scan-summary.md
        
        # Validate against threshold
        if [ -f "/opt/thresholds/threshold.yml" ]; then.
          echo "Validating against threshold..."
          saf threshold -i /results/scan-results.json -t /opt/thresholds/threshold.yml
          THRESHOLD_RESULT=\$?
          echo "\$THRESHOLD_RESULT" > /results/threshold-result.txt
        fi
      fi
      
      # Indicate scan is complete
      touch /results/scan-complete
      
      # Keep container running briefly to allow result retrieval
      echo "Scan complete. Results available in /results directory."
      sleep 300
    volumeMounts:
    - name: shared-results
      mountPath: /results
    - name: profiles
      mountPath: /opt/profiles
    - name: thresholds
      mountPath: /opt/thresholds
  
  volumes:
  - name: shared-results
    emptyDir: {}
  - name: profiles
    configMap:
      name: inspec-profile-${RUN_ID}
  - name: thresholds
    configMap:
      name: inspec-threshold-${RUN_ID}
EOF

# Wait for pod to be ready
echo "Waiting for pod to be ready..."
kubectl wait --for=condition=ready pod/${POD_NAME} -n ${NAMESPACE} --timeout=300s

# Wait for scan to complete
echo "Waiting for scan to complete..."
until kubectl exec -it ${POD_NAME} -n ${NAMESPACE} -c scanner -- ls /results/scan-complete >/dev/null 2>&1; do
  echo "Scan in progress..."
  sleep 5
done

# Retrieve scan results
echo "Retrieving scan results..."
kubectl cp ${NAMESPACE}/${POD_NAME}:/results/scan-results.json "${RESULTS_DIR}/scan-results.json" -c scanner
kubectl cp ${NAMESPACE}/${POD_NAME}:/results/scan-summary.md "${RESULTS_DIR}/scan-summary.md" -c scanner

# Check threshold result
if kubectl exec -it ${POD_NAME} -n ${NAMESPACE} -c scanner -- cat /results/threshold-result.txt >/dev/null 2>&1; then
  THRESHOLD_RESULT=$(kubectl exec -it ${POD_NAME} -n ${NAMESPACE} -c scanner -- cat /results/threshold-result.txt)
  echo "THRESHOLD_RESULT=${THRESHOLD_RESULT}" > "${RESULTS_DIR}/threshold-result.txt"
  
  if [ "${THRESHOLD_RESULT}" -eq 0 ]; then
    echo "✅ Security scan passed threshold requirements"
  else
    echo "❌ Security scan failed to meet threshold requirements"
  fi
else
  echo "Warning: Threshold result not found"
  echo "THRESHOLD_RESULT=1" > "${RESULTS_DIR}/threshold-result.txt"
fi

# Display summary
echo "============= SCAN SUMMARY ============="
cat "${RESULTS_DIR}/scan-summary.md"
echo "========================================"

# Ask if we should cleanup
read -p "Do you want to cleanup the pod and ConfigMaps? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Cleaning up resources..."
  kubectl delete pod/${POD_NAME} -n ${NAMESPACE}
  kubectl delete configmap/inspec-profile-${RUN_ID} -n ${NAMESPACE}
  kubectl delete configmap/inspec-threshold-${RUN_ID} -n ${NAMESPACE}
  echo "Cleanup complete."
else
  echo "Resources not cleaned up. You can manually delete them with:"
  echo "kubectl delete pod/${POD_NAME} -n ${NAMESPACE}"
  echo "kubectl delete configmap/inspec-profile-${RUN_ID} -n ${NAMESPACE}"
  echo "kubectl delete configmap/inspec-threshold-${RUN_ID} -n ${NAMESPACE}"
fi

echo "Scan results saved to: ${RESULTS_DIR}"
echo "Done."