#!/bin/bash
# install-all.sh - Helper script to install all CINC Auditor scanner charts
# This script installs the complete stack of charts for container scanning

set -e

# Default values
NAMESPACE="inspec-test"
INSTALL_STANDARD=true
INSTALL_DISTROLESS=true
VALUES_FILE=""
RELEASE_PREFIX="scanner"
TEST_PODS=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --namespace|-n)
      NAMESPACE="$2"
      shift 2
      ;;
    --values|-f)
      VALUES_FILE="$2"
      shift 2
      ;;
    --release-prefix|-p)
      RELEASE_PREFIX="$2"
      shift 2
      ;;
    --no-standard)
      INSTALL_STANDARD=false
      shift
      ;;
    --no-distroless)
      INSTALL_DISTROLESS=false
      shift
      ;;
    --no-test-pods)
      TEST_PODS=false
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [options]"
      echo ""
      echo "Options:"
      echo "  --namespace, -n NAME      Target namespace for deployment (default: inspec-test)"
      echo "  --values, -f FILE         Custom values file to use"
      echo "  --release-prefix, -p NAME Prefix for Helm release names (default: scanner)"
      echo "  --no-standard             Skip standard scanner installation"
      echo "  --no-distroless           Skip distroless scanner installation"
      echo "  --no-test-pods            Don't deploy test pods"
      echo "  --help, -h                Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Construct common value overrides
VALUE_OVERRIDES="--set scanner-infrastructure.targetNamespace=$NAMESPACE"

if [ "$TEST_PODS" = false ]; then
  VALUE_OVERRIDES="$VALUE_OVERRIDES --set testPod.deploy=false"
fi

# Add values file if specified
if [ -n "$VALUES_FILE" ]; then
  VALUE_OVERRIDES="$VALUE_OVERRIDES -f $VALUES_FILE"
fi

echo "Installing CINC Auditor container scanning charts..."
echo "Target namespace: $NAMESPACE"
echo "Test pods enabled: $TEST_PODS"

# Install standard scanner if requested
if [ "$INSTALL_STANDARD" = true ]; then
  echo -e "\nInstalling standard scanner..."
  helm install $RELEASE_PREFIX-standard ./standard-scanner $VALUE_OVERRIDES
fi

# Install distroless scanner if requested
if [ "$INSTALL_DISTROLESS" = true ]; then
  echo -e "\nInstalling distroless scanner..."
  helm install $RELEASE_PREFIX-distroless ./distroless-scanner $VALUE_OVERRIDES
fi

echo -e "\nGenerating kubeconfig file..."
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
$SCRIPT_DIR/../scripts/generate-kubeconfig.sh $NAMESPACE inspec-scanner ./kubeconfig-$NAMESPACE.yaml

echo -e "\nInstallation complete!"
echo "A kubeconfig file has been generated at: ./kubeconfig-$NAMESPACE.yaml"
echo ""
echo "To scan a standard container:"
echo "KUBECONFIG=./kubeconfig-$NAMESPACE.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline -t k8s-container://$NAMESPACE/inspec-target/busybox"
echo ""
echo "To scan a distroless container:"
echo "./scripts/scan-distroless-container.sh $NAMESPACE distroless-target distroless ./examples/cinc-profiles/container-baseline"
echo ""
echo "For more information, see the documentation in ./docs/"