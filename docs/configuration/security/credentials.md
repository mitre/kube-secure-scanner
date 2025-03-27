# Secure Credential Management

This document covers secure management of authentication credentials for the CINC Auditor container scanning solution.

## Types of Credentials

The scanning solution uses several types of credentials:

1. **Kubeconfig Files**: For Kubernetes API authentication
2. **Service Account Tokens**: For service account authentication
3. **TLS Certificates**: For secure communication with the Kubernetes API
4. **CI/CD Secrets**: For secure pipeline integration

## Kubeconfig Security

### File Storage

Store kubeconfig files securely:

```bash
# Create secure directory
mkdir -p ~/.kube/secure
chmod 700 ~/.kube/secure

# Store kubeconfig with restricted permissions
cp kubeconfig.yaml ~/.kube/secure/
chmod 600 ~/.kube/secure/kubeconfig.yaml
```

### Environment Variables

Be cautious with environment variables:

```bash
# Using environment variables (note security considerations)
export KUBECONFIG=~/.kube/secure/kubeconfig.yaml

# Avoid print or export commands that might expose the variable in logs
set +x  # Turn off command echo
```

### Memory-Only Storage

For highest security, keep credentials in memory only:

```bash
# Generate kubeconfig in a subshell
$(kubectl config set-credentials scanner-user --token=$(kubectl create token scanner-sa -n scanner-namespace) --kubeconfig=/dev/shm/temp-config)
$(kubectl config set-cluster scanner-cluster --server=... --kubeconfig=/dev/shm/temp-config)
$(kubectl config set-context scanner-context --cluster=scanner-cluster --user=scanner-user --kubeconfig=/dev/shm/temp-config)

# Use the in-memory kubeconfig
KUBECONFIG=/dev/shm/temp-config cinc-auditor exec ...

# Clean up
rm /dev/shm/temp-config
```

## Service Account Token Management

### Token Expiration

Set appropriate token expiration times:

```bash
# Short-lived token for single scan (15 minutes)
TOKEN=$(kubectl create token scanner-sa -n scanner-namespace --duration=15m)

# Medium-lived token for CI/CD pipeline (1 hour)
TOKEN=$(kubectl create token scanner-sa -n scanner-namespace --duration=1h)

# Long-lived token should be avoided, but if necessary (24 hours max)
TOKEN=$(kubectl create token scanner-sa -n scanner-namespace --duration=24h)
```

### Token Rotation

Implement regular token rotation:

```bash
#!/bin/bash
# rotate-tokens.sh
NAMESPACE="scanner-namespace"
SA_NAME="scanner-sa"

# Generate new token
NEW_TOKEN=$(kubectl create token $SA_NAME -n $NAMESPACE --duration=24h)

# Update configuration that uses the token
# This depends on how you're storing/using the token
# Example: Update a Kubernetes secret
kubectl create secret generic scanner-token -n $NAMESPACE \
  --from-literal=token=$NEW_TOKEN --dry-run=client -o yaml | \
  kubectl apply -f -

echo "Token rotated for $SA_NAME in $NAMESPACE"
```

## Kubernetes Secrets

### Storing Kubeconfig in Secrets

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: scanner-kubeconfig
  namespace: scanner-namespace
type: Opaque
data:
  kubeconfig.yaml: <BASE64_ENCODED_KUBECONFIG>
```

### Mounting Secrets in Pods

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: scanner-pod
  namespace: scanner-namespace
spec:
  containers:
  - name: scanner
    image: scanner-image:latest
    volumeMounts:
    - name: config
      mountPath: "/etc/scanner/config"
      readOnly: true
    env:
    - name: KUBECONFIG
      value: "/etc/scanner/config/kubeconfig.yaml"
  volumes:
  - name: config
    secret:
      secretName: scanner-kubeconfig
      defaultMode: 0400  # Read-only for owner only
```

## CI/CD Pipeline Credentials

### GitHub Actions

Securely store credentials in GitHub Secrets:

```yaml
name: Security Scan

on:
  push:
    branches: [ main ]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      # Set up credentials securely
      - name: Configure Kubernetes
        run: |
          mkdir -p $HOME/.kube
          echo "${{ secrets.KUBECONFIG }}" > $HOME/.kube/config
          chmod 600 $HOME/.kube/config
```

### GitLab CI

Securely store credentials in GitLab CI/CD Variables:

```yaml
container-security-scan:
  stage: scan
  script:
    - mkdir -p $HOME/.kube
    - echo "$KUBECONFIG" > $HOME/.kube/config
    - chmod 600 $HOME/.kube/config
    - cinc-auditor exec profile -t k8s-container://namespace/pod/container
  variables:
    # Mark as protected and masked
    KUBECONFIG: ${{ secrets.KUBECONFIG }}
```

## External Credential Providers

### AWS Secrets Manager

```bash
# Retrieve kubeconfig from AWS Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id scanner/kubeconfig \
  --query SecretString \
  --output text > $HOME/.kube/config
chmod 600 $HOME/.kube/config
```

### HashiCorp Vault

```bash
# Retrieve kubeconfig from HashiCorp Vault
VAULT_TOKEN=$(vault login -token-only -method=kubernetes role=scanner)
vault kv get -field=kubeconfig secret/scanner/kubeconfig > $HOME/.kube/config
chmod 600 $HOME/.kube/config
```

## Best Practices

1. **Never hardcode credentials** in scripts or configuration files
2. **Use short-lived tokens** whenever possible
3. **Implement regular rotation** for all credentials
4. **Set restrictive permissions** on credential files
5. **Use secure memory** for temporary credential storage
6. **Audit credential usage** regularly
7. **Use external vaults** for enterprise deployments
8. **Isolate credentials** by environment (dev, staging, prod)

## Credential Compromise Response

If credentials are compromised:

1. **Revoke the compromised credentials** immediately

   ```bash
   kubectl delete serviceaccount scanner-sa -n scanner-namespace
   kubectl create serviceaccount scanner-sa -n scanner-namespace
   ```

2. **Audit usage** to determine potential impact

   ```bash
   # Check audit logs for suspicious activity
   kubectl logs -n kube-system -l component=kube-apiserver
   ```

3. **Rotate all related credentials**

   ```bash
   # Regenerate and distribute new credentials
   ./rotate-credentials.sh
   ```

4. **Update security controls** to prevent future compromises

## Related Topics

- [Hardening Configuration](hardening.md)
- [RBAC Configuration](rbac.md)
- [Kubeconfig Security](../kubeconfig/security.md)
- [Token Management](../../tokens/index.md)
