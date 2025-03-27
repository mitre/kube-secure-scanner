#!/bin/bash
# setup-minikube.sh - Sets up a 3-node minikube cluster for secure container scanning research
# Usage: ./setup-minikube.sh [--driver=<driver>] [--k8s-version=<version>] [--profile=<name>]

set -e

# Default values
DRIVER="docker"
K8S_VERSION="v1.28.3"
MINIKUBE_VERSION="v1.32.0"
NODES=3
PROFILE="minikube"
DEPLOY_METHOD="all"  # Options: all, manual, helm, none
INSTALL_DEPS=false   # Whether to attempt installing dependencies
DEPLOY_DISTROLESS=false  # Whether to deploy a distroless test pod

# Color codes for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
for arg in "$@"; do
  case $arg in
    --driver=*)
      DRIVER="${arg#*=}"
      ;;
    --k8s-version=*)
      K8S_VERSION="${arg#*=}"
      ;;
    --minikube-version=*)
      MINIKUBE_VERSION="${arg#*=}"
      ;;
    --nodes=*)
      NODES="${arg#*=}"
      ;;
    --profile=*)
      PROFILE="${arg#*=}"
      ;;
    --deploy=*)
      DEPLOY_METHOD="${arg#*=}"
      ;;
    --install-deps)
      INSTALL_DEPS=true
      ;;
    --with-distroless)
      DEPLOY_DISTROLESS=true
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Sets up a multi-node minikube cluster for secure container scanning research,"
      echo "configures RBAC permissions, and deploys test pods for scanning."
      echo ""
      echo "Options:"
      echo "  --driver=<driver>           Driver to use for minikube (default: docker)"
      echo "  --k8s-version=<version>     Kubernetes version to use (default: v1.28.3)"
      echo "  --minikube-version=<version> Minikube version to use (default: v1.32.0)"
      echo "  --nodes=<count>             Number of nodes in the cluster (default: 3)"
      echo "  --profile=<name>            Minikube profile name (default: minikube)"
      echo "  --deploy=<method>           Deployment method (all, manual, helm, none) (default: all)"
      echo "  --install-deps              Attempt to install missing dependencies"
      echo "  --with-distroless           Deploy a distroless test pod as well"
      echo ""
      echo "Examples:"
      echo "  $0 --driver=docker --nodes=3                # Standard 3-node setup with docker driver"
      echo "  $0 --k8s-version=v1.29.1 --deploy=helm     # Use K8s v1.29.1 and deploy using Helm only"
      echo "  $0 --profile=inspec-scanner --nodes=2      # Create a 2-node cluster with custom profile name"
      echo "  $0 --install-deps                          # Install missing dependencies"
      echo "  $0 --with-distroless                       # Also deploy a distroless container for testing"
      exit 0
      ;;
    *)
      echo -e "${RED}Unknown option: $arg${NC}"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

#########################
# Dependency Management #
#########################

# Function to check and optionally install dependencies
check_dependency() {
  local cmd="$1"
  local name="$2"
  local install_cmd="$3"
  local install_url="$4"
  
  # Check if the command is available
  if ! command -v "$cmd" &> /dev/null; then
    echo -e "${YELLOW}⚠️ $name is not installed${NC}"
    
    if [ "$INSTALL_DEPS" = true ]; then
      echo -e "${BLUE}🔄 Installing $name...${NC}"
      eval "$install_cmd" || {
        echo -e "${RED}❌ Failed to install $name${NC}"
        echo -e "${YELLOW}Please install manually: $install_url${NC}"
        return 1
      }
      echo -e "${GREEN}✅ $name installed successfully${NC}"
    else
      echo -e "${YELLOW}To install: $install_cmd${NC}"
      echo -e "${YELLOW}Or visit: $install_url${NC}"
      return 1
    fi
  else
    echo -e "${GREEN}✅ $name is installed${NC}"
    return 0
  fi
}

# Print header
echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  SECURE CONTAINER SCANNING - MINIKUBE SETUP      ${NC}"
echo -e "${BLUE}==================================================${NC}"
echo ""
echo -e "${YELLOW}Checking required dependencies...${NC}"
echo ""

# Check for essential dependencies
check_dependency "minikube" "Minikube" \
  "curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && sudo install minikube-linux-amd64 /usr/local/bin/minikube && rm minikube-linux-amd64" \
  "https://minikube.sigs.k8s.io/docs/start/"

# Exit if minikube is not installed and couldn't be installed
if [ $? -ne 0 ]; then
  echo -e "${RED}❌ Minikube is required to continue. Please install it first.${NC}"
  exit 1
fi

# Check for kubectl
check_dependency "kubectl" "kubectl" \
  "curl -LO \"https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\" && sudo install kubectl /usr/local/bin/kubectl && rm kubectl" \
  "https://kubernetes.io/docs/tasks/tools/"

# Exit if kubectl is not installed and couldn't be installed
if [ $? -ne 0 ]; then
  echo -e "${RED}❌ kubectl is required to continue. Please install it first.${NC}"
  exit 1
fi

# Check for helm if needed
if [[ "$DEPLOY_METHOD" == "all" || "$DEPLOY_METHOD" == "helm" ]]; then
  check_dependency "helm" "Helm" \
    "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash" \
    "https://helm.sh/docs/intro/install/"
  
  # Exit if helm is required but not installed
  if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Helm is required for the selected deployment method. Please install it first.${NC}"
    exit 1
  fi
fi

# Check for scanning tools (not required immediately but will be needed later)
CINC_INSTALLED=false
check_dependency "cinc-auditor" "CINC Auditor" \
  "curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor" \
  "https://cinc.sh/start/auditor/"

if [ $? -eq 0 ]; then
  CINC_INSTALLED=true
  
  # Check for the train-k8s-container plugin
  echo -e "${YELLOW}Checking for train-k8s-container plugin...${NC}"
  if ! cinc-auditor plugin list | grep -q "train-k8s-container"; then
    echo -e "${YELLOW}⚠️ The train-k8s-container plugin is not installed${NC}"
    
    if [ "$INSTALL_DEPS" = true ]; then
      echo -e "${BLUE}🔄 Installing train-k8s-container plugin...${NC}"
      cinc-auditor plugin install train-k8s-container || {
        echo -e "${RED}❌ Failed to install train-k8s-container plugin${NC}"
        echo -e "${YELLOW}Please install manually: cinc-auditor plugin install train-k8s-container${NC}"
      }
    else
      echo -e "${YELLOW}To install: cinc-auditor plugin install train-k8s-container${NC}"
    fi
  else
    echo -e "${GREEN}✅ train-k8s-container plugin is installed${NC}"
  fi
fi

# Check for SAF CLI
check_dependency "saf" "MITRE SAF CLI" \
  "npm install -g @mitre/saf" \
  "https://saf-cli.mitre.org/"

# Additional dependencies summary
echo ""
echo -e "${BLUE}Dependency Summary:${NC}"
if [ "$CINC_INSTALLED" = true ]; then
  if cinc-auditor plugin list | grep -q "train-k8s-container"; then
    echo -e "${GREEN}✅ CINC Auditor with train-k8s-container: Ready${NC}"
  else
    echo -e "${YELLOW}⚠️ CINC Auditor: Installed, but missing train-k8s-container plugin${NC}"
  fi
else
  echo -e "${YELLOW}⚠️ CINC Auditor: Not installed (required for scanning)${NC}"
fi

if command -v saf &> /dev/null; then
  echo -e "${GREEN}✅ MITRE SAF CLI: Ready${NC}"
else
  echo -e "${YELLOW}⚠️ MITRE SAF CLI: Not installed (recommended for results analysis)${NC}"
fi

echo ""

########################
# Minikube Setup Phase #
########################

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  SETTING UP MINIKUBE CLUSTER                     ${NC}"
echo -e "${BLUE}==================================================${NC}"

# Check if the specified profile is already running
if minikube status -p "$PROFILE" &>/dev/null; then
    echo -e "${YELLOW}🔄 Minikube profile '$PROFILE' is already running. Stopping and resetting...${NC}"
    minikube stop -p "$PROFILE"
    minikube delete -p "$PROFILE"
fi

# Start minikube with specified driver and node count
echo -e "${BLUE}🚀 Starting minikube with ${NODES} nodes using $DRIVER driver...${NC}"
minikube start --driver=${DRIVER} \
              --kubernetes-version=${K8S_VERSION} \
              --nodes=${NODES} \
              -p ${PROFILE}

# Verify the setup
echo -e "${GREEN}✅ Cluster is up and running!${NC}"
echo -e "${BLUE}📋 Node status:${NC}"
kubectl get nodes -o wide

# Show cluster info
echo -e "${BLUE}📋 Cluster info:${NC}"
kubectl cluster-info

########################
# Deployment Phase     #
########################

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  DEPLOYING SCANNING INFRASTRUCTURE                ${NC}"
echo -e "${BLUE}==================================================${NC}"

if [[ "$DEPLOY_METHOD" == "all" || "$DEPLOY_METHOD" == "manual" ]]; then
    echo -e "${BLUE}📦 Deploying components using kubectl...${NC}"
    
    # Create namespace
    echo -e "${YELLOW}Creating namespace...${NC}"
    kubectl create namespace inspec-test
    
    # Create service account
    echo -e "${YELLOW}Creating service account...${NC}"
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: inspec-scanner
  namespace: inspec-test
EOF
    
    # Create role with ephemeral containers support for distroless scanning
    echo -e "${YELLOW}Creating RBAC role...${NC}"
    cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: inspec-container-role
  namespace: inspec-test
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
- apiGroups: [""]
  resources: ["pods/ephemeralcontainers"]
  verbs: ["get", "create", "update", "patch"]
EOF
    
    # Create role binding
    echo -e "${YELLOW}Creating role binding...${NC}"
    cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: inspec-container-rolebinding
  namespace: inspec-test
subjects:
- kind: ServiceAccount
  name: inspec-scanner
  namespace: inspec-test
roleRef:
  kind: Role
  name: inspec-container-role
  apiGroup: rbac.authorization.k8s.io
EOF
    
    # Create test pod
    echo -e "${YELLOW}Creating test pod...${NC}"
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: inspec-target
  namespace: inspec-test
  labels:
    app: inspec-target
    scan-target: "true"
spec:
  containers:
  - name: busybox
    image: busybox:latest
    command: ["sleep", "infinity"]
EOF
    
    # Create distroless test pod if requested
    if [ "$DEPLOY_DISTROLESS" = true ]; then
      echo -e "${YELLOW}Creating distroless test pod...${NC}"
      cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: distroless-target
  namespace: inspec-test
  labels:
    app: distroless-target
    scan-target: "true"
    distroless: "true"
spec:
  containers:
  - name: distroless
    image: gcr.io/distroless/static-debian11:latest
    command: ["/bin/sleep", "infinity"]
EOF
    fi
    
    # Wait for pods to be ready
    echo -e "${YELLOW}⏳ Waiting for test pod to be ready...${NC}"
    kubectl wait --for=condition=ready pod/inspec-target -n inspec-test --timeout=60s
    
    if [ "$DEPLOY_DISTROLESS" = true ]; then
      echo -e "${YELLOW}⏳ Waiting for distroless test pod to be ready...${NC}"
      kubectl wait --for=condition=ready pod/distroless-target -n inspec-test --timeout=60s || {
        echo -e "${YELLOW}⚠️ Warning: Distroless pod didn't reach ready state. This may be expected for some distroless images.${NC}"
      }
    fi
    
    echo -e "${GREEN}✅ Manual deployment complete!${NC}"
fi

if [[ "$DEPLOY_METHOD" == "all" || "$DEPLOY_METHOD" == "helm" ]]; then
    echo -e "${BLUE}📦 Deploying components using Helm...${NC}"
    
    # Standard container scanning
    if [[ "$DEPLOY_METHOD" == "all" || "$DEPLOY_DISTROLESS" = false ]]; then
        echo -e "${YELLOW}Installing standard-scanner Helm chart...${NC}"
        helm install standard-scanner ./helm-charts/standard-scanner \
          --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
          --set testPod.deploy=true \
          --set testPod.name=inspec-target-helm
        
        # Wait for pod to be ready
        echo -e "${YELLOW}⏳ Waiting for standard test pod to be ready...${NC}"
        kubectl wait --for=condition=ready pod/inspec-target-helm -n inspec-test --timeout=60s
        
        echo -e "${GREEN}✅ Standard scanner deployment complete!${NC}"
    fi
    
    # Distroless container scanning
    if [ "$DEPLOY_DISTROLESS" = true ]; then
        echo -e "${YELLOW}Installing distroless-scanner Helm chart...${NC}"
        helm install distroless-scanner ./helm-charts/distroless-scanner \
          --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
          --set testPod.deploy=true \
          --set testPod.name=distroless-target-helm
        
        # Wait for pod to be ready
        echo -e "${YELLOW}⏳ Waiting for distroless test pod to be ready...${NC}"
        kubectl wait --for=condition=ready pod/distroless-target-helm -n inspec-test --timeout=60s || {
            echo -e "${YELLOW}⚠️ Warning: Distroless pod didn't reach ready state. This may be expected for some distroless images.${NC}"
        }
        
        echo -e "${GREEN}✅ Distroless scanner deployment complete!${NC}"
    fi
    
    echo -e "${GREEN}✅ Helm deployment complete!${NC}"
fi

# Generate a kubeconfig file
echo -e "${BLUE}🔑 Generating kubeconfig file...${NC}"
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml

########################
# Validation Phase     #
########################

echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  VALIDATING SETUP                                 ${NC}"
echo -e "${BLUE}==================================================${NC}"

# Show deployed resources
echo -e "${YELLOW}Deployed pods:${NC}"
kubectl get pods -n inspec-test

echo -e "${YELLOW}Service accounts:${NC}"
kubectl get serviceaccounts -n inspec-test

echo -e "${YELLOW}RBAC configuration:${NC}"
kubectl get roles,rolebindings -n inspec-test

# Validate generated kubeconfig
echo -e "${YELLOW}Testing kubeconfig file...${NC}"
if KUBECONFIG=./kubeconfig.yaml kubectl get pods -n inspec-test &>/dev/null; then
  echo -e "${GREEN}✅ Kubeconfig validation successful!${NC}"
else
  echo -e "${RED}❌ Kubeconfig validation failed. There might be an issue with the token or permissions.${NC}"
fi

# Setup complete!
echo ""
echo -e "${GREEN}🎉 Minikube setup complete! Your ${NODES}-node cluster is ready for container scanning research.${NC}"
echo ""
echo -e "${BLUE}📋 Configuration Summary:${NC}"
echo -e "  • Minikube Profile: ${PROFILE}"
echo -e "  • Kubernetes Version: ${K8S_VERSION}"
echo -e "  • Nodes: ${NODES}"
echo -e "  • Driver: ${DRIVER}"
echo -e "  • Namespace: inspec-test"
echo -e "  • Service Account: inspec-scanner"
echo -e "  • Kubeconfig: ./kubeconfig.yaml"
echo -e "  • Test Pod(s):"

if [[ "$DEPLOY_METHOD" == "all" || "$DEPLOY_METHOD" == "manual" ]]; then
    echo -e "    - inspec-target (Manual deployment)"
    if [ "$DEPLOY_DISTROLESS" = true ]; then
      echo -e "    - distroless-target (Manual deployment, distroless)"
    fi
fi

if [[ "$DEPLOY_METHOD" == "all" || "$DEPLOY_METHOD" == "helm" ]]; then
    echo -e "    - inspec-target-helm (Helm deployment)"
    if [ "$DEPLOY_DISTROLESS" = true ]; then
      echo -e "    - distroless-target-helm (Helm deployment, distroless)"
    fi
fi

echo ""
echo -e "${BLUE}==================================================${NC}"
echo -e "${BLUE}  NEXT STEPS                                       ${NC}"
echo -e "${BLUE}==================================================${NC}"
echo ""

if [ "$CINC_INSTALLED" = true ] && cinc-auditor plugin list | grep -q "train-k8s-container"; then
  echo -e "${GREEN}You're ready to run container scans! Here's what you can do next:${NC}"
else
  echo -e "${YELLOW}Before running scans, please install:${NC}"
  echo -e "  • CINC Auditor: curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor"
  echo -e "  • train-k8s-container plugin: cinc-auditor plugin install train-k8s-container"
  echo ""
fi

echo -e "${YELLOW}1. Run a basic container scan:${NC}"
echo -e "   KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \\"
echo -e "     -t k8s-container://inspec-test/inspec-target/busybox"
echo ""

echo -e "${YELLOW}2. Run a comprehensive scan with results processing:${NC}"
echo -e "   ./scripts/scan-container.sh inspec-test inspec-target busybox ./examples/cinc-profiles/container-baseline"
echo ""

if [ "$DEPLOY_DISTROLESS" = true ]; then
  echo -e "${YELLOW}3. For distroless container scanning:${NC}"
  echo -e "   ./scripts/scan-distroless-container.sh inspec-test distroless-target distroless ./examples/cinc-profiles/container-baseline"
  echo ""
fi

echo -e "${YELLOW}For more information, see:${NC}"
echo -e "  • Project documentation in the docs/ directory"
echo -e "  • Script usage: ./scripts/scan-container.sh --help"
if [ "$DEPLOY_DISTROLESS" = true ]; then
  echo -e "  • Distroless docs: ./docs/distroless-containers.md"
fi
echo ""

echo -e "${BLUE}==================================================${NC}"
echo -e "${GREEN}Setup Complete! Happy Scanning!${NC}"
echo -e "${BLUE}==================================================${NC}"