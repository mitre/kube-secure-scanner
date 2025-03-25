# GitHub Actions Integration Examples

This page provides practical examples of integrating container scanning with GitHub Actions.

## Overview

GitHub Actions offers a flexible CI/CD platform for integrating the Kube CINC Secure Scanner. These examples demonstrate real-world implementations for various scanning approaches.

## Standard Container Scanning Example

This example demonstrates scanning standard containers using the Kubernetes API approach:

```yaml
name: Standard Container Scan

on:
  workflow_dispatch:
    inputs:
      namespace:
        description: 'Kubernetes namespace'
        required: true
        default: 'default'
      pod_name:
        description: 'Pod to scan'
        required: true
      container_name:
        description: 'Container to scan'
        required: true
      profile:
        description: 'InSpec profile to use'
        required: true
        default: 'dev-sec/linux-baseline'
      threshold:
        description: 'Minimum passing score (0-100)'
        required: true
        default: '70'

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        
      - name: Setup Kubernetes access
        run: |
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml
          
          # Create service account
          kubectl create serviceaccount scanner-sa -n ${{ github.event.inputs.namespace }}
          
          # Create role
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
          
          # Generate token
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
            --reporter json:scan-results.json cli
      
      - name: Process scan results
        run: |
          # Install SAF CLI
          npm install -g @mitre/saf
          
          # Generate scan summary
          saf summary --input scan-results.json --output-md scan-summary.md
          
          # Apply threshold check
          saf threshold -i scan-results.json -t ${{ github.event.inputs.threshold }}
          THRESHOLD_RESULT=$?
          
          # Create GitHub summary
          echo "## Container Scan Results" > $GITHUB_STEP_SUMMARY
          cat scan-summary.md >> $GITHUB_STEP_SUMMARY
          
          echo "## Threshold Check" >> $GITHUB_STEP_SUMMARY
          if [ $THRESHOLD_RESULT -eq 0 ]; then
            echo "✅ **PASSED** - Met or exceeded threshold of ${{ github.event.inputs.threshold }}%" >> $GITHUB_STEP_SUMMARY
          else
            echo "❌ **FAILED** - Did not meet threshold of ${{ github.event.inputs.threshold }}%" >> $GITHUB_STEP_SUMMARY
          fi
      
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

## Dynamic RBAC Scanning Example

This example demonstrates scanning pods based on dynamic label selection:

```yaml
name: Dynamic RBAC Pod Scanning

on:
  workflow_dispatch:
    inputs:
      namespace:
        description: 'Kubernetes namespace'
        required: true
        default: 'default'
      label_selector:
        description: 'Label selector (format: key=value)'
        required: true
        default: 'scan=true'
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
        
      - name: Setup Kubernetes access
        run: |
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml
          
          # Parse label selector
          LABEL_KEY=$(echo "${{ github.event.inputs.label_selector }}" | cut -d= -f1)
          LABEL_VALUE=$(echo "${{ github.event.inputs.label_selector }}" | cut -d= -f2)
          
          # Create service account
          kubectl create serviceaccount label-scanner-sa -n ${{ github.event.inputs.namespace }}
          
          # Create role with label selector
          cat <<EOF | kubectl apply -f -
          apiVersion: rbac.authorization.k8s.io/v1
          kind: Role
          metadata:
            name: label-scanner-role
            namespace: ${{ github.event.inputs.namespace }}
          rules:
          - apiGroups: [""]
            resources: ["pods"]
            verbs: ["get", "list"]
          - apiGroups: [""]
            resources: ["pods/exec"]
            verbs: ["create"]
          EOF
          
          # Create role binding
          kubectl create rolebinding label-scanner-binding \
            --role=label-scanner-role \
            --serviceaccount=${{ github.event.inputs.namespace }}:label-scanner-sa \
            -n ${{ github.event.inputs.namespace }}
          
          # Generate token
          TOKEN=$(kubectl create token label-scanner-sa -n ${{ github.event.inputs.namespace }} --duration=15m)
          echo "SCANNER_TOKEN=$TOKEN" >> $GITHUB_ENV
      
      - name: Install CINC Auditor
        run: |
          curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor
          cinc-auditor plugin install train-k8s-container
      
      - name: Scan labeled pods
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
          
          # Find pods with matching label
          PODS=$(kubectl get pods -n ${{ github.event.inputs.namespace }} -l ${{ github.event.inputs.label_selector }} -o name | cut -d/ -f2)
          
          if [ -z "$PODS" ]; then
            echo "No pods found with label ${{ github.event.inputs.label_selector }}"
            exit 1
          fi
          
          echo "Found pods with label ${{ github.event.inputs.label_selector }}:"
          echo "$PODS"
          
          # Install SAF CLI
          npm install -g @mitre/saf
          
          # Create summary header for GitHub
          echo "## Dynamic Label Scan Results" > $GITHUB_STEP_SUMMARY
          echo "Label selector: \`${{ github.event.inputs.label_selector }}\`" >> $GITHUB_STEP_SUMMARY
          echo "Pods found: $(echo "$PODS" | wc -l)" >> $GITHUB_STEP_SUMMARY
          echo "---" >> $GITHUB_STEP_SUMMARY
          
          # Scan each pod
          for POD in $PODS; do
            echo "Scanning pod: $POD"
            
            # Get first container name
            CONTAINER=$(kubectl get pod $POD -n ${{ github.event.inputs.namespace }} -o jsonpath='{.spec.containers[0].name}')
            
            # Run scan
            KUBECONFIG=scanner-kubeconfig.yaml cinc-auditor exec ${{ github.event.inputs.profile }} \
              -t k8s-container://${{ github.event.inputs.namespace }}/$POD/$CONTAINER \
              --reporter json:$POD-results.json cli
            
            # Process results
            saf summary --input $POD-results.json --output-md $POD-summary.md
            
            # Add to GitHub summary
            echo "### Results for pod: $POD" >> $GITHUB_STEP_SUMMARY
            cat $POD-summary.md >> $GITHUB_STEP_SUMMARY
            echo "---" >> $GITHUB_STEP_SUMMARY
          done
      
      - name: Upload scan results
        uses: actions/upload-artifact@v3
        with:
          name: labeled-scan-results
          path: |
            *-results.json
            *-summary.md
      
      - name: Cleanup
        if: always()
        run: |
          kubectl delete rolebinding label-scanner-binding -n ${{ github.event.inputs.namespace }}
          kubectl delete role label-scanner-role -n ${{ github.event.inputs.namespace }}
          kubectl delete serviceaccount label-scanner-sa -n ${{ github.event.inputs.namespace }}
```

## Complete CI/CD Pipeline Example

This example demonstrates a complete CI/CD pipeline with build, deploy, scan, and quality gates:

```yaml
name: CI/CD Pipeline with Container Scanning

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      image_tag:
        description: 'Image tag to build'
        required: true
        default: 'latest'
      scan_namespace:
        description: 'Namespace for deployment and scanning'
        required: true
        default: 'default'
      threshold:
        description: 'Minimum passing score (0-100)'
        required: true
        default: '70'

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image_tag: ${{ steps.set-tag.outputs.image_tag }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        
      - name: Set image tag
        id: set-tag
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "image_tag=${{ github.event.inputs.image_tag }}" >> $GITHUB_OUTPUT
          else
            echo "image_tag=sha-$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT
          fi
      
      - name: Build Docker image
        run: |
          docker build -t myapp:${{ steps.set-tag.outputs.image_tag }} .
          
          # For demo purposes, we're not pushing to a registry
          # In a real scenario, you would push the image here
          
  deploy:
    needs: build
    runs-on: ubuntu-latest
    outputs:
      pod_name: ${{ steps.deploy.outputs.pod_name }}
    steps:
      - name: Set namespace
        id: namespace
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "namespace=${{ github.event.inputs.scan_namespace }}" >> $GITHUB_OUTPUT
          else
            echo "namespace=default" >> $GITHUB_OUTPUT
          fi
      
      - name: Setup Kubernetes
        run: |
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml
      
      - name: Deploy to Kubernetes
        id: deploy
        run: |
          # Generate a unique name for this deployment
          POD_NAME="myapp-${{ github.run_id }}"
          echo "pod_name=$POD_NAME" >> $GITHUB_OUTPUT
          
          # Create deployment
          cat <<EOF | kubectl apply -f -
          apiVersion: v1
          kind: Pod
          metadata:
            name: $POD_NAME
            namespace: ${{ steps.namespace.outputs.namespace }}
            labels:
              app: myapp
              scan: "true"
              github-run: "${{ github.run_id }}"
          spec:
            containers:
            - name: app
              image: myapp:${{ needs.build.outputs.image_tag }}
              # For demo, we're using a locally built image
              # In reality, you'd use an image from a registry
              imagePullPolicy: Never
              command: ["sleep", "3600"]
          EOF
          
          # Wait for pod to be ready
          kubectl wait --for=condition=ready pod/$POD_NAME -n ${{ steps.namespace.outputs.namespace }} --timeout=120s
          
  scan:
    needs: [build, deploy]
    runs-on: ubuntu-latest
    steps:
      - name: Set namespace
        id: namespace
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "namespace=${{ github.event.inputs.scan_namespace }}" >> $GITHUB_OUTPUT
          else
            echo "namespace=default" >> $GITHUB_OUTPUT
          fi
      
      - name: Set threshold
        id: threshold
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "value=${{ github.event.inputs.threshold }}" >> $GITHUB_OUTPUT
          else
            echo "value=70" >> $GITHUB_OUTPUT
          fi
      
      - name: Setup scanner access
        run: |
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml
          
          # Create service account with limited permissions
          kubectl create serviceaccount pipeline-scanner-sa -n ${{ steps.namespace.outputs.namespace }}
          
          # Create role limited to the specific pod
          cat <<EOF | kubectl apply -f -
          apiVersion: rbac.authorization.k8s.io/v1
          kind: Role
          metadata:
            name: pipeline-scanner-role
            namespace: ${{ steps.namespace.outputs.namespace }}
          rules:
          - apiGroups: [""]
            resources: ["pods"]
            verbs: ["get", "list"]
          - apiGroups: [""]
            resources: ["pods/exec"]
            verbs: ["create"]
            resourceNames: ["${{ needs.deploy.outputs.pod_name }}"]
          EOF
          
          # Create role binding
          kubectl create rolebinding pipeline-scanner-binding \
            --role=pipeline-scanner-role \
            --serviceaccount=${{ steps.namespace.outputs.namespace }}:pipeline-scanner-sa \
            -n ${{ steps.namespace.outputs.namespace }}
          
          # Generate token
          TOKEN=$(kubectl create token pipeline-scanner-sa -n ${{ steps.namespace.outputs.namespace }} --duration=15m)
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
              namespace: ${{ steps.namespace.outputs.namespace }}
            name: scanner-context
          current-context: scanner-context
          users:
          - name: scanner-user
            user:
              token: ${{ env.SCANNER_TOKEN }}
          EOF
          
          # Run scan (using both a custom profile and a baseline)
          KUBECONFIG=scanner-kubeconfig.yaml cinc-auditor exec dev-sec/linux-baseline \
            -t k8s-container://${{ steps.namespace.outputs.namespace }}/${{ needs.deploy.outputs.pod_name }}/app \
            --reporter json:baseline-results.json cli
      
      - name: Process scan results
        run: |
          # Install SAF CLI
          npm install -g @mitre/saf
          
          # Generate scan summary
          saf summary --input baseline-results.json --output-md baseline-summary.md
          
          # Apply threshold check
          saf threshold -i baseline-results.json -t ${{ steps.threshold.outputs.value }}
          THRESHOLD_RESULT=$?
          
          # Create GitHub summary
          echo "## Container Scan Results" > $GITHUB_STEP_SUMMARY
          echo "### Linux Baseline" >> $GITHUB_STEP_SUMMARY
          cat baseline-summary.md >> $GITHUB_STEP_SUMMARY
          
          echo "## Threshold Check" >> $GITHUB_STEP_SUMMARY
          if [ $THRESHOLD_RESULT -eq 0 ]; then
            echo "✅ **PASSED** - Met or exceeded threshold of ${{ steps.threshold.outputs.value }}%" >> $GITHUB_STEP_SUMMARY
          else
            echo "❌ **FAILED** - Did not meet threshold of ${{ steps.threshold.outputs.value }}%" >> $GITHUB_STEP_SUMMARY
            # Uncomment to fail the workflow if threshold not met
            # exit 1
          fi
      
      - name: Upload scan results
        uses: actions/upload-artifact@v3
        with:
          name: pipeline-scan-results
          path: |
            *-results.json
            *-summary.md
      
      - name: Cleanup
        if: always()
        run: |
          kubectl delete rolebinding pipeline-scanner-binding -n ${{ steps.namespace.outputs.namespace }}
          kubectl delete role pipeline-scanner-role -n ${{ steps.namespace.outputs.namespace }}
          kubectl delete serviceaccount pipeline-scanner-sa -n ${{ steps.namespace.outputs.namespace }}
  
  cleanup:
    needs: [build, deploy, scan]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - name: Set namespace
        id: namespace
        run: |
          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "namespace=${{ github.event.inputs.scan_namespace }}" >> $GITHUB_OUTPUT
          else
            echo "namespace=default" >> $GITHUB_OUTPUT
          fi
      
      - name: Cleanup resources
        run: |
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml
          
          # Delete the pod
          kubectl delete pod ${{ needs.deploy.outputs.pod_name }} -n ${{ steps.namespace.outputs.namespace }}
```

## Using GitHub Actions for Distroless Container Scanning

This example demonstrates scanning distroless containers using the debug container approach:

```yaml
name: Distroless Container Scan

on:
  workflow_dispatch:
    inputs:
      namespace:
        description: 'Kubernetes namespace'
        required: true
        default: 'default'
      distroless_pod:
        description: 'Distroless pod to scan'
        required: true
      distroless_container:
        description: 'Distroless container to scan'
        required: true
      profile:
        description: 'InSpec profile to use'
        required: true
        default: 'dev-sec/linux-baseline'

jobs:
  scan_distroless:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        
      - name: Setup Kubernetes with debug container permissions
        run: |
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml
          
          # Create service account
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
            resourceNames: ["${{ github.event.inputs.distroless_pod }}"]
          EOF
          
          # Create role binding
          kubectl create rolebinding debug-scanner-binding \
            --role=debug-scanner-role \
            --serviceaccount=${{ github.event.inputs.namespace }}:debug-scanner-sa \
            -n ${{ github.event.inputs.namespace }}
          
          # Generate token
          TOKEN=$(kubectl create token debug-scanner-sa -n ${{ github.event.inputs.namespace }} --duration=30m)
          echo "SCANNER_TOKEN=$TOKEN" >> $GITHUB_ENV
      
      - name: Create debug container
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
          
          # Get pod JSON
          POD_JSON=$(kubectl get pod ${{ github.event.inputs.distroless_pod }} -n ${{ github.event.inputs.namespace }} -o json)
          
          # Add debug container
          PATCHED_POD=$(echo "$POD_JSON" | jq --arg target "${{ github.event.inputs.distroless_container }}" '.spec.ephemeralContainers += [{
            "name": "debugger",
            "image": "busybox:latest",
            "command": ["sleep", "3600"],
            "targetContainerName": $target
          }]')
          
          # Apply patch
          echo "$PATCHED_POD" | kubectl replace --raw /api/v1/namespaces/${{ github.event.inputs.namespace }}/pods/${{ github.event.inputs.distroless_pod }}/ephemeralcontainers -f -
          
          # Wait for debug container to start
          sleep 10
      
      - name: Install CINC Auditor
        run: |
          curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor
      
      - name: Scan through debug container
        run: |
          # Create scan script
          cat > scan-distroless.sh << 'EOF'
          #!/bin/sh
          # Get target container's root filesystem
          TARGET_PROC_ROOT="/proc/1/root"
          PROFILE="$1"
          
          # Create results directory
          mkdir -p /tmp/results
          
          # Run InSpec with chroot
          cinc-auditor exec "$PROFILE" --target chroot://$TARGET_PROC_ROOT --reporter json:/tmp/results/results.json
          
          # Output results
          cat /tmp/results/results.json
          EOF
          
          # Copy script to debug container
          export KUBECONFIG=kubeconfig.yaml
          kubectl cp -n ${{ github.event.inputs.namespace }} scan-distroless.sh ${{ github.event.inputs.distroless_pod }}:scan-distroless.sh -c debugger
          kubectl exec -n ${{ github.event.inputs.namespace }} ${{ github.event.inputs.distroless_pod }} -c debugger -- chmod +x /scan-distroless.sh
          
          # Run scan
          kubectl exec -n ${{ github.event.inputs.namespace }} ${{ github.event.inputs.distroless_pod }} -c debugger -- /scan-distroless.sh ${{ github.event.inputs.profile }} > distroless-results.json
      
      - name: Process scan results
        run: |
          # Install SAF CLI
          npm install -g @mitre/saf
          
          # Generate scan summary
          saf summary --input distroless-results.json --output-md distroless-summary.md
          
          # Create GitHub summary
          echo "## Distroless Container Scan Results" > $GITHUB_STEP_SUMMARY
          cat distroless-summary.md >> $GITHUB_STEP_SUMMARY
      
      - name: Upload scan results
        uses: actions/upload-artifact@v3
        with:
          name: distroless-scan-results
          path: |
            distroless-results.json
            distroless-summary.md
      
      - name: Cleanup
        if: always()
        run: |
          kubectl delete rolebinding debug-scanner-binding -n ${{ github.event.inputs.namespace }}
          kubectl delete role debug-scanner-role -n ${{ github.event.inputs.namespace }}
          kubectl delete serviceaccount debug-scanner-sa -n ${{ github.event.inputs.namespace }}
```

## Related Resources

- [GitHub Actions Integration Guide](../platforms/github-actions.md)
- [Standard Container Workflow](../workflows/standard-container.md)
- [Distroless Container Workflow](../workflows/distroless-container.md)
- [Sidecar Container Workflow](../workflows/sidecar-container.md)
- [Security Workflows](../workflows/security-workflows.md)
- [Approach Mapping](../approach-mapping.md)
- [GitHub Workflow Examples](../../github-workflow-examples/index.md)