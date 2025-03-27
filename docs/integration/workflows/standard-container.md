# Standard Container Scanning Workflow Integration

This page explains how to integrate the standard container scanning workflow into CI/CD pipelines, focusing on the Kubernetes API approach.

## Overview

The standard container scanning workflow uses the train-k8s-container plugin to scan containers via the Kubernetes API. This is our recommended approach for standard containers in production environments.

## Integration Workflow

The integration workflow for standard container scanning involves:

1. Creating a service account with appropriate RBAC permissions
2. Generating a short-lived token for authentication
3. Running CINC Auditor with the train-k8s-container plugin
4. Processing results with the SAF CLI
5. Cleaning up resources

## CI/CD Platform Integration

### GitHub Actions Integration

To integrate the standard container scanning workflow into GitHub Actions:

1. Create a GitHub Actions workflow file in your repository:
   - Location: `.github/workflows/container-scan.yml`
   - See the sample code below or reference `github-workflow-examples/existing-cluster-scanning.yml`

```yaml
name: Kubernetes Container Scan

on:
  workflow_dispatch:
    inputs:
      namespace:
        description: 'Kubernetes namespace'
        required: true
        default: 'default'
      pod_name:
        description: 'Pod name to scan'
        required: true
      container_name:
        description: 'Container name to scan'
        required: true
      profile:
        description: 'InSpec profile to use'
        required: true
        default: 'dev-sec/linux-baseline'

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        
      - name: Setup Kubernetes credentials
        run: |
          # Setup kubeconfig
          echo "${{ secrets.KUBE_CONFIG }}" > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml
          
          # Create service account with limited permissions
          kubectl create serviceaccount scanner-sa -n ${{ github.event.inputs.namespace }}
          
          # Create role with limited permissions
          cat <<EOF | kubectl apply -f -
          apiVersion: rbac.authorization.k8s.io/v1
          kind: Role
          metadata:
            name: scanner-role
            namespace: ${{ github.event.inputs.namespace }}
          rules:
          - apiGroups: [""]
            resources: ["pods"]
            verbs: ["get", "list"]
          - apiGroups: [""]
            resources: ["pods/exec"]
            verbs: ["create"]
            resourceNames: ["${{ github.event.inputs.pod_name }}"]
          EOF
          
          # Create role binding
          kubectl create rolebinding scanner-binding \
            --role=scanner-role \
            --serviceaccount=${{ github.event.inputs.namespace }}:scanner-sa \
            -n ${{ github.event.inputs.namespace }}
            
          # Generate token (valid for 15 minutes)
          TOKEN=$(kubectl create token scanner-sa -n ${{ github.event.inputs.namespace }} --duration=15m)
          echo "SCANNER_TOKEN=$TOKEN" >> $GITHUB_ENV
          
      - name: Install CINC Auditor
        run: |
          curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor
          cinc-auditor plugin install train-k8s-container
          
      - name: Run container scan
        run: |
          # Create scanner kubeconfig
          cat > scanner-kubeconfig.yaml <<EOF
          apiVersion: v1
          kind: Config
          clusters:
          - cluster:
              server: $(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')
              certificate-authority-data: $(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
            name: k8s-cluster
          contexts:
          - context:
              cluster: k8s-cluster
              user: scanner-user
              namespace: ${{ github.event.inputs.namespace }}
            name: scanner-context
          current-context: scanner-context
          users:
          - name: scanner-user
            user:
              token: ${{ env.SCANNER_TOKEN }}
          EOF
          
          # Run scan
          KUBECONFIG=scanner-kubeconfig.yaml cinc-auditor exec ${{ github.event.inputs.profile }} \
            -t k8s-container://${{ github.event.inputs.namespace }}/${{ github.event.inputs.pod_name }}/${{ github.event.inputs.container_name }} \
            --reporter json:scan-results.json
          
      - name: Process results with SAF CLI
        run: |
          npm install -g @mitre/saf
          saf summary --input scan-results.json --output-md scan-summary.md
          
          # Generate the report for GitHub
          echo "## Scan Results" > $GITHUB_STEP_SUMMARY
          cat scan-summary.md >> $GITHUB_STEP_SUMMARY
          
      - name: Upload scan results
        uses: actions/upload-artifact@v3
        with:
          name: scan-results
          path: |
            scan-results.json
            scan-summary.md
            
      - name: Cleanup
        if: always()
        run: |
          kubectl delete rolebinding scanner-binding -n ${{ github.event.inputs.namespace }}
          kubectl delete role scanner-role -n ${{ github.event.inputs.namespace }}
          kubectl delete serviceaccount scanner-sa -n ${{ github.event.inputs.namespace }}
```

### GitLab CI Integration

To integrate the standard container scanning workflow into GitLab CI:

1. Create a `.gitlab-ci.yml` file in your repository:
   - See the sample code below or reference `gitlab-pipeline-examples/gitlab-ci.yml`

```yaml
stages:
  - scan
  - report
  - cleanup

variables:
  NAMESPACE: "default"
  POD_NAME: "app-pod"
  CONTAINER_NAME: "app-container"
  PROFILE: "dev-sec/linux-baseline"

scan_container:
  stage: scan
  image: 
    name: ruby:3.0-slim
    entrypoint: [""]
  script:
    # Setup environment
    - apt-get update && apt-get install -y curl gnupg kubectl nodejs npm
    
    # Setup kubectl
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    
    # Setup service account and RBAC
    - kubectl create serviceaccount scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: scanner-role-$CI_PIPELINE_ID
        namespace: $NAMESPACE
      rules:
      - apiGroups: [""]
        resources: ["pods"]
        verbs: ["get", "list"]
      - apiGroups: [""]
        resources: ["pods/exec"]
        verbs: ["create"]
        resourceNames: ["$POD_NAME"]
      EOF
    - kubectl create rolebinding scanner-binding-$CI_PIPELINE_ID --role=scanner-role-$CI_PIPELINE_ID --serviceaccount=$NAMESPACE:scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE
    
    # Generate token
    - TOKEN=$(kubectl create token scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE --duration=15m)
    
    # Install CINC Auditor and plugin
    - curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor
    - cinc-auditor plugin install train-k8s-container
    
    # Create scanner kubeconfig
    - |
      cat > scanner-kubeconfig.yaml << EOF
      apiVersion: v1
      kind: Config
      clusters:
      - cluster:
          server: $(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')
          certificate-authority-data: $(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
        name: k8s-cluster
      contexts:
      - context:
          cluster: k8s-cluster
          user: scanner-user
          namespace: $NAMESPACE
        name: scanner-context
      current-context: scanner-context
      users:
      - name: scanner-user
        user:
          token: $TOKEN
      EOF
    
    # Run scan
    - KUBECONFIG=scanner-kubeconfig.yaml cinc-auditor exec $PROFILE -t k8s-container://$NAMESPACE/$POD_NAME/$CONTAINER_NAME --reporter json:scan-results.json
    
    # Process results with SAF CLI
    - npm install -g @mitre/saf
    - saf summary --input scan-results.json --output-md scan-summary.md
    - cat scan-summary.md
    
  artifacts:
    paths:
      - scan-results.json
      - scan-summary.md
      - scanner-kubeconfig.yaml

generate_report:
  stage: report
  image: node:16
  script:
    - npm install -g @mitre/saf
    - saf view -i scan-results.json --output scan-report.html
  artifacts:
    paths:
      - scan-report.html

cleanup:
  stage: cleanup
  image: bitnami/kubectl
  when: always
  script:
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    - kubectl delete rolebinding scanner-binding-$CI_PIPELINE_ID -n $NAMESPACE --ignore-not-found
    - kubectl delete role scanner-role-$CI_PIPELINE_ID -n $NAMESPACE --ignore-not-found
    - kubectl delete serviceaccount scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE --ignore-not-found
```

## Configuration {#configuration}

When configuring the standard container scanning workflow, you should set the following parameters:

1. **Namespace**: The Kubernetes namespace where the target pod is running
2. **Pod Name**: The name of the pod containing the container to scan
3. **Container Name**: The name of the container within the pod to scan
4. **Profile Path**: The CINC Auditor profile to use for scanning
5. **Token Duration**: Duration for the short-lived authentication token (default: 15 minutes)
6. **SAF CLI Settings**: Configuration for threshold validation and reporting

These settings can be configured through environment variables as detailed in the [Environment Variables](../configuration/environment-variables.md) documentation.

## Best Practices

When integrating the standard container scanning workflow, follow these best practices:

1. **Limited Scope**: Always scope RBAC permissions to the specific pods being scanned
2. **Short-lived Tokens**: Use tokens with short durations (15-30 minutes)
3. **Resource Cleanup**: Always clean up temporary resources, even on job failure
4. **SAF CLI Integration**: Use the SAF CLI to generate human-readable reports
5. **Failure Handling**: Configure proper error handling for scan failures
6. **CI Variables**: Use CI variables for flexible configuration

## Security Considerations

- Store Kubernetes credentials as secrets/variables in your CI/CD platform
- Avoid storing tokens or kubeconfig files in the repository
- Always use the least privilege principle for RBAC configurations
- Ensure token expiration is properly set to minimize exposure

## Troubleshooting

### Common Issues

1. **Access Denied Errors**:
   - Verify the token is valid and not expired
   - Check RBAC permissions are properly configured
   - Ensure the pod name matches exactly

2. **Plugin Installation Failures**:
   - Verify network connectivity
   - Check Ruby and gem versions compatibility
   - Consider using pre-built Docker images with the plugin installed

3. **Scan Failures**:
   - Check the plugin version is compatible with your Kubernetes version
   - Ensure the pod and container exist and are running
   - Verify the profile path is correct

## Related Resources

- [GitHub Actions Integration](../platforms/github-actions.md)
- [GitLab CI Integration](../platforms/gitlab-ci.md)
- [GitLab Services Integration](../platforms/gitlab-services.md)
- [Approach Mapping](../approach-mapping.md)
- [Kubernetes API Approach](../../approaches/kubernetes-api/index.md)
