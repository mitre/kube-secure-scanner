#!/bin/bash
# generate-kubeconfig.sh - Creates a kubeconfig file for a specified service account
# Usage: ./generate-kubeconfig.sh <namespace> <service-account-name> [output-file]

set -e

# Check arguments
if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <namespace> <service-account-name> [output-file]"
  echo "Example: $0 inspec-test inspec-scanner ./kubeconfig.yaml"
  exit 1
fi

NAMESPACE=$1
SA_NAME=$2
OUTPUT_FILE=${3:-"./kubeconfig.yaml"}

# Get cluster information
SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')

# Verify service account exists
kubectl get serviceaccount ${SA_NAME} -n ${NAMESPACE} &>/dev/null || {
  echo "Error: Service account ${SA_NAME} not found in namespace ${NAMESPACE}"
  exit 1
}

# Create token
echo "Generating token for ${SA_NAME} in namespace ${NAMESPACE}..."
TOKEN=$(kubectl create token ${SA_NAME} -n ${NAMESPACE})

# Generate kubeconfig
cat > ${OUTPUT_FILE} << EOF
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
    user: ${SA_NAME}
  name: scanner-context
current-context: scanner-context
users:
- name: ${SA_NAME}
  user:
    token: ${TOKEN}
EOF

# Set proper permissions
chmod 600 ${OUTPUT_FILE}

echo "Generated kubeconfig at ${OUTPUT_FILE}"
echo "This configuration will work until the token expires (default: 1 hour)"