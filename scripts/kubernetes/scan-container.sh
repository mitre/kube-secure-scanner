#!/bin/bash
# scan-container.sh - End-to-end script to scan a container with restricted permissions
# Usage: ./scan-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]

set -e

# Check arguments
if [ "$#" -lt 4 ]; then
  echo "Usage: $0 <namespace> <pod-name> <container-name> <profile-path> [threshold_file]"
  echo "Example: $0 inspec-test inspec-target busybox ~/cinc-profiles/linux-baseline /path/to/threshold.yml"
  echo ""
  echo "Parameters:"
  echo "  namespace       - Kubernetes namespace containing the pod"
  echo "  pod-name        - Name of the pod to scan"
  echo "  container-name  - Name of the container within the pod to scan"
  echo "  profile-path    - Path to the CINC Auditor profile"
  echo "  threshold_file  - Optional: Path to threshold.yml or threshold.json file"
  echo "                    If not provided, a default threshold of 70% compliance will be used"
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

# Check if SAF CLI is installed
if ! command -v saf &> /dev/null; then
  echo "MITRE SAF-CLI is not installed. Installing..."
  npm install -g @mitre/saf
fi

echo "Setting up temporary access for scanning ${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME}..."

# Create service account
echo "Creating service account ${SA_NAME}..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${SA_NAME}
  namespace: ${NAMESPACE}
EOF

# Create role
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

# Run CINC Auditor scan
echo "Running CINC Auditor scan against ${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME}..."
KUBECONFIG=${KUBECONFIG_FILE} cinc-auditor exec ${PROFILE_PATH} \
  -t k8s-container://${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} \
  --reporter cli json:${RESULTS_FILE}

SCAN_RESULT=$?

# Process results with SAF-CLI
echo "Processing results with MITRE SAF-CLI..."
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

# Cleanup
echo "Cleaning up temporary resources..."
kubectl delete rolebinding ${BINDING_NAME} -n ${NAMESPACE}
kubectl delete role ${ROLE_NAME} -n ${NAMESPACE}
kubectl delete serviceaccount ${SA_NAME} -n ${NAMESPACE}
rm ${KUBECONFIG_FILE}

# Remove temporary threshold file if we created one
if [ -f "${THRESHOLD_CONFIG_FILE}" ]; then
  rm ${THRESHOLD_CONFIG_FILE}
fi

echo "Scan results saved to: ${RESULTS_FILE}"
echo "Scan summary saved to: ${SUMMARY_FILE}"
echo "Done."
exit ${SCAN_RESULT}