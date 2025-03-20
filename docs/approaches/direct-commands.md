# Helper Scripts vs. Direct Commands

This document explains how to use both our helper scripts and the equivalent direct commands for container scanning operations.

## Understanding the Two Approaches

Our container scanning solution can be used in two ways:

1. **Helper Scripts**: Easy-to-use wrapper scripts that handle the complexity
2. **Direct Commands**: Using the underlying tools directly for more control

## Container Scanning with Helper Scripts vs. Direct Commands

### Setup Minikube for Testing

| Helper Script | Direct Commands |
|---------------|-----------------|
| `./scripts/setup-minikube.sh --nodes=2 --with-distroless` | ```bash<br>minikube start --nodes=2<br>kubectl create namespace inspec-test<br>kubectl -n inspec-test create serviceaccount inspec-scanner<br># Create RBAC manually with kubectl apply<br>``` |

### Creating Scanning Infrastructure

#### With Helper Scripts

```bash
# Install all components with a single script
./helm-charts/install-all.sh --namespace inspec-test
```

#### With Direct Commands

```bash
# Install each component separately
kubectl create namespace inspec-test

# Create the service account
kubectl -n inspec-test create serviceaccount inspec-scanner

# Create the role
kubectl apply -f - <<EOF
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
EOF

# Create the role binding
kubectl apply -f - <<EOF
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

# Create a test pod
kubectl apply -f - <<EOF
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
```

### Creating Authentication

#### With Helper Scripts

```bash
# Generate kubeconfig automatically
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml
```

#### With Direct Commands

```bash
# Generate token
TOKEN=$(kubectl create token inspec-scanner -n inspec-test --duration=60m)
SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')

# Create kubeconfig manually
cat > ./kubeconfig.yaml << EOF
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
    namespace: inspec-test
    user: inspec-scanner
  name: scanner-context
current-context: scanner-context
users:
- name: inspec-scanner
  user:
    token: ${TOKEN}
EOF

chmod 600 ./kubeconfig.yaml
```

### Running a Standard Container Scan

#### With Helper Scripts

```bash
# One-line scan with automatic RBAC, token, and threshold validation
./scripts/scan-container.sh inspec-test inspec-target busybox ./examples/cinc-profiles/container-baseline
```

#### With Direct Commands

```bash
# Run CINC Auditor directly
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
  -t k8s-container://inspec-test/inspec-target/busybox \
  --reporter cli json:scan-results.json

# Process results with SAF CLI
saf summary --input scan-results.json --output-md scan-summary.md
saf threshold -i scan-results.json -t threshold.yml
```

### Scanning Distroless Containers

#### With Helper Scripts

```bash
# One-line scan of distroless container with ephemeral debug container
./scripts/scan-distroless-container.sh inspec-test distroless-target distroless ./examples/cinc-profiles/container-baseline
```

#### With Direct Commands

```bash
# Create debug container manually
kubectl debug -n inspec-test distroless-target \
  --image=docker.io/cincproject/auditor:latest \
  --target=distroless \
  --container=debug-container \
  -- sleep 300 &

# Wait for debug container to be ready
sleep 10

# Run scan against debug container
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
  -t k8s-container://inspec-test/distroless-target/debug-container \
  --reporter cli json:scan-results.json

# Process results with SAF CLI
saf summary --input scan-results.json --output-md scan-summary.md
saf threshold -i scan-results.json -t threshold.yml
```

### Using Helm for Deployment

#### With Helper Scripts

```bash
# Install everything with a single command
./helm-charts/install-all.sh --namespace inspec-test
```

#### With Direct Commands

```bash
# Install each chart separately
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=inspec-test

helm install common-scanner ./helm-charts/common-scanner \
  --set scanner-infrastructure.targetNamespace=inspec-test

helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test

helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test
```

## SAF CLI Integration

### With Helper Scripts

```bash
# Threshold validation is built into the scan scripts
./scripts/scan-container.sh inspec-test inspec-target busybox ./examples/cinc-profiles/container-baseline ./threshold.yml
```

### With Direct Commands

```bash
# Run scan and get results
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
  -t k8s-container://inspec-test/inspec-target/busybox \
  --reporter cli json:scan-results.json

# Generate summary
saf summary --input scan-results.json --output-md scan-summary.md

# Apply threshold validation
saf threshold -i scan-results.json -t threshold.yml
THRESHOLD_RESULT=$?

if [ $THRESHOLD_RESULT -eq 0 ]; then
  echo "✅ Security scan passed threshold requirements"
else
  echo "❌ Security scan failed to meet threshold requirements"
  exit $THRESHOLD_RESULT
fi
```

## CI/CD Integration

### GitHub Actions

```yaml
- name: Run container scan
  run: |
    # Helper script method
    ./scripts/scan-container.sh $NAMESPACE $POD_NAME $CONTAINER_NAME ./profile ./threshold.yml
    
    # OR direct method
    KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./profile \
      -t k8s-container://$NAMESPACE/$POD_NAME/$CONTAINER_NAME \
      --reporter cli json:scan-results.json
    
    saf threshold -i scan-results.json -t threshold.yml
```

### GitLab CI

```yaml
run_scan:
  stage: scan
  script:
    # Helper script method
    ./scripts/scan-container.sh $NAMESPACE $POD_NAME $CONTAINER_NAME ./profile ./threshold.yml
    
    # OR direct method
    KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./profile \
      -t k8s-container://$NAMESPACE/$POD_NAME/$CONTAINER_NAME \
      --reporter cli json:scan-results.json
    
    saf threshold -i scan-results.json -t threshold.yml
```

## Which Method to Choose?

### Use Helper Scripts When:

- You want a simpler, more streamlined experience
- You're new to Kubernetes or CINC Auditor
- You need to quickly implement scanning in CI/CD
- You want automatic cleanup of temporary resources

### Use Direct Commands When:

- You need more control over the process
- You're integrating with existing automation
- You want to understand what's happening "under the hood"
- You need to customize the scanning process

## Known Limitations

### Helper Scripts:

- Less flexibility for advanced use cases
- Dependencies between scripts might not be immediately obvious
- Limited customization of RBAC without modifying the scripts

### Direct Commands:

- More complex to implement
- Requires deeper understanding of Kubernetes and CINC Auditor
- Manual cleanup of resources required