# Security Hardening Configuration

This guide provides recommendations for hardening the security configuration of your CINC Auditor container scanning solution.

## Principle of Least Privilege

Follow the principle of least privilege when configuring scanner access:

1. Create dedicated service accounts for scanning
2. Limit service account permissions to only what's necessary
3. Avoid using cluster-admin or other high-privilege accounts
4. Use namespace-scoped roles when possible

## Service Account Configuration

```yaml
# Example: Secure service account configuration
apiVersion: v1
kind: ServiceAccount
metadata:
  name: scanner-sa
  namespace: scanner-namespace
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-role
  namespace: target-namespace
rules:
- apiGroups: [""]
  resources: ["pods", "pods/exec"]
  verbs: ["get", "list"]
  # Optionally limit to specific pods by name
  resourceNames: ["target-pod-1", "target-pod-2"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scanner-rolebinding
  namespace: target-namespace
subjects:
- kind: ServiceAccount
  name: scanner-sa
  namespace: scanner-namespace
roleRef:
  kind: Role
  name: scanner-role
  apiGroup: rbac.authorization.k8s.io
```

## Kubeconfig Hardening

### Short-lived Tokens

Use short-lived tokens for authentication:

```bash
# Create token with 15-minute expiration
TOKEN=$(kubectl create token scanner-sa -n scanner-namespace --duration=15m)

# Use token in kubeconfig
# ... kubeconfig generation ...
```

### Restricted File Permissions

Set restrictive permissions on kubeconfig files:

```bash
chmod 600 secure-kubeconfig.yaml
```

### Environment-specific Configurations

Use separate configurations for different environments:

```bash
# Production - most restricted permissions
./generate-kubeconfig.sh prod-namespace scanner-sa-prod ./kubeconfig-prod.yaml

# Development - less restricted permissions
./generate-kubeconfig.sh dev-namespace scanner-sa-dev ./kubeconfig-dev.yaml
```

## Network Security

### TLS Configuration

Ensure TLS is properly configured:

```yaml
# In kubeconfig
clusters:
- cluster:
    certificate-authority-data: <REDACTED>
    server: https://kubernetes.api.server:6443
  name: secure-cluster
```

### Network Policies

Implement network policies to restrict scanner pod communications:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scanner-network-policy
  namespace: scanner-namespace
spec:
  podSelector:
    matchLabels:
      app: scanner
  policyTypes:
  - Ingress
  - Egress
  ingress: []
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 443
  - to:
    - namespaceSelector:
        matchLabels:
          name: target-namespace
```

## Secrets Management

### Using Kubernetes Secrets

Store sensitive configuration in Kubernetes secrets:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: scanner-secret
  namespace: scanner-namespace
type: Opaque
data:
  kubeconfig.yaml: <BASE64_ENCODED_KUBECONFIG>
```

Mount the secret in scanner pods:

```yaml
volumes:
- name: config-volume
  secret:
    secretName: scanner-secret
containers:
- name: scanner
  volumeMounts:
  - name: config-volume
    mountPath: "/etc/scanner/config"
    readOnly: true
```

### Secret Rotation

Implement regular secret rotation:

```bash
#!/bin/bash
# rotate-secrets.sh
NAMESPACE="scanner-namespace"
SA_NAME="scanner-sa"
SECRET_NAME="scanner-secret"

# Generate new kubeconfig
TOKEN=$(kubectl create token $SA_NAME -n $NAMESPACE --duration=24h)
SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')

# Create kubeconfig file
cat > kubeconfig.yaml << EOF
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

# Update Kubernetes secret
kubectl create secret generic $SECRET_NAME -n $NAMESPACE \
  --from-file=kubeconfig.yaml --dry-run=client -o yaml | \
  kubectl apply -f -

echo "Secret rotated: $SECRET_NAME"
```

## Distroless Containers

When scanning distroless containers, use secure ephemeral debug containers:

```yaml
# Secure debug container configuration
debugContainers:
  image: "gcr.io/distroless/static-debian11:debug"
  securityContext:
    runAsNonRoot: true
    readOnlyRootFilesystem: true
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
```

## Audit Logging

Enable audit logging for scanner operations:

```yaml
# Kubernetes API server audit policy
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  users: ["system:serviceaccount:scanner-namespace:scanner-sa"]
  resources:
  - group: ""
    resources: ["pods/exec"]
```

## CI/CD Pipeline Security

Secure CI/CD pipeline configurations:

### GitHub Actions

```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Kubernetes
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG }}" > $HOME/.kube/config
          chmod 600 $HOME/.kube/config
          
      # Use OIDC for authentication when possible
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: us-west-2
```

### GitLab CI

```yaml
container-security-scan:
  stage: scan
  image: ruby:3.1-alpine
  before_script:
    - mkdir -p $HOME/.kube
    - echo "$KUBECONFIG" > $HOME/.kube/config
    - chmod 600 $HOME/.kube/config
  script:
    - cinc-auditor exec profile -t k8s-container://namespace/pod/container
  variables:
    # Mark as protected and masked
    KUBECONFIG: ${{ secrets.KUBECONFIG }}
```

## Related Topics

- [Credential Management](credentials.md)
- [RBAC Configuration](rbac.md)
- [Kubeconfig Security](../kubeconfig/security.md)
- [Security Principles](../../security/principles/index.md)
- [Threat Mitigations](../../security/threat-model/threat-mitigations.md)
- [NSA/CISA Kubernetes Hardening Guide](../../security/compliance/nsa-cisa-hardening.md)
