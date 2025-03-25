# Distroless Container Scanning Workflow Integration

This page explains how to integrate the distroless container scanning workflow into CI/CD pipelines, focusing on the debug container approach.

## Overview

The distroless container scanning workflow uses ephemeral debug containers to provide a shell environment for scanning containers that don't include a shell, such as distroless containers. This approach is our recommended interim solution for distroless containers until direct support is available in the train-k8s-container plugin.

## Integration Workflow

The integration workflow for distroless container scanning involves:

1. Creating a service account with appropriate RBAC permissions
2. Generating a short-lived token for authentication
3. Creating an ephemeral debug container with access to the target container's filesystem
4. Running CINC Auditor from within the debug container using a chroot approach
5. Processing results with the SAF CLI
6. Cleaning up resources

## CI/CD Platform Integration

### GitHub Actions Integration

To integrate the distroless container scanning workflow into GitHub Actions:

1. Create a GitHub Actions workflow file in your repository:
   - Location: `.github/workflows/distroless-scan.yml`
   - This example assumes Kubernetes v1.23+ with ephemeral containers support

```yaml
name: Distroless Container Scan

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
          
          # Create service account with enhanced permissions for debug containers
          kubectl create serviceaccount debug-scanner-sa -n ${{ github.event.inputs.namespace }}
          
          # Create role with debug container permissions
          cat <<EOF | kubectl apply -f -
          apiVersion: rbac.authorization.k8s.io/v1
          kind: Role
          metadata:
            name: debug-scanner-role
            namespace: ${{ github.event.inputs.namespace }}
          rules:
          - apiGroups: [""]
            resources: ["pods"]
            verbs: ["get", "list"]
          - apiGroups: [""]
            resources: ["pods/exec"]
            verbs: ["create"]
          - apiGroups: [""]
            resources: ["pods/ephemeralcontainers"]
            verbs: ["get", "update"]
            resourceNames: ["${{ github.event.inputs.pod_name }}"]
          EOF
          
          # Create role binding
          kubectl create rolebinding debug-scanner-binding \
            --role=debug-scanner-role \
            --serviceaccount=${{ github.event.inputs.namespace }}:debug-scanner-sa \
            -n ${{ github.event.inputs.namespace }}
            
          # Generate token (valid for 30 minutes)
          TOKEN=$(kubectl create token debug-scanner-sa -n ${{ github.event.inputs.namespace }} --duration=30m)
          echo "SCANNER_TOKEN=$TOKEN" >> $GITHUB_ENV
          
      - name: Create debug container and scan
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
          
          # Create the debug container
          POD_JSON=$(kubectl get pod ${{ github.event.inputs.pod_name }} -n ${{ github.event.inputs.namespace }} -o json)
          
          # Add the debug container
          PATCHED_POD=$(echo "$POD_JSON" | jq --arg target "${{ github.event.inputs.container_name }}" '.spec.ephemeralContainers += [{
            "name": "debugger",
            "image": "busybox:latest",
            "command": ["sleep", "3600"],
            "targetContainerName": $target
          }]')
          
          # Apply the patch to add ephemeral container
          export KUBECONFIG=kubeconfig.yaml
          echo "$PATCHED_POD" | kubectl replace --raw /api/v1/namespaces/${{ github.event.inputs.namespace }}/pods/${{ github.event.inputs.pod_name }}/ephemeralcontainers -f -
          
          # Wait for debug container to start
          sleep 10
          
          # Install CINC Auditor
          curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor
          
          # Create an InSpec wrapper script to run in the debug container
          cat > scan-distroless.sh << 'EOF'
          #!/bin/sh
          # Extract the target container's process root directory
          TARGET_PROC_ROOT="/proc/1/root"
          PROFILE_PATH="$1"
          
          # Create temporary directory for results
          mkdir -p /tmp/results
          
          # Run InSpec with chroot
          cinc-auditor exec "$PROFILE_PATH" --target chroot://$TARGET_PROC_ROOT --reporter json:/tmp/results/results.json
          
          # Output the results
          cat /tmp/results/results.json
          EOF
          
          # Copy and execute the script in the debug container
          kubectl cp -n ${{ github.event.inputs.namespace }} scan-distroless.sh ${{ github.event.inputs.pod_name }}:scan-distroless.sh -c debugger
          kubectl exec -n ${{ github.event.inputs.namespace }} ${{ github.event.inputs.pod_name }} -c debugger -- chmod +x /scan-distroless.sh
          
          # Run CINC Auditor through the debug container
          kubectl exec -n ${{ github.event.inputs.namespace }} ${{ github.event.inputs.pod_name }} -c debugger -- /scan-distroless.sh ${{ github.event.inputs.profile }} > scan-results.json
          
      - name: Process results with SAF CLI
        run: |
          npm install -g @mitre/saf
          saf summary --input scan-results.json --output-md scan-summary.md
          
          # Generate the report for GitHub
          echo "## Distroless Container Scan Results" > $GITHUB_STEP_SUMMARY
          cat scan-summary.md >> $GITHUB_STEP_SUMMARY
          
      - name: Upload scan results
        uses: actions/upload-artifact@v3
        with:
          name: distroless-scan-results
          path: |
            scan-results.json
            scan-summary.md
            
      - name: Cleanup
        if: always()
        run: |
          kubectl delete rolebinding debug-scanner-binding -n ${{ github.event.inputs.namespace }}
          kubectl delete role debug-scanner-role -n ${{ github.event.inputs.namespace }}
          kubectl delete serviceaccount debug-scanner-sa -n ${{ github.event.inputs.namespace }}
```

### GitLab CI Integration

To integrate the distroless container scanning workflow into GitLab CI:

1. Create a `.gitlab-ci.yml` file in your repository:

```yaml
stages:
  - scan
  - report
  - cleanup

variables:
  NAMESPACE: "default"
  POD_NAME: "distroless-pod"
  CONTAINER_NAME: "distroless-container"
  PROFILE: "dev-sec/linux-baseline"

scan_distroless_container:
  stage: scan
  image: 
    name: ruby:3.0-slim
    entrypoint: [""]
  script:
    # Setup environment
    - apt-get update && apt-get install -y curl gnupg kubectl nodejs npm jq
    
    # Setup kubectl
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    
    # Setup service account and RBAC
    - kubectl create serviceaccount debug-scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: debug-scanner-role-$CI_PIPELINE_ID
        namespace: $NAMESPACE
      rules:
      - apiGroups: [""]
        resources: ["pods"]
        verbs: ["get", "list"]
      - apiGroups: [""]
        resources: ["pods/exec"]
        verbs: ["create"]
      - apiGroups: [""]
        resources: ["pods/ephemeralcontainers"]
        verbs: ["get", "update"]
        resourceNames: ["$POD_NAME"]
      EOF
    - kubectl create rolebinding debug-scanner-binding-$CI_PIPELINE_ID --role=debug-scanner-role-$CI_PIPELINE_ID --serviceaccount=$NAMESPACE:debug-scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE
    
    # Generate token
    - TOKEN=$(kubectl create token debug-scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE --duration=30m)
    
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
    
    # Create the debug container
    - POD_JSON=$(kubectl get pod $POD_NAME -n $NAMESPACE -o json)
    - |
      PATCHED_POD=$(echo "$POD_JSON" | jq --arg target "$CONTAINER_NAME" '.spec.ephemeralContainers += [{
        "name": "debugger",
        "image": "busybox:latest",
        "command": ["sleep", "3600"],
        "targetContainerName": $target
      }]')
    
    # Apply the patch to add ephemeral container
    - echo "$PATCHED_POD" | kubectl replace --raw /api/v1/namespaces/$NAMESPACE/pods/$POD_NAME/ephemeralcontainers -f -
    
    # Wait for debug container to start
    - sleep 10
    
    # Install CINC Auditor
    - curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor
    
    # Create an InSpec wrapper script to run in the debug container
    - |
      cat > scan-distroless.sh << 'EOF'
      #!/bin/sh
      # Extract the target container's process root directory
      TARGET_PROC_ROOT="/proc/1/root"
      PROFILE_PATH="$1"
      
      # Create temporary directory for results
      mkdir -p /tmp/results
      
      # Run InSpec with chroot
      cinc-auditor exec "$PROFILE_PATH" --target chroot://$TARGET_PROC_ROOT --reporter json:/tmp/results/results.json
      
      # Output the results
      cat /tmp/results/results.json
      EOF
    
    # Copy and execute the script in the debug container
    - kubectl cp -n $NAMESPACE scan-distroless.sh $POD_NAME:scan-distroless.sh -c debugger
    - kubectl exec -n $NAMESPACE $POD_NAME -c debugger -- chmod +x /scan-distroless.sh
    
    # Run CINC Auditor through the debug container
    - kubectl exec -n $NAMESPACE $POD_NAME -c debugger -- /scan-distroless.sh $PROFILE > scan-results.json
    
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
    - kubectl delete rolebinding debug-scanner-binding-$CI_PIPELINE_ID -n $NAMESPACE --ignore-not-found
    - kubectl delete role debug-scanner-role-$CI_PIPELINE_ID -n $NAMESPACE --ignore-not-found
    - kubectl delete serviceaccount debug-scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE --ignore-not-found
```

## Best Practices

When integrating the distroless container scanning workflow, follow these best practices:

1. **Kubernetes Version Check**: Ensure your Kubernetes cluster supports ephemeral containers
2. **Enhanced RBAC Permissions**: The debug container approach requires additional permissions compared to standard scanning
3. **Token Duration**: Use slightly longer token durations (30 minutes) as debugging might take more time
4. **Resource Cleanup**: Always clean up temporary resources, even on job failure
5. **Error Handling**: Implement robust error handling for the debug container creation
6. **Security Communication**: Clearly communicate the enhanced permissions required for this approach

## Security Considerations

- Store Kubernetes credentials as secrets/variables in your CI/CD platform
- Debug containers require additional permissions compared to standard scanning
- The ephemeral containers feature may not be available in all Kubernetes environments
- This approach requires `pods/ephemeralcontainers` permissions, which are more extensive than the standard approach

## Troubleshooting

### Common Issues

1. **Ephemeral Container Creation Fails**:
   - Verify Kubernetes version supports ephemeral containers (v1.23+)
   - Check RBAC includes permissions for `pods/ephemeralcontainers`
   - Ensure feature gate is enabled if using older Kubernetes versions

2. **Script Execution Failures**:
   - Check the debug container is running properly
   - Verify the target container path is accessible
   - Confirm the shell script has executable permissions

3. **Scan Failures**:
   - Check chroot access to the target container filesystem
   - Verify profile compatibility with distroless environment
   - Check the target process root directory exists

## Related Resources

- [Debug Container Approach](../../approaches/debug-container.md)
- [GitHub Actions Integration](../platforms/github-actions.md)
- [GitLab CI Integration](../platforms/gitlab-ci.md)
- [GitLab Services Integration](../platforms/gitlab-services.md)
- [Approach Mapping](../approach-mapping.md)