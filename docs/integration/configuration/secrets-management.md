# Secrets Management for Container Scanning

This page outlines best practices for managing secrets when integrating container scanning into CI/CD pipelines.

## Overview

Container scanning often requires access to Kubernetes clusters, container registries, and other sensitive resources. Proper secrets management is critical for:

- Protecting cluster access credentials
- Securing container registry authentication
- Managing service account tokens securely
- Implementing the principle of least privilege
- Preventing secrets from being exposed in logs or outputs

## Types of Secrets

When integrating container scanning, you'll typically need to manage these types of secrets:

1. **Kubernetes Authentication**:
   - Kubeconfig files
   - Service account tokens
   - API server certificates

2. **Container Registry Authentication**:
   - Registry usernames and passwords
   - Registry access tokens
   - Docker config.json files

3. **Scanning Credentials**:
   - Profile repository access tokens
   - Compliance API keys
   - Report repository credentials

4. **Temporary Credentials**:
   - Short-lived service account tokens
   - Limited-scope access tokens
   - Ephemeral certificates

## Best Practices

### General Security Practices

- **Never store secrets in code repositories**
- **Limit secret access** to only the jobs and stages that require them
- **Use environment variables** to inject secrets into pipelines
- **Implement secret rotation** policies
- **Always validate inputs** to prevent injection attacks
- **Audit secret usage** regularly

### CI/CD Platform-Specific Practices

#### GitHub Actions

1. **Use GitHub Secrets for sensitive data**:
   ```yaml
   - name: Setup Kubernetes access
     run: |
       echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig.yaml
       export KUBECONFIG=kubeconfig.yaml
   ```

2. **Limit secret exposure with environment isolation**:
   ```yaml
   jobs:
     scan:
       environment: production
       env:
         SCANNER_TOKEN: ${{ secrets.SCANNER_TOKEN }}
   ```

3. **Use OIDC for cloud provider authentication**:
   ```yaml
   - name: Configure AWS credentials
     uses: aws-actions/configure-aws-credentials@v1
     with:
       role-to-assume: ${{ secrets.AWS_ROLE }}
       aws-region: us-east-1
   ```

#### GitLab CI/CD

1. **Use GitLab CI/CD Variables**:
   ```yaml
   before_script:
     - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
     - export KUBECONFIG=kubeconfig.yaml
   ```

2. **Use masked variables** to prevent accidental exposure:
   ```yaml
   # In GitLab CI/CD settings, mark variables as "Masked"
   ```

3. **Limit variable scope by environment**:
   ```yaml
   # In GitLab CI/CD settings, set variables with a specific environment scope
   ```

4. **Use CI/CD file variables for per-pipeline secrets**:
   ```yaml
   variables:
     SCANNER_TOKEN: $CI_JOB_TOKEN
   ```

### Kubernetes Secret Management

1. **Create time-limited service accounts**:
   ```bash
   # Create short-lived token (Kubernetes 1.22+)
   TOKEN=$(kubectl create token scanner-sa --duration=15m)
   ```

2. **Create least-privilege RBAC roles**:
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: scanner-role
   rules:
   - apiGroups: [""]
     resources: ["pods"]
     verbs: ["get", "list"]
   - apiGroups: [""]
     resources: ["pods/exec"]
     verbs: ["create"]
     resourceNames: ["specific-pod-name"]
   ```

3. **Use namespaced resources** to limit access scope:
   ```yaml
   # Create rolebinding in specific namespace
   kubectl create rolebinding scanner-binding \
     --role=scanner-role \
     --serviceaccount=default:scanner-sa \
     -n target-namespace
   ```

4. **Include Job/Pipeline IDs in resource names** for traceability:
   ```yaml
   metadata:
     name: scanner-sa-${CI_JOB_ID}
     annotations:
       ci-job: "${CI_JOB_ID}"
       pipeline: "${CI_PIPELINE_ID}"
   ```

## Temporary Credentials Workflow

Here's a recommended workflow for managing temporary credentials in scanning pipelines:

1. **Create a temporary service account**:
   ```bash
   kubectl create serviceaccount scanner-sa-${CI_JOB_ID} -n ${NAMESPACE}
   ```

2. **Create a restricted role** with specific pod access:
   ```bash
   cat <<EOF | kubectl apply -f -
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   metadata:
     name: scanner-role-${CI_JOB_ID}
     namespace: ${NAMESPACE}
   rules:
   - apiGroups: [""]
     resources: ["pods"]
     verbs: ["get", "list"]
   - apiGroups: [""]
     resources: ["pods/exec"]
     verbs: ["create"]
     resourceNames: ["${POD_NAME}"]
   EOF
   ```

3. **Bind the role to the service account**:
   ```bash
   kubectl create rolebinding scanner-binding-${CI_JOB_ID} \
     --role=scanner-role-${CI_JOB_ID} \
     --serviceaccount=${NAMESPACE}:scanner-sa-${CI_JOB_ID} \
     -n ${NAMESPACE}
   ```

4. **Generate a short-lived token**:
   ```bash
   TOKEN=$(kubectl create token scanner-sa-${CI_JOB_ID} -n ${NAMESPACE} --duration=15m)
   ```

5. **Use the token for scanning**:
   ```bash
   # Create scanner kubeconfig
   cat > scanner-kubeconfig.yaml <<EOF
   apiVersion: v1
   kind: Config
   clusters:
   - cluster:
       server: ${KUBE_SERVER}
       certificate-authority-data: ${KUBE_CA_DATA}
     name: k8s-cluster
   contexts:
   - context:
       cluster: k8s-cluster
       user: scanner-user
       namespace: ${NAMESPACE}
     name: scanner-context
   current-context: scanner-context
   users:
   - name: scanner-user
     user:
       token: ${TOKEN}
   EOF
   ```

6. **Clean up after scanning**:
   ```bash
   kubectl delete rolebinding scanner-binding-${CI_JOB_ID} -n ${NAMESPACE}
   kubectl delete role scanner-role-${CI_JOB_ID} -n ${NAMESPACE}
   kubectl delete serviceaccount scanner-sa-${CI_JOB_ID} -n ${NAMESPACE}
   ```

## Managing Secrets in Container Registry Authentication

When scanning containers that require pulling from private registries:

1. **Use docker config secrets**:
   ```yaml
   apiVersion: v1
   kind: Secret
   metadata:
     name: registry-credentials
   type: kubernetes.io/dockerconfigjson
   data:
     .dockerconfigjson: <base64-encoded-docker-config>
   ```

2. **Reference secrets in pod definition**:
   ```yaml
   spec:
     imagePullSecrets:
     - name: registry-credentials
   ```

3. **Securely inject credentials in CI/CD**:
   ```yaml
   before_script:
     - echo "$REGISTRY_PASSWORD" | docker login -u "$REGISTRY_USERNAME" --password-stdin $REGISTRY_URL
   ```

## Sanitizing Output and Avoiding Secret Leakage

To prevent accidental exposure of secrets in logs and reports:

1. **Sanitize scan output**:
   ```bash
   # Replace sensitive data in outputs
   sed -i 's/sensitive-data-pattern/[REDACTED]/g' scan-results.json
   ```

2. **Use log filters in CI/CD pipelines**:
   ```yaml
   # GitLab CI/CD filter pattern
   variables:
     SECURE_LOG_LEVEL: info
     CI_DEBUG_TRACE: "false"
   ```

3. **Set token variables as secrets in your CI/CD system**:
   - GitHub Actions: `${{ secrets.TOKEN_NAME }}`
   - GitLab CI/CD: Masked variables

4. **Avoid using debug output for workflows with secrets**:
   ```yaml
   # Only enable debug on non-sensitive stages
   debug:
     if: github.event.inputs.enable_debug == 'true'
   ```

5. **Use credential helpers when possible**:
   - AWS: `aws-cli` credential helper
   - GCP: `gcloud` credential helper
   - Azure: `az` credential helper

## Automated Secret Rotation

For long-running scanning pipelines or environments, implement automated secret rotation:

1. **Create periodic jobs to rotate credentials**:
   ```yaml
   # GitLab CI/CD schedule for rotating credentials
   secret-rotation:
     stage: maintenance
     rules:
       - if: $CI_PIPELINE_SOURCE == "schedule"
     script:
       - ./rotate-credentials.sh
   ```

2. **Store rotation timestamps**:
   ```bash
   # Record when credentials were last rotated
   echo "Last rotated: $(date)" > rotation-timestamp.txt
   ```

3. **Implement graceful credential handover**:
   ```bash
   # Create new credentials before invalidating old ones
   NEW_TOKEN=$(create-new-token)
   update-token-consumers "$NEW_TOKEN"
   invalidate-old-token
   ```

## Related Resources

- [Environment Variables for Integration](./environment-variables.md)
- [GitHub Actions Integration Guide](../platforms/github-actions.md)
- [GitLab CI/CD Integration Guide](../platforms/gitlab-ci.md)
- [Kubernetes API Approach](../../approaches/kubernetes-api.md)
- [Standard Container Workflow](../workflows/standard-container.md)
- [Security Workflows](../workflows/security-workflows.md)
- [RBAC Documentation](../../rbac/index.md)
- [Service Accounts Documentation](../../service-accounts/index.md)