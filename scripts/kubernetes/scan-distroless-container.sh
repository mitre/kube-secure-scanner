#!/bin/bash
# scan-distroless-container.sh - Script to scan distroless containers using ephemeral debug containers
# Usage: ./scan-distroless-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]
# 
# IMPORTANT: This script is a proof-of-concept for scanning distroless containers
# The ephemeral container approach works, but this script requires customization
# for your specific distroless container environment. The current implementation
# contains placeholder code in the scanning section.

set -e

# Check arguments
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <namespace> <pod-name> <container-name> <profile-path> [threshold_file]"
  echo "Example: $0 inspec-test distroless-target app ~/cinc-profiles/linux-baseline /path/to/threshold.yml"
  echo ""
  echo "Parameters:"
  echo "  namespace       - Kubernetes namespace containing the pod"
  echo "  pod-name        - Name of the pod to scan"
  echo "  container-name  - Name of the container within the pod to scan"
  echo "  profile-path    - Path to the CINC Auditor profile"
  echo "  threshold_file  - Optional: Path to threshold.yml or threshold.json file"
  echo "                    If not provided, a default threshold of 70% compliance will be used"
  echo ""
  echo "IMPORTANT: This is a proof-of-concept script that must be customized for your environment."
  echo "           The script currently has placeholder code for the actual scanning part."
  echo "           See the comments in the script and documentation for details."
  exit 1
fi

NAMESPACE=$1
POD_NAME=$2
CONTAINER_NAME=$3
PROFILE_PATH=$4
THRESHOLD_FILE=$5
RUN_ID=$(date +%s)
SA_NAME="scanner-${RUN_ID}"
ROLE_NAME="scanner-role-${RUN_ID}"
BINDING_NAME="scanner-binding-${RUN_ID}"
KUBECONFIG_FILE="./kubeconfig-${RUN_ID}.yaml"
RESULTS_FILE="./scan-results-${RUN_ID}.json"
SUMMARY_FILE="./scan-summary-${RUN_ID}.md"
THRESHOLD_CONFIG_FILE="./threshold-${RUN_ID}.yml"
DEBUG_CONTAINER_NAME="debug-scanner-${RUN_ID}"
DEBUG_IMAGE="alpine:latest"  # Base image for debugging

# Check if SAF CLI is installed
if ! command -v saf &> /dev/null; then
  echo "MITRE SAF-CLI is not installed. Installing..."
  npm install -g @mitre/saf
fi

echo "Setting up temporary access for scanning ${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME}..."

# Create service account with ephemeral container permissions
echo "Creating service account ${SA_NAME}..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${SA_NAME}
  namespace: ${NAMESPACE}
EOF

# Create role with ephemeral container permissions
echo "Creating role ${ROLE_NAME}..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ${ROLE_NAME}
  namespace: ${NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/ephemeralcontainers"]
  verbs: ["get", "create", "update"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["${POD_NAME}"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
  resourceNames: ["${POD_NAME}"]
EOF

# Create role binding
echo "Creating role binding ${BINDING_NAME}..."
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${BINDING_NAME}
  namespace: ${NAMESPACE}
subjects:
- kind: ServiceAccount
  name: ${SA_NAME}
  namespace: ${NAMESPACE}
roleRef:
  kind: Role
  name: ${ROLE_NAME}
  apiGroup: rbac.authorization.k8s.io
EOF

# Wait for permissions to propagate
echo "Waiting for permissions to propagate..."
sleep 3

# Create kubeconfig
echo "Generating kubeconfig..."
TOKEN=$(kubectl create token ${SA_NAME} -n ${NAMESPACE})
SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')

cat > ${KUBECONFIG_FILE} << EOF
apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    server: ${SERVER}
    certificate-authority-data: ${CA_DATA}
  name: scanner-cluster
contexts:
- context:
    cluster: scanner-cluster
    namespace: ${NAMESPACE}
    user: scanner-user
  name: scanner-context
current-context: scanner-context
users:
- name: scanner-user
  user:
    token: ${TOKEN}
EOF

chmod 600 ${KUBECONFIG_FILE}

# Detect if container is distroless
echo "Detecting if container is distroless..."
if ! KUBECONFIG=${KUBECONFIG_FILE} kubectl exec -n ${NAMESPACE} ${POD_NAME} -c ${CONTAINER_NAME} -- /bin/sh -c "echo test" &>/dev/null; then
  echo "Detected distroless container, using ephemeral container approach"
  
  # Create ephemeral container
  echo "Creating ephemeral debug container..."
  KUBECONFIG=${KUBECONFIG_FILE} kubectl debug ${POD_NAME} -n ${NAMESPACE} \
    --image=${DEBUG_IMAGE} \
    --target=${CONTAINER_NAME} \
    --container=${DEBUG_CONTAINER_NAME} \
    --quiet -it -- sleep 3600 &
  
  EPHEMERAL_PID=$!
  
  # Wait for ephemeral container to be ready
  echo "Waiting for ephemeral container to be ready..."
  sleep 5
  
  # Verify ephemeral container is running
  if ! KUBECONFIG=${KUBECONFIG_FILE} kubectl get pod ${POD_NAME} -n ${NAMESPACE} -o jsonpath='{.status.ephemeralContainerStatuses[0].name}' 2>/dev/null | grep -q ${DEBUG_CONTAINER_NAME}; then
    echo "❌ ERROR: Ephemeral container failed to start. Check if ephemeral containers are supported in your cluster."
    echo "   Kubernetes version 1.23+ is required for this feature."
    
    # Clean up and exit
    kill ${EPHEMERAL_PID} 2>/dev/null || true
    kubectl delete rolebinding ${BINDING_NAME} -n ${NAMESPACE} 2>/dev/null || true
    kubectl delete role ${ROLE_NAME} -n ${NAMESPACE} 2>/dev/null || true
    kubectl delete serviceaccount ${SA_NAME} -n ${NAMESPACE} 2>/dev/null || true
    rm -f ${KUBECONFIG_FILE} 2>/dev/null || true
    
    exit 1
  fi
  
  echo "✅ Ephemeral container is running successfully"
  
  ##############################################################################
  # IMPORTANT: PLACEHOLDER CODE - REQUIRES CUSTOMIZATION                       #
  # The following section contains placeholder code that demonstrates the      #
  # approach but does not actually implement the scanning functionality.       #
  # You need to customize this section for your specific distroless container. #
  ##############################################################################
  
  echo -e "\n⚠️  WARNING: PLACEHOLDER CODE SECTION ⚠️"
  echo "This script contains placeholder code and will not perform a real scan yet."
  echo "See the documentation at docs/distroless-containers.md for implementation details."
  echo -e "You need to customize this script for your specific environment.\n"
  
  echo "DEMONSTRATION: Running simulated CINC Auditor scan through ephemeral container..."
  
  # Generate a dummy results file for demonstration
  cat > ${RESULTS_FILE} << EOF
{
  "platform": {
    "name": "k8s-container",
    "release": "ephemeral-container-demo"
  },
  "profiles": [
    {
      "name": "container-baseline",
      "version": "1.0.0",
      "title": "Container Baseline (Simulated)",
      "summary": "Demonstration of distroless container scanning",
      "supports": [],
      "controls": [
        {
          "id": "demo-1",
          "title": "Simulated control 1",
          "desc": "This is a simulated control for demonstration purposes",
          "impact": 0.7,
          "results": [{"status": "passed"}]
        },
        {
          "id": "demo-2",
          "title": "Simulated control 2",
          "desc": "This is a simulated control for demonstration purposes",
          "impact": 0.5,
          "results": [{"status": "passed"}]
        }
      ],
      "groups": [],
      "status": "loaded",
      "status_message": "Loaded"
    }
  ],
  "statistics": {
    "duration": 0.1,
    "controls": {
      "total": 2,
      "passed": {
        "total": 2
      },
      "skipped": {
        "total": 0
      },
      "failed": {
        "total": 0
      }
    }
  },
  "version": "4.38.9"
}
EOF
  
  SCAN_RESULT=0
  
  # TODO: Implement the actual scan using one of these approaches:
  #
  # OPTION 1: Modified train-k8s-container plugin
  # This option requires forking and modifying the plugin to support ephemeral containers
  # - Detect distroless containers and use ephemeral containers automatically
  # - Use the same transport syntax for consistency
  # Example:
  # KUBECONFIG=${KUBECONFIG_FILE} cinc-auditor exec ${PROFILE_PATH} \
  #   -t k8s-container://${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} \
  #   --reporter cli json:${RESULTS_FILE}
  #
  # OPTION 2: Direct access through ephemeral container
  # Use the ephemeral container directly to access the target container's filesystem
  # This might involve:
  # - Using the process namespace to access the target container's filesystem
  # - Executing InSpec in the ephemeral container
  # - Mounting volumes to share results
  
  echo -e "\n⚠️  END OF PLACEHOLDER CODE SECTION ⚠️\n"
  
  # Clean up ephemeral container
  echo "Cleaning up ephemeral container..."
  kill ${EPHEMERAL_PID} 2>/dev/null || true
  
else
  # Standard container scanning
  echo "Container has shell, using standard scanning approach..."
  echo "Running CINC Auditor scan against ${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME}..."
  KUBECONFIG=${KUBECONFIG_FILE} cinc-auditor exec ${PROFILE_PATH} \
    -t k8s-container://${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} \
    --reporter cli json:${RESULTS_FILE}
  
  SCAN_RESULT=$?
fi

# Process results with SAF-CLI
# Note: This assumes that results were successfully generated
# In a real implementation, this would need to be adapted for ephemeral container results
echo "Processing results with MITRE SAF-CLI..."
if [ -f "${RESULTS_FILE}" ]; then
  saf summary --input ${RESULTS_FILE} --output-md ${SUMMARY_FILE}
  
  # Display summary
  echo "============= SCAN SUMMARY ============="
  cat ${SUMMARY_FILE}
  echo "========================================"
  
  # Apply threshold check
  if [ -n "${THRESHOLD_FILE}" ] && [ -f "${THRESHOLD_FILE}" ]; then
    # Use provided threshold file
    echo "Checking against threshold configuration in ${THRESHOLD_FILE}..."
    saf threshold -i ${RESULTS_FILE} -t ${THRESHOLD_FILE}
    THRESHOLD_RESULT=$?
  else
    # Create a default threshold configuration with 70% compliance minimum
    echo "No threshold file provided. Using default threshold (70% compliance)..."
    cat > ${THRESHOLD_CONFIG_FILE} << EOF
compliance:
  min: 70
EOF
    saf threshold -i ${RESULTS_FILE} -t ${THRESHOLD_CONFIG_FILE}
    THRESHOLD_RESULT=$?
  fi
  
  if [ $THRESHOLD_RESULT -eq 0 ]; then
    echo "✅ Security scan passed threshold requirements"
  else
    echo "❌ Security scan failed to meet threshold requirements"
    # Return the threshold failure as the script exit code
    SCAN_RESULT=${THRESHOLD_RESULT}
  fi
else
  echo "❌ No results file was generated. Scan may have failed."
  SCAN_RESULT=1
fi

# Cleanup
echo "Cleaning up temporary resources..."
kubectl delete rolebinding ${BINDING_NAME} -n ${NAMESPACE} 2>/dev/null || true
kubectl delete role ${ROLE_NAME} -n ${NAMESPACE} 2>/dev/null || true
kubectl delete serviceaccount ${SA_NAME} -n ${NAMESPACE} 2>/dev/null || true
rm -f ${KUBECONFIG_FILE} 2>/dev/null || true

# Remove temporary threshold file if we created one
if [ -f "${THRESHOLD_CONFIG_FILE}" ]; then
  rm -f ${THRESHOLD_CONFIG_FILE} 2>/dev/null || true
fi

echo "Scan results saved to: ${RESULTS_FILE}"
echo "Scan summary saved to: ${SUMMARY_FILE}"
echo "Done."

if [[ ! KUBECONFIG=${KUBECONFIG_FILE} kubectl exec -n ${NAMESPACE} ${POD_NAME} -c ${CONTAINER_NAME} -- /bin/sh -c "echo test" &>/dev/null ]]; then
  echo ""
  echo "⚠️  IMPORTANT: This was a simulated scan for a distroless container"
  echo "   The generated results are placeholder data only."
  echo "   To implement a real scan, customize the script according to the documentation."
fi

exit ${SCAN_RESULT}