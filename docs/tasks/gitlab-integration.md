# GitLab CI Integration

## Overview

!!! security-focus "Security Emphasis"
    GitLab CI pipelines have access to your Kubernetes clusters and containers, potentially exposing sensitive information. This task implements security best practices including pipeline-specific RBAC, ephemeral credentials, and automatic resource cleanup to minimize security risks.

This task guides you through integrating Kube CINC Secure Scanner with GitLab CI/CD pipelines. Completing this task will enable you to automate container security scanning within your GitLab pipelines while maintaining a strong security posture.

**Time to complete:** 30-45 minutes

**Security risk:** 🟡 Medium - Requires GitLab CI with Kubernetes cluster access

**Security approach:** Implements secure CI/CD integration with ephemeral credentials, pipeline-specific RBAC generation, and proper permission boundaries between GitLab and Kubernetes resources

## Security Architecture

???+ abstract "Understanding Permission Layers"
    Integrating GitLab CI with Kubernetes scanning requires managing multiple permission layers:

    **1. GitLab Runner/Pipeline Permissions**
    * **Control:** Access to GitLab repository resources, ability to run pipelines, store artifacts
    * **Risk area:** Could expose repository secrets or allow unauthorized access
    * **Mitigation:** Use protected variables and dedicated runners with limited scope
    
    **2. CI/CD System Kubernetes Permissions**
    * **Control:** Initial access to create and manage Kubernetes resources, including RBAC setup
    * **Risk area:** Overly permissive access could allow broader cluster access than needed
    * **Mitigation:** Store kubeconfig as protected variable with namespace-scoped permissions
    
    **3. Container Scanner RBAC Permissions**
    * **Control:** What the scanner itself can access within Kubernetes during scan operations
    * **Risk area:** Scanning permissions that are too broad could allow access to unintended resources
    * **Mitigation:** Generate short-lived, minimal-scope tokens scoped only to target containers
    
    The pipelines in this guide demonstrate proper separation of these permission layers with pipeline-specific RBAC permissions that are unique to each pipeline run and automatically cleaned up afterward.

## Security Prerequisites

- [ ] A GitLab repository where you have permissions to set up CI/CD pipelines
- [ ] A Kubernetes cluster that meets the [requirements for existing clusters](../kubernetes-setup/existing-cluster-requirements.md)
- [ ] Understanding of [Kubernetes RBAC](../rbac/index.md) for creating secure service accounts
- [ ] GitLab runners with the ability to execute commands against your Kubernetes cluster
- [ ] [Kubernetes setup](../kubernetes-setup/index.md) with appropriate permissions

## Step-by-Step Instructions

### Step 1: Configure GitLab CI/CD Variables

!!! security-note "Security Consideration"
    Store Kubernetes credentials as protected and masked variables to prevent exposure in logs and limit their use to protected branches only.

1. In your GitLab repository, go to **Settings** > **CI/CD** > **Variables**
2. Add the following variables:
   - `KUBE_CONFIG`: Base64-encoded kubeconfig file (mark as Protected and Masked)

     ```bash
     # Generate using:
     cat ~/.kube/config | base64 -w 0
     ```

   - `SCANNER_NAMESPACE`: The namespace where scanning resources will be created
   - `CINC_PROFILE_PATH`: Path to the CINC Auditor profile (e.g., `dev-sec/linux-baseline`)
   - `THRESHOLD_VALUE`: Minimum passing score for scans (e.g., `70`)

### Step 2: Create .gitlab-ci.yml File

!!! security-note "Security Consideration"
    The pipeline creates isolated, temporary RBAC resources with unique identifiers for each pipeline run to prevent permission reuse.

1. Create a `.gitlab-ci.yml` file in your repository root:

```yaml
stages:
  - deploy
  - scan
  - report
  - cleanup

variables:
  SCANNER_NAMESPACE: "inspec-test"
  TARGET_LABEL: "app=target-app"
  THRESHOLD_VALUE: "70"  # Minimum passing score (0-100)

deploy_container:
  stage: deploy
  script:
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: Pod
      metadata:
        name: scan-target-${CI_PIPELINE_ID}
        namespace: ${SCANNER_NAMESPACE}
        labels:
          app: target-app
          pipeline: "${CI_PIPELINE_ID}"
      spec:
        containers:
        - name: target
          image: registry.example.com/my-image:latest
          command: ["sleep", "1h"]
      EOF
    - |
      # Wait for pod to be ready
      kubectl wait --for=condition=ready pod/scan-target-${CI_PIPELINE_ID} \
        -n ${SCANNER_NAMESPACE} --timeout=120s
    - |
      # Save target info for later stages
      echo "TARGET_POD=scan-target-${CI_PIPELINE_ID}" >> deploy.env
      echo "TARGET_CONTAINER=target" >> deploy.env
  artifacts:
    reports:
      dotenv: deploy.env

create_access:
  stage: scan
  needs: [deploy_container]
  script:
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    - |
      # Create the role for this specific pod
      cat <<EOF | kubectl apply -f -
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: scanner-role-${CI_PIPELINE_ID}
        namespace: ${SCANNER_NAMESPACE}
      rules:
      - apiGroups: [""]
        resources: ["pods"]
        verbs: ["get", "list"]
      - apiGroups: [""]
        resources: ["pods/exec"]
        verbs: ["create"]
        resourceNames: ["${TARGET_POD}"]
      - apiGroups: [""]
        resources: ["pods/log"]
        verbs: ["get"]
        resourceNames: ["${TARGET_POD}"]
      EOF
    - |
      # Create service account
      cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: scanner-sa-${CI_PIPELINE_ID}
        namespace: ${SCANNER_NAMESPACE}
      EOF
    - |
      # Create role binding
      cat <<EOF | kubectl apply -f -
      apiVersion: rbac.authorization.k8s.io/v1
      kind: RoleBinding
      metadata:
        name: scanner-binding-${CI_PIPELINE_ID}
        namespace: ${SCANNER_NAMESPACE}
      subjects:
      - kind: ServiceAccount
        name: scanner-sa-${CI_PIPELINE_ID}
        namespace: ${SCANNER_NAMESPACE}
      roleRef:
        kind: Role
        name: scanner-role-${CI_PIPELINE_ID}
        apiGroup: rbac.authorization.k8s.io
      EOF
    - |
      # Generate token with 15-minute lifespan
      TOKEN=$(kubectl create token scanner-sa-${CI_PIPELINE_ID} \
        -n ${SCANNER_NAMESPACE} --duration=15m)
      echo "SCANNER_TOKEN=${TOKEN}" >> scanner.env
      
      # Save cluster info
      SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
      CA_DATA=$(kubectl config view --raw --minify --flatten \
        -o jsonpath='{.clusters[].cluster.certificate-authority-data}')
      echo "CLUSTER_SERVER=${SERVER}" >> scanner.env
      echo "CLUSTER_CA_DATA=${CA_DATA}" >> scanner.env
  artifacts:
    reports:
      dotenv: scanner.env

run_scan:
  stage: scan
  needs: [deploy_container, create_access]
  script:
    - |
      # Create a kubeconfig file with restricted permissions
      cat > scan-kubeconfig.yaml << EOF
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
          namespace: ${SCANNER_NAMESPACE}
          user: scanner-user
        name: scanner-context
      current-context: scanner-context
      users:
      - name: scanner-user
        user:
          token: ${SCANNER_TOKEN}
      EOF
      
      # Set proper permissions on kubeconfig
      chmod 600 scan-kubeconfig.yaml
    - |
      # Install CINC Auditor
      curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor
      
      # Install train-k8s-container plugin
      cinc-auditor plugin install train-k8s-container
      
      # Install SAF CLI
      npm install -g @mitre/saf
      
      # Run cinc-auditor scan
      KUBECONFIG=scan-kubeconfig.yaml \
        cinc-auditor exec ${CINC_PROFILE_PATH} \
        -t k8s-container://${SCANNER_NAMESPACE}/${TARGET_POD}/${TARGET_CONTAINER} \
        --reporter json:scan-results.json
      
      # Generate scan summary using SAF CLI
      saf summary --input scan-results.json --output-md scan-summary.md
      
      # Display summary in job output
      cat scan-summary.md
      
      # Check scan against threshold
      saf threshold -i scan-results.json -t ${THRESHOLD_VALUE}
      THRESHOLD_RESULT=$?
      
      # Save result for later stages
      echo "THRESHOLD_PASSED=${THRESHOLD_RESULT}" >> scan.env
      
      if [ ${THRESHOLD_RESULT} -eq 0 ]; then
        echo "✅ Security scan passed threshold requirements"
      else
        echo "❌ Security scan failed to meet threshold requirements"
        # Uncomment to enforce threshold as a gate
        # exit ${THRESHOLD_RESULT}
      fi
  artifacts:
    paths:
      - scan-results.json
      - scan-summary.md
    reports:
      dotenv: scan.env

generate_report:
  stage: report
  needs: [run_scan]
  script:
    - |
      # Install SAF CLI if needed in this stage
      which saf || npm install -g @mitre/saf
      
      # Generate a more comprehensive report
      saf view -i scan-results.json --output scan-report.html
      
      # Create a simple markdown report for the MR
      cat > scan-report.md << EOF
      # Security Scan Results
      
      ## Summary
      
      $(cat scan-summary.md)
      
      ## Threshold Check
      
      ${THRESHOLD_PASSED} -eq 0 && echo "✅ **PASSED**" || echo "❌ **FAILED**"
      
      Threshold: ${THRESHOLD_VALUE}%
      
      ## Details
      
      For full results, see the artifacts.
      EOF
  artifacts:
    paths:
      - scan-report.html
      - scan-report.md
    when: always

cleanup:
  stage: cleanup
  needs: [run_scan]
  when: always  # Run even if previous stages failed
  script:
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    - |
      # Delete all resources
      kubectl delete pod/${TARGET_POD} -n ${SCANNER_NAMESPACE} --ignore-not-found
      kubectl delete role/scanner-role-${CI_PIPELINE_ID} -n ${SCANNER_NAMESPACE} --ignore-not-found
      kubectl delete sa/scanner-sa-${CI_PIPELINE_ID} -n ${SCANNER_NAMESPACE} --ignore-not-found
      kubectl delete rolebinding/scanner-binding-${CI_PIPELINE_ID} \
        -n ${SCANNER_NAMESPACE} --ignore-not-found
```

### Step 3: Advanced Approach: Pipeline-Specific Namespaces

!!! security-note "Security Consideration"
    For higher security, you can isolate each scan pipeline in its own namespace to provide complete resource isolation.

Create a more secure version with isolated namespaces:

```yaml
# Add this to your .gitlab-ci.yml
deploy_container:
  script:
    - |
      # Create namespace with unique name for this pipeline
      PIPELINE_NAMESPACE="${SCANNER_NAMESPACE}-${CI_PIPELINE_ID}"
      kubectl create namespace ${PIPELINE_NAMESPACE}
      
      # Set variable for other stages
      echo "PIPELINE_NAMESPACE=${PIPELINE_NAMESPACE}" >> deploy.env
      
      # Create pod in isolated namespace
      cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: Pod
      metadata:
        name: scan-target
        namespace: ${PIPELINE_NAMESPACE}
        labels:
          app: target-app
      spec:
        containers:
        - name: target
          image: registry.example.com/my-image:latest
          command: ["sleep", "1h"]
      EOF

# Update the cleanup stage to delete the entire namespace
cleanup:
  script:
    - |
      # Delete entire namespace (removes all resources at once)
      kubectl delete namespace ${PIPELINE_NAMESPACE}
```

### Step 4: Configure Quality Gates

!!! security-note "Security Consideration"
    Enforcing quality gates in the pipeline prevents security issues from progressing further in your CI/CD process.

Modify the `run_scan` job to enforce security thresholds:

```yaml
run_scan:
  script:
    # ... existing scan commands ...
    
    # Create a more advanced threshold file
    cat > threshold.yml << EOF
    compliance:
      min: ${THRESHOLD_VALUE}
    failed:
      critical:
        max: 0  # No critical failures allowed
      high: 
        max: 2  # At most 2 high failures allowed
    EOF
    
    # Apply threshold check with the configuration file
    saf threshold -i scan-results.json -t threshold.yml
    THRESHOLD_RESULT=$?
    
    # Enforce threshold as a quality gate
    exit ${THRESHOLD_RESULT}
```

## Security Best Practices

- Use short-lived tokens (15 minutes or less) to minimize the access window
- Configure RBAC to limit access to only the specific resources needed for scanning
- Use pipeline-specific resource names with unique identifiers (${CI_PIPELINE_ID})
- Store sensitive information in protected and masked CI/CD variables
- Clean up all resources even when pipelines fail using the `when: always` option
- Limit the permissions of the kubeconfig file stored in CI/CD variables
- Consider using pipeline-specific namespaces for complete isolation

## Verification Steps

1. Check that the pipeline runs successfully

   ```bash
   # Check the pipeline status in GitLab UI or using GitLab CLI
   gitlab-cli pipeline list --project your-project-id --status success
   ```

2. Verify that RBAC resources are automatically cleaned up after the pipeline completes

   ```bash
   # Should return "No resources found"
   kubectl get role/scanner-role-* -n ${SCANNER_NAMESPACE}
   kubectl get sa/scanner-sa-* -n ${SCANNER_NAMESPACE}
   ```

3. Review the scan results in the GitLab pipeline artifacts or merge request comments

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Pipeline fails at the deploy stage** | Verify that the kubeconfig has proper permissions and the namespace exists |
| **RBAC creation fails** | Check the permissions of the kubeconfig and ensure it can create RBAC resources |
| **Token generation fails** | Make sure you're using Kubernetes 1.24+ for the token creation command or implement a different token generation approach for older versions |
| **Scan fails with access denied** | Verify that the token is being correctly created and roles have the proper permissions |
| **SAF-CLI installation fails** | Ensure your GitLab runner has Node.js properly installed |

## Next Steps

After completing this task, consider:

- [Configure threshold values](thresholds-configuration.md) for comprehensive pass/fail criteria
- [Set up RBAC with label-based targeting](rbac-setup.md) for flexible container selection
- [Integrate with GitLab security dashboards](../integration/platforms/gitlab-ci.md#security-dashboard-integration)
- [Use GitLab services](../integration/platforms/gitlab-services.md) for advanced container scanning

## Related Security Considerations

- [Kubernetes RBAC Configuration](../rbac/index.md)
- [Ephemeral Security Credentials](../security/principles/ephemeral-creds.md)
- [Least Privilege Principle](../security/principles/least-privilege.md)
- [Token Management](../tokens/index.md)
- [Kubernetes Setup Best Practices](../kubernetes-setup/best-practices.md)
