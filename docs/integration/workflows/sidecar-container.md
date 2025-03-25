# Sidecar Container Scanning Workflow Integration

This page explains how to integrate the sidecar container scanning workflow into CI/CD pipelines, providing a universal solution for both standard and distroless containers.

## Overview

The sidecar container scanning workflow uses a shared process namespace to allow a sidecar container with CINC Auditor to scan the main container's filesystem. This approach works for both standard and distroless containers and requires minimal RBAC permissions compared to the debug container approach.

## Integration Workflow

The integration workflow for sidecar container scanning involves:

1. Creating a pod with shared process namespace and a sidecar container
2. Running CINC Auditor from the sidecar container to scan the main container's filesystem
3. Extracting and processing scan results
4. Cleaning up resources after scanning

## CI/CD Platform Integration

### GitHub Actions Integration

To integrate the sidecar container scanning workflow into GitHub Actions:

1. Create a GitHub Actions workflow file in your repository:
   - Location: `.github/workflows/sidecar-scan.yml`
   - See the sample code below or reference `github-workflow-examples/sidecar-scanner.yml`

```yaml
name: Sidecar Container Scan

on:
  workflow_dispatch:
    inputs:
      namespace:
        description: 'Kubernetes namespace'
        required: true
        default: 'default'
      application_image:
        description: 'Application container image to scan'
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
          
      - name: Create sidecar scanner pod
        run: |
          cat <<EOF | kubectl apply -f -
          apiVersion: v1
          kind: Pod
          metadata:
            name: sidecar-scanner-${{ github.run_id }}
            namespace: ${{ github.event.inputs.namespace }}
          spec:
            shareProcessNamespace: true
            containers:
            - name: app
              image: ${{ github.event.inputs.application_image }}
              command: ["sleep", "3600"]
            - name: scanner
              image: registry.example.com/cinc-auditor-scanner:latest
              command: ["sleep", "3600"]
              securityContext:
                privileged: false
            restartPolicy: Never
          EOF
          
          # Wait for pod to be ready
          kubectl wait --for=condition=ready pod/sidecar-scanner-${{ github.run_id }} -n ${{ github.event.inputs.namespace }} --timeout=120s
          
      - name: Create scanning script
        run: |
          cat > scan-sidecar.sh << 'EOF'
          #!/bin/bash
          
          # Extract target container's PID
          TARGET_PID=$(pgrep -xo sleep)
          if [ -z "$TARGET_PID" ]; then
            echo "Error: Could not find target container PID"
            exit 1
          fi
          
          # Use target container's process namespace
          TARGET_ROOT="/proc/${TARGET_PID}/root"
          
          # Run CINC Auditor scan using chroot
          PROFILE="$1"
          cinc-auditor exec "$PROFILE" --target chroot://$TARGET_ROOT --reporter json:/tmp/scan-results.json
          
          # Output results
          cat /tmp/scan-results.json
          EOF
          
          # Copy script to scanner container
          kubectl cp -n ${{ github.event.inputs.namespace }} scan-sidecar.sh sidecar-scanner-${{ github.run_id }}:scan-sidecar.sh -c scanner
          kubectl exec -n ${{ github.event.inputs.namespace }} sidecar-scanner-${{ github.run_id }} -c scanner -- chmod +x /scan-sidecar.sh
          
      - name: Run scan
        run: |
          # Execute scan in sidecar container
          kubectl exec -n ${{ github.event.inputs.namespace }} sidecar-scanner-${{ github.run_id }} -c scanner -- /scan-sidecar.sh "${{ github.event.inputs.profile }}" > scan-results.json
          
      - name: Process results with SAF CLI
        run: |
          npm install -g @mitre/saf
          saf summary --input scan-results.json --output-md scan-summary.md
          
          # Generate report for GitHub
          echo "## Sidecar Container Scan Results" > $GITHUB_STEP_SUMMARY
          cat scan-summary.md >> $GITHUB_STEP_SUMMARY
          
      - name: Upload scan results
        uses: actions/upload-artifact@v3
        with:
          name: sidecar-scan-results
          path: |
            scan-results.json
            scan-summary.md
            
      - name: Cleanup
        if: always()
        run: |
          kubectl delete pod sidecar-scanner-${{ github.run_id }} -n ${{ github.event.inputs.namespace }}
```

### GitLab CI Integration

To integrate the sidecar container scanning workflow into GitLab CI:

1. Create a `.gitlab-ci.yml` file in your repository:
   - See the sample code below or reference `gitlab-pipeline-examples/gitlab-ci-sidecar.yml`

```yaml
stages:
  - scan
  - report
  - cleanup

variables:
  NAMESPACE: "default"
  APPLICATION_IMAGE: "alpine:latest"
  PROFILE: "dev-sec/linux-baseline"

scan_with_sidecar:
  stage: scan
  image: bitnami/kubectl
  script:
    # Setup kubectl
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    
    # Create sidecar scanner pod
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: Pod
      metadata:
        name: sidecar-scanner-${CI_PIPELINE_ID}
        namespace: ${NAMESPACE}
      spec:
        shareProcessNamespace: true
        containers:
        - name: app
          image: ${APPLICATION_IMAGE}
          command: ["sleep", "3600"]
        - name: scanner
          image: registry.example.com/cinc-auditor-scanner:latest
          command: ["sleep", "3600"]
          securityContext:
            privileged: false
        restartPolicy: Never
      EOF
    
    # Wait for pod to be ready
    - kubectl wait --for=condition=ready pod/sidecar-scanner-${CI_PIPELINE_ID} -n ${NAMESPACE} --timeout=120s
    
    # Create scanning script
    - |
      cat > scan-sidecar.sh << 'EOF'
      #!/bin/bash
      
      # Extract target container's PID
      TARGET_PID=$(pgrep -xo sleep)
      if [ -z "$TARGET_PID" ]; then
        echo "Error: Could not find target container PID"
        exit 1
      fi
      
      # Use target container's process namespace
      TARGET_ROOT="/proc/${TARGET_PID}/root"
      
      # Run CINC Auditor scan using chroot
      PROFILE="$1"
      cinc-auditor exec "$PROFILE" --target chroot://$TARGET_ROOT --reporter json:/tmp/scan-results.json
      
      # Output results
      cat /tmp/scan-results.json
      EOF
    
    # Copy script to scanner container
    - kubectl cp -n ${NAMESPACE} scan-sidecar.sh sidecar-scanner-${CI_PIPELINE_ID}:scan-sidecar.sh -c scanner
    - kubectl exec -n ${NAMESPACE} sidecar-scanner-${CI_PIPELINE_ID} -c scanner -- chmod +x /scan-sidecar.sh
    
    # Run scan
    - kubectl exec -n ${NAMESPACE} sidecar-scanner-${CI_PIPELINE_ID} -c scanner -- /scan-sidecar.sh "${PROFILE}" > scan-results.json
    
    # Install and run SAF CLI
    - apt-get update && apt-get install -y nodejs npm
    - npm install -g @mitre/saf
    - saf summary --input scan-results.json --output-md scan-summary.md
    - cat scan-summary.md
    
  artifacts:
    paths:
      - scan-results.json
      - scan-summary.md

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
    - kubectl delete pod sidecar-scanner-${CI_PIPELINE_ID} -n ${NAMESPACE} --ignore-not-found
```

### GitLab CI with Services

GitLab CI offers an enhanced approach using services for the sidecar scanner:

```yaml
stages:
  - scan
  - report
  - cleanup

variables:
  NAMESPACE: "default"
  APPLICATION_IMAGE: "alpine:latest"
  PROFILE: "dev-sec/linux-baseline"

scan_with_sidecar_service:
  stage: scan
  image: bitnami/kubectl
  services:
    - name: registry.example.com/cinc-auditor-scanner:latest
      alias: scanner-service
      entrypoint: ["sleep", "infinity"]
  script:
    # Setup kubectl
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    
    # Create sidecar scanner pod with service
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: Pod
      metadata:
        name: sidecar-scanner-${CI_PIPELINE_ID}
        namespace: ${NAMESPACE}
      spec:
        shareProcessNamespace: true
        containers:
        - name: app
          image: ${APPLICATION_IMAGE}
          command: ["sleep", "3600"]
        - name: scanner
          image: registry.example.com/cinc-auditor-scanner:latest
          command: ["sleep", "3600"]
          securityContext:
            privileged: false
        restartPolicy: Never
      EOF
    
    # Wait for pod to be ready
    - kubectl wait --for=condition=ready pod/sidecar-scanner-${CI_PIPELINE_ID} -n ${NAMESPACE} --timeout=120s
    
    # Use the scanner service for running the scan
    - docker exec -i scanner-service bash -c "cinc-auditor exec ${PROFILE} --target k8s://${NAMESPACE}/sidecar-scanner-${CI_PIPELINE_ID}/app --reporter json:/tmp/scan-results.json"
    - docker cp scanner-service:/tmp/scan-results.json ./scan-results.json
    
    # Process results
    - apt-get update && apt-get install -y nodejs npm
    - npm install -g @mitre/saf
    - saf summary --input scan-results.json --output-md scan-summary.md
    - cat scan-summary.md
    
  artifacts:
    paths:
      - scan-results.json
      - scan-summary.md

# Additional stages for report generation and cleanup
```

## Best Practices

When integrating the sidecar container scanning workflow, follow these best practices:

1. **Container Setup**: Always use the `shareProcessNamespace: true` setting in the pod spec
2. **Image Selection**: Use pre-built CINC Auditor scanner images for the sidecar container
3. **Process Identification**: Implement robust process identification for finding the target container
4. **Error Handling**: Include proper error handling for cases where the process can't be found
5. **Result Extraction**: Ensure scan results are properly extracted from the sidecar container
6. **Resource Cleanup**: Always clean up scanner pods after completion

## Security Considerations

- The sidecar approach requires minimal RBAC permissions compared to other approaches
- No need for ephemeral container or enhanced pod/exec permissions
- The pod spec requires shared process namespace, which is a security consideration
- The sidecar container does not need privileged access
- This approach requires modifying the pod specification, which may not be suitable for all workflows

## Troubleshooting

### Common Issues

1. **Process Identification Failures**:
   - Verify the target container is running the expected process
   - Check that the process search command is correct for your container
   - Consider using alternative process identification methods (e.g., by container name)

2. **Shared Namespace Issues**:
   - Verify Kubernetes version supports shared process namespaces
   - Check that the pod spec includes `shareProcessNamespace: true`
   - Ensure the cluster configuration allows shared process namespaces

3. **Scan Failures**:
   - Check the target container's filesystem is accessible from the sidecar
   - Verify the chroot path is correct
   - Ensure the CINC Auditor profile is compatible with the target environment

## Related Resources

- [Sidecar Container Approach](../../approaches/sidecar-container.md)
- [GitHub Actions Integration](../platforms/github-actions.md)
- [GitLab CI Integration](../platforms/gitlab-ci.md)
- [GitLab Services Integration](../platforms/gitlab-services.md)
- [Approach Mapping](../approach-mapping.md)