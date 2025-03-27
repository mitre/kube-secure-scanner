# Security-Focused Integration Workflows

This page outlines security-focused workflows for integrating container scanning into CI/CD pipelines, with an emphasis on security best practices and enhanced RBAC models.

## Overview

Security is a primary concern when integrating container scanning into CI/CD pipelines. This document focuses on integrating enhanced security practices into scanning workflows, including:

1. RBAC best practices
2. Secure token handling
3. Token revocation
4. Least privilege implementation
5. Credentials protection
6. Audit logging

## Enhanced RBAC Integration

### Label-Based RBAC Workflow

The label-based RBAC workflow enhances security by allowing scanning only of containers with specific labels:

```yaml
# Enhanced security using label selectors
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
  resourceNames: []
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
  labelSelector: 
    matchExpressions:
    - key: scan-enabled
      operator: In
      values: ["true"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  labelSelector: 
    matchExpressions:
    - key: scan-enabled
      operator: In
      values: ["true"]
```

### Implementing Label-Based RBAC in GitHub Actions

```yaml
name: Secure Label-Based Scanning

on:
  workflow_dispatch:
    inputs:
      namespace:
        description: 'Kubernetes namespace'
        required: true
        default: 'production'
      label_selector:
        description: 'Label selector (format: key=value)'
        required: true
        default: 'scan-enabled=true'
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
        
      - name: Setup secure RBAC with label selector
        run: |
          # Setup kubeconfig
          echo "${{ secrets.KUBE_CONFIG }}" > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml
          
          # Extract key and value from label selector
          LABEL_KEY=$(echo "${{ github.event.inputs.label_selector }}" | cut -d= -f1)
          LABEL_VALUE=$(echo "${{ github.event.inputs.label_selector }}" | cut -d= -f2)
          
          # Create service account
          kubectl create serviceaccount secure-scanner-sa -n ${{ github.event.inputs.namespace }}
          
          # Create role with label selector
          cat <<EOF | kubectl apply -f -
          apiVersion: rbac.authorization.k8s.io/v1
          kind: Role
          metadata:
            name: secure-scanner-role
            namespace: ${{ github.event.inputs.namespace }}
          rules:
          - apiGroups: [""]
            resources: ["pods"]
            verbs: ["get", "list"]
          - apiGroups: [""]
            resources: ["pods/exec"]
            verbs: ["create"]
            resourceNames: []
          EOF
          
          # Create role binding
          kubectl create rolebinding secure-scanner-binding \
            --role=secure-scanner-role \
            --serviceaccount=${{ github.event.inputs.namespace }}:secure-scanner-sa \
            -n ${{ github.event.inputs.namespace }}
            
          # Generate token with short duration (15 minutes)
          TOKEN=$(kubectl create token secure-scanner-sa -n ${{ github.event.inputs.namespace }} --duration=15m)
          echo "SCANNER_TOKEN=$TOKEN" >> $GITHUB_ENV
          
      - name: Run secure scan
        run: |
          # Install CINC Auditor
          curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor
          cinc-auditor plugin install train-k8s-container
          
          # Create scanner kubeconfig
          cat > secure-kubeconfig.yaml <<EOF
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
          
          # Get pods with the specified label
          LABEL_SELECTOR="${{ github.event.inputs.label_selector }}"
          PODS=$(kubectl get pods -n ${{ github.event.inputs.namespace }} -l $LABEL_SELECTOR -o name | cut -d/ -f2)
          
          # Check if any pods match the label
          if [ -z "$PODS" ]; then
            echo "No pods found with label $LABEL_SELECTOR"
            exit 1
          fi
          
          # Scan each matching pod
          for POD in $PODS; do
            echo "Scanning pod: $POD"
            
            # Get the first container in the pod
            CONTAINER=$(kubectl get pod $POD -n ${{ github.event.inputs.namespace }} -o jsonpath='{.spec.containers[0].name}')
            
            # Run scan
            KUBECONFIG=secure-kubeconfig.yaml cinc-auditor exec ${{ github.event.inputs.profile }} \
              -t k8s-container://${{ github.event.inputs.namespace }}/$POD/$CONTAINER \
              --reporter json:$POD-results.json
            
            # Process results
            npm install -g @mitre/saf
            saf summary --input $POD-results.json --output-md $POD-summary.md
            
            echo "## Scan Results for $POD" >> $GITHUB_STEP_SUMMARY
            cat $POD-summary.md >> $GITHUB_STEP_SUMMARY
            echo "---" >> $GITHUB_STEP_SUMMARY
          done
          
      - name: Upload scan results
        uses: actions/upload-artifact@v3
        with:
          name: secure-scan-results
          path: |
            *-results.json
            *-summary.md
            
      - name: Cleanup and revoke token
        if: always()
        run: |
          # Delete RBAC resources to immediately revoke access
          kubectl delete rolebinding secure-scanner-binding -n ${{ github.event.inputs.namespace }}
          kubectl delete role secure-scanner-role -n ${{ github.event.inputs.namespace }}
          kubectl delete serviceaccount secure-scanner-sa -n ${{ github.event.inputs.namespace }}
          
          # Secure deletion of kubeconfig
          shred -u secure-kubeconfig.yaml
```

### Implementing Label-Based RBAC in GitLab CI

```yaml
stages:
  - scan
  - report
  - cleanup

variables:
  NAMESPACE: "production"
  LABEL_SELECTOR: "scan-enabled=true"
  PROFILE: "dev-sec/linux-baseline"
  TOKEN_DURATION: "15m"

setup_and_scan:
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
    
    # Extract key and value from label selector
    - LABEL_KEY=$(echo "$LABEL_SELECTOR" | cut -d= -f1)
    - LABEL_VALUE=$(echo "$LABEL_SELECTOR" | cut -d= -f2)
    
    # Setup secure service account and RBAC
    - kubectl create serviceaccount secure-scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: secure-scanner-role-$CI_PIPELINE_ID
        namespace: $NAMESPACE
      rules:
      - apiGroups: [""]
        resources: ["pods"]
        verbs: ["get", "list"]
      - apiGroups: [""]
        resources: ["pods/exec"]
        verbs: ["create"]
      EOF
    - kubectl create rolebinding secure-scanner-binding-$CI_PIPELINE_ID --role=secure-scanner-role-$CI_PIPELINE_ID --serviceaccount=$NAMESPACE:secure-scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE
    
    # Generate secure token
    - TOKEN=$(kubectl create token secure-scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE --duration=$TOKEN_DURATION)
    
    # Create secure scanner kubeconfig
    - |
      cat > secure-kubeconfig.yaml << EOF
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
    
    # Get pods with the specified label
    - PODS=$(kubectl get pods -n $NAMESPACE -l $LABEL_SELECTOR -o name | cut -d/ -f2)
    
    # Check if any pods match the label
    - |
      if [ -z "$PODS" ]; then
        echo "No pods found with label $LABEL_SELECTOR"
        exit 1
      fi
    
    # Install CINC Auditor
    - curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor
    - cinc-auditor plugin install train-k8s-container
    - npm install -g @mitre/saf
    
    # Scan each matching pod
    - |
      for POD in $PODS; do
        echo "Scanning pod: $POD"
        
        # Get the first container in the pod
        CONTAINER=$(kubectl get pod $POD -n $NAMESPACE -o jsonpath='{.spec.containers[0].name}')
        
        # Run scan
        KUBECONFIG=secure-kubeconfig.yaml cinc-auditor exec $PROFILE \
          -t k8s-container://$NAMESPACE/$POD/$CONTAINER \
          --reporter json:$POD-results.json
        
        # Process results
        saf summary --input $POD-results.json --output-md $POD-summary.md
        echo "Results for $POD:"
        cat $POD-summary.md
        echo "---"
      done
    
    # Audit logging
    - |
      echo "Security Scan Audit Log" > audit-log.txt
      echo "Timestamp: $(date -u)" >> audit-log.txt
      echo "Pipeline: $CI_PIPELINE_ID" >> audit-log.txt
      echo "Namespace: $NAMESPACE" >> audit-log.txt
      echo "Label Selector: $LABEL_SELECTOR" >> audit-log.txt
      echo "Token Duration: $TOKEN_DURATION" >> audit-log.txt
      echo "Pods Scanned: $PODS" >> audit-log.txt
    
    # Secure token handling
    - shred -u secure-kubeconfig.yaml
    
  artifacts:
    paths:
      - "*-results.json"
      - "*-summary.md"
      - "audit-log.txt"

cleanup:
  stage: cleanup
  image: bitnami/kubectl
  when: always
  script:
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    - kubectl delete rolebinding secure-scanner-binding-$CI_PIPELINE_ID -n $NAMESPACE --ignore-not-found
    - kubectl delete role secure-scanner-role-$CI_PIPELINE_ID -n $NAMESPACE --ignore-not-found
    - kubectl delete serviceaccount secure-scanner-sa-$CI_PIPELINE_ID -n $NAMESPACE --ignore-not-found
    - shred -u kubeconfig.yaml
```

## Security Enhancements for CI/CD Integration

### Short-lived Tokens

Always use short-lived tokens with explicit durations:

```bash
# Generate token with 15-minute duration
TOKEN=$(kubectl create token scanner-sa -n $NAMESPACE --duration=15m)
```

### Immediate Token Revocation

Implement immediate token revocation after scanning:

```bash
# Delete RBAC resources to immediately revoke access
kubectl delete rolebinding scanner-binding -n $NAMESPACE
kubectl delete role scanner-role -n $NAMESPACE
kubectl delete serviceaccount scanner-sa -n $NAMESPACE
```

### Secure Credential Handling

Implement secure handling of credentials:

```bash
# Secure deletion of sensitive files
shred -u kubeconfig.yaml

# Avoid storing tokens in variables when possible
KUBECONFIG=scanner-kubeconfig.yaml cinc-auditor exec $PROFILE -t k8s-container://...
```

### Audit Logging

Add comprehensive audit logging to your scanning workflows:

```bash
# Create audit log
echo "Security Scan Audit Log" > audit-log.txt
echo "Timestamp: $(date -u)" >> audit-log.txt
echo "CI Job: $CI_JOB_ID" >> audit-log.txt
echo "Namespace: $NAMESPACE" >> audit-log.txt
echo "Pod: $POD" >> audit-log.txt
echo "Container: $CONTAINER" >> audit-log.txt
echo "Profile: $PROFILE" >> audit-log.txt
echo "Token Duration: 15m" >> audit-log.txt
```

## CI/CD Security Best Practices

When implementing container scanning in CI/CD pipelines, follow these security best practices:

1. **Least Privilege Principle**: Provide only the minimum required permissions
2. **Short-lived Credentials**: Use tokens with the shortest practical lifetime
3. **Secure Storage**: Store sensitive data in secure CI/CD variables/secrets
4. **Immediate Cleanup**: Clean up resources immediately after scanning
5. **Audit Logging**: Implement comprehensive audit logging for all scan operations
6. **Token Revocation**: Actively revoke tokens after use instead of waiting for expiration
7. **Secure Outputs**: Handle scan results securely, especially for security findings
8. **Secure Credential Handling**: Avoid exposing credentials in logs or command lines
9. **CI/CD Pipeline Security**: Ensure the CI/CD pipeline itself is secure
10. **Separate Service Accounts**: Use dedicated service accounts for scanning operations

## Related Resources

- [RBAC Configuration](../../rbac/index.md)
- [Label-Based RBAC](../../rbac/label-based.md)
- [Service Accounts](../../service-accounts/index.md)
- [Tokens](../../tokens/index.md)
- [Security Analysis](../../security/risk/index.md)
- [GitHub Actions Integration](../platforms/github-actions.md)
- [GitLab CI Integration](../platforms/gitlab-ci.md)
