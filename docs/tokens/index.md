# Token Management

!!! info "Directory Inventory"
    See the [Tokens Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

This guide covers the creation, usage, and lifecycle management of Kubernetes tokens for secure InSpec scanning.

## Token Types

### Short-Lived Tokens (Recommended)

Short-lived tokens are created on-demand and expire automatically:

```bash
# Create a token with default expiration (1 hour)
kubectl create token inspec-scanner -n inspec-test

# Create a token with custom expiration
kubectl create token inspec-scanner -n inspec-test --duration=30m
```

Benefits:

- Automatic expiration
- No token storage/cleanup required
- Reduced risk if token is exposed

### Bound Service Account Tokens

For automated pipelines, you can create bound service account tokens:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: scanner-token
  namespace: inspec-test
  annotations:
    kubernetes.io/service-account.name: inspec-scanner
    kubernetes.io/service-account.expiration: "86400"  # 24 hours in seconds
type: kubernetes.io/service-account-token
```

Benefits:

- Configurable expiration
- Can be rotated with Kubernetes secrets rotation
- Compatible with older Kubernetes tooling

## Token Generation in CI/CD Pipelines

### GitLab CI Example

```yaml
stages:
  - scan

variables:
  KUBE_NAMESPACE: inspec-test

create_token:
  stage: scan
  script:
    - TOKEN=$(kubectl create token inspec-scanner -n $KUBE_NAMESPACE)
    - echo "SCAN_TOKEN=$TOKEN" >> scan_credentials.env
  artifacts:
    reports:
      dotenv: scan_credentials.env

run_scan:
  stage: scan
  needs: [create_token]
  script:
    - echo "$SCAN_TOKEN" > token.txt
    - ./run_scan.sh token.txt
  artifacts:
    reports:
      scan: scan-results.json
```

### GitHub Actions Example

```yaml
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - name: Generate Token
        id: generate-token
        run: |
          TOKEN=$(kubectl create token inspec-scanner -n inspec-test)
          echo "::set-output name=token::$TOKEN"
          
      - name: Run Scan
        run: |
          echo "${{ steps.generate-token.outputs.token }}" > token.txt
          ./run_scan.sh token.txt
```

## Token Security Best Practices

1. **Short Expiration**: Use the shortest practical token expiration
2. **Just-in-Time Creation**: Generate tokens when needed, not in advance
3. **Secure Storage**: Store tokens in secure CI/CD variables or secrets
4. **Mask in Logs**: Ensure tokens are masked in CI/CD logs
5. **Single-Use**: Use each token only once, then discard
6. **Audience Restriction**: If possible, restrict token audience

## Token Expiration Testing

Test token expiration to ensure your system handles it gracefully:

```bash
# Create a token with short expiration
TOKEN=$(kubectl create token inspec-scanner -n inspec-test --duration=30s)

# Save token to a file
echo "$TOKEN" > test-token.txt

# Use token immediately (should work)
KUBECONFIG=<your-config> K8S_AUTH_TOKEN=$(cat test-token.txt) inspec exec ...

# Wait for expiration
sleep 35

# Try again (should fail)
KUBECONFIG=<your-config> K8S_AUTH_TOKEN=$(cat test-token.txt) inspec exec ...
```

## Token Audit and Troubleshooting

### Decoding Tokens

```bash
# Get the token
TOKEN=$(kubectl create token inspec-scanner -n inspec-test)

# Decode token payload (middle section)
echo $TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | jq .
```

This shows token metadata including:

- Expiration time
- Subject (service account)
- Audience
- Issuer

### Verifying Token Privileges

```bash
# Use auth can-i to check permissions with a token
kubectl auth can-i get pods --namespace=inspec-test --token=$TOKEN

# Check specific resource access
kubectl auth can-i create pods/exec --namespace=inspec-test --token=$TOKEN --resource-name=target-pod
```

## References

- [Kubernetes Authentication Documentation](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)
- [Managing Service Account Tokens](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/)
- [Token Request API](https://kubernetes.io/docs/reference/kubernetes-api/authentication-resources/token-request-v1/)
