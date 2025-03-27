# Token Management

## Overview

!!! security-focus "Security Emphasis"
    Secure token management is critical for maintaining the security integrity of your Kubernetes scanning operations. This task implements best practices for generating, using, and rotating short-lived tokens to minimize the risk of credential compromise.

This task guides you through implementing secure token management for Kube CINC Secure Scanner. By following this approach, you'll create ephemeral, least-privilege access tokens for scanning operations that automatically expire after use.

**Time to complete:** 20-30 minutes

**Security risk:** 🔴 High - Involves creation and management of authentication credentials

**Security approach:** Implements ephemeral credentials with time-based expiration, least-privilege access controls, and secure token delivery mechanisms

## Security Architecture

???+ abstract "Understanding Permission Layers"
    Token management for container scanning involves multiple security layers:

    **1. Token Generation Permissions**
    * **Control:** Who can create authentication tokens for service accounts
    * **Risk area:** Unrestricted token generation could lead to unauthorized cluster access
    * **Mitigation:** Limit token creation to authorized administrators or automated systems with strict controls
    
    **2. Token Usage Permissions**
    * **Control:** What the token can access within the Kubernetes API
    * **Risk area:** Overly permissive tokens could grant excessive access
    * **Mitigation:** Bind tokens to service accounts with precisely scoped RBAC permissions
    
    **3. Token Storage & Transmission**
    * **Control:** How tokens are stored, transmitted, and protected
    * **Risk area:** Token exposure could lead to credential theft
    * **Mitigation:** Implement secure storage, encrypted transmission, and automatic token expiration

## Security Prerequisites

- [ ] Kubernetes cluster with TokenRequest API enabled (v1.22+)
- [ ] Service accounts and RBAC roles created (see [RBAC Setup](rbac-setup.md))
- [ ] Administrative access to generate tokens
- [ ] Understanding of Kubernetes RBAC and authentication mechanisms

## Step-by-Step Instructions

### Step 1: Understanding Token Types

!!! security-note "Security Consideration"
    Different token types have different security properties and lifetimes. Short-lived tokens are strongly preferred.

Kubernetes supports several token types:

1. **Service Account Tokens (pre-v1.24)**: Long-lived tokens stored in secrets
2. **TokenRequest API Tokens (v1.22+)**: Short-lived tokens with configurable expiration
3. **Bound Service Account Tokens**: Tokens bound to specific audiences and use cases

For security reasons, we'll use the TokenRequest API to generate short-lived tokens.

### Step 2: Generate Short-Lived Tokens

!!! security-note "Security Consideration"
    Always set an appropriate expiration time based on the expected duration of the scanning operation.

1. Generate a token with a 15-minute expiration:

```bash
# Create a token that expires in 15 minutes
TOKEN=$(kubectl create token scanner-sa -n scanner-namespace --duration=15m)
echo $TOKEN
```

2. For automated scripts, save the token securely:

```bash
# Save token to a protected file with restricted permissions
echo $TOKEN > scanner-token.txt
chmod 600 scanner-token.txt
```

### Step 3: Create a Secure Kubeconfig File

!!! security-note "Security Consideration"
    Kubeconfig files contain sensitive credentials and should be protected accordingly.

1. Generate a kubeconfig file using the token:

```bash
# Get cluster information
SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')

# Create the kubeconfig file
cat > scanner-kubeconfig.yaml << EOF
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
    namespace: scanner-namespace
    user: scanner-user
  name: scanner-context
current-context: scanner-context
users:
- name: scanner-user
  user:
    token: ${TOKEN}
EOF

# Set proper permissions
chmod 600 scanner-kubeconfig.yaml
```

### Step 4: Implement Token Rotation

!!! security-note "Security Consideration"
    Automated token rotation ensures that tokens are regularly refreshed, limiting the exposure window.

1. Create a shell script for token rotation:

```bash
#!/bin/bash
# token-rotation.sh

# Set variables
SERVICE_ACCOUNT="scanner-sa"
NAMESPACE="scanner-namespace"
DURATION="15m"
KUBECONFIG_PATH="./scanner-kubeconfig.yaml"

# Generate new token
echo "Generating new token for ${SERVICE_ACCOUNT}..."
NEW_TOKEN=$(kubectl create token ${SERVICE_ACCOUNT} -n ${NAMESPACE} --duration=${DURATION})

# Get cluster information
SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')

# Update kubeconfig file
echo "Updating kubeconfig file at ${KUBECONFIG_PATH}..."
cat > ${KUBECONFIG_PATH} << EOF
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
    token: ${NEW_TOKEN}
EOF

# Set secure permissions
chmod 600 ${KUBECONFIG_PATH}

echo "Token rotation completed successfully."
echo "Token will expire in ${DURATION}."
```

2. Make the script executable:

```bash
chmod +x token-rotation.sh
```

### Step 5: Implement Token Management in CI/CD Pipelines

!!! security-note "Security Consideration"
    CI/CD pipelines should generate fresh tokens for each run to maintain security isolation between pipeline executions.

**GitHub Actions example**:

```yaml
jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Generate Kubernetes token
        id: generate-token
        run: |
          # Create token directly within the workflow
          TOKEN=$(kubectl create token scanner-sa -n scanner-namespace --duration=15m)
          
          # Store token as a step output (masked in logs)
          echo "::add-mask::$TOKEN"
          echo "token=$TOKEN" >> $GITHUB_OUTPUT
        
      - name: Create kubeconfig
        run: |
          # Use token from previous step
          TOKEN="${{ steps.generate-token.outputs.token }}"
          
          # Create kubeconfig file
          cat > scanner-kubeconfig.yaml << EOF
          apiVersion: v1
          kind: Config
          preferences: {}
          clusters:
          - cluster:
              server: ${{ secrets.CLUSTER_SERVER }}
              certificate-authority-data: ${{ secrets.CLUSTER_CA }}
            name: scanner-cluster
          contexts:
          - context:
              cluster: scanner-cluster
              namespace: scanner-namespace
              user: scanner-user
            name: scanner-context
          current-context: scanner-context
          users:
          - name: scanner-user
            user:
              token: ${TOKEN}
          EOF
          
          chmod 600 scanner-kubeconfig.yaml
      
      - name: Run scan with token
        run: |
          KUBECONFIG=scanner-kubeconfig.yaml kubectl get pods -n scanner-namespace
          # Additional scanning commands...
```

**GitLab CI example**:

```yaml
generate_token:
  stage: prepare
  script:
    - |
      # Generate token
      TOKEN=$(kubectl create token scanner-sa -n scanner-namespace --duration=15m)
      
      # Save token securely for other jobs
      echo "SCANNER_TOKEN=${TOKEN}" >> tokens.env
  artifacts:
    reports:
      dotenv: tokens.env

security_scan:
  stage: scan
  needs: [generate_token]
  script:
    - |
      # Create kubeconfig with token from previous job
      cat > scanner-kubeconfig.yaml << EOF
      apiVersion: v1
      kind: Config
      preferences: {}
      clusters:
      - cluster:
          server: ${CLUSTER_SERVER}
          certificate-authority-data: ${CLUSTER_CA_DATA}
        name: scanner-cluster
      contexts:
      - context:
          cluster: scanner-cluster
          namespace: scanner-namespace
          user: scanner-user
        name: scanner-context
      current-context: scanner-context
      users:
      - name: scanner-user
        user:
          token: ${SCANNER_TOKEN}
      EOF
      
      chmod 600 scanner-kubeconfig.yaml
      
      # Run scan with token
      KUBECONFIG=scanner-kubeconfig.yaml kubectl get pods -n scanner-namespace
      # Additional scanning commands...
```

### Step 6: Implement Secure Token Storage for Non-Pipeline Use Cases

!!! security-note "Security Consideration"
    For operations outside CI/CD pipelines, token storage requires additional security measures.

1. Use environment variables with limited scope:

```bash
# Set token as environment variable for the current process only
export KUBE_TOKEN="$(kubectl create token scanner-sa -n scanner-namespace --duration=15m)"

# Use with kubectl
kubectl --token="$KUBE_TOKEN" get pods -n scanner-namespace
```

2. For systems requiring persistent token storage, use a secrets management system:

```bash
# Example with HashiCorp Vault (if installed)
vault kv put secret/scanner-tokens/token value="$(kubectl create token scanner-sa -n scanner-namespace --duration=60m)"

# Later retrieve the token
TOKEN=$(vault kv get -field=value secret/scanner-tokens/token)
```

## Security Best Practices

- Generate new tokens for each scanning operation
- Set appropriate token expiration times (15-60 minutes maximum)
- Never store tokens in source code repositories
- Implement proper file permissions (600 or more restrictive) for files containing tokens
- Use dedicated service accounts with least-privilege RBAC
- Store tokens in secure, ephemeral locations
- Implement token rotation for long-running operations
- Always use HTTPS for API communications
- Log token creation and usage for auditing purposes
- Mask tokens in logs and console output
- Delete token files immediately after use

## Verification Steps

1. Verify token expiration

   ```bash
   # Create token with short expiration
   TOKEN=$(kubectl create token scanner-sa -n scanner-namespace --duration=1m)
   
   # Use the token immediately
   kubectl --token=$TOKEN get pods -n scanner-namespace
   
   # Wait for token to expire
   sleep 65
   
   # This should fail with an authentication error
   kubectl --token=$TOKEN get pods -n scanner-namespace
   ```

2. Verify token permissions

   ```bash
   # Generate token
   TOKEN=$(kubectl create token scanner-sa -n scanner-namespace --duration=5m)
   
   # Should succeed (assuming proper RBAC)
   kubectl --token=$TOKEN get pods -n scanner-namespace
   
   # Should fail (assuming proper RBAC)
   kubectl --token=$TOKEN get pods -n kube-system
   ```

3. Check token security in kubeconfig

   ```bash
   # Verify file permissions
   ls -la scanner-kubeconfig.yaml
   # Should show: -rw------- (600 permissions)
   ```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **'create token' command not found** | Upgrade to Kubernetes 1.24+ or use alternative token generation methods |
| **Token expired errors** | Increase token duration slightly or optimize scanning process for faster completion |
| **Permission denied with token** | Verify the service account has appropriate RBAC permissions |
| **Tokens visible in CI/CD logs** | Use secret masking features in your CI/CD platform to prevent token exposure |
| **Cannot authenticate with token** | Check that the token format is correct and hasn't been corrupted during transfer |

## Next Steps

After completing this task, consider:

- [Implement RBAC setup](rbac-setup.md) to align with token permissions
- [Integrate with GitHub Actions](github-integration.md) using secure token generation
- [Integrate with GitLab CI](gitlab-integration.md) using secure token generation
- [Configure kubectl for secure operations](../configuration/kubeconfig/security.md)

## Related Security Considerations

- [Kubernetes Authentication Methods](../configuration/kubeconfig/management.md)
- [Ephemeral Credentials](../security/principles/ephemeral-creds.md)
- [Least Privilege Principle](../security/principles/least-privilege.md)
- [Secure Transport](../security/principles/secure-transport.md)
