# GitLab CI/CD Integration Examples

This page provides practical examples of integrating container scanning with GitLab CI/CD pipelines.

## Overview

GitLab CI/CD offers powerful capabilities for integrating the Kube CINC Secure Scanner. These examples demonstrate real-world implementations for various scanning approaches.

## Basic Container Scanning Example

This example demonstrates basic container scanning using the Kubernetes API approach:

```yaml
image: debian:stable-slim

variables:
  KUBE_NAMESPACE: default
  KUBE_POD_NAME: target-app
  KUBE_CONTAINER_NAME: app
  INSPEC_PROFILE: dev-sec/linux-baseline
  THRESHOLD_SCORE: 70

stages:
  - scan
  - process
  - cleanup

scan:
  stage: scan
  before_script:
    - apt-get update && apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release
    - curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    - echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
    - apt-get update && apt-get install -y kubectl
    - curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor
    - cinc-auditor plugin install train-k8s-container

    # Setup Kubernetes access
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    
    # Create service account with limited scope
    - kubectl create serviceaccount scanner-sa -n $KUBE_NAMESPACE
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: scanner-role
        namespace: $KUBE_NAMESPACE
      rules:
      - apiGroups: [""]
        resources: ["pods"]
        verbs: ["get", "list"]
      - apiGroups: [""]
        resources: ["pods/exec"]
        verbs: ["create"]
        resourceNames: ["$KUBE_POD_NAME"]
      EOF
    - kubectl create rolebinding scanner-binding --role=scanner-role --serviceaccount=$KUBE_NAMESPACE:scanner-sa -n $KUBE_NAMESPACE
    
    # Generate token
    - TOKEN=$(kubectl create token scanner-sa -n $KUBE_NAMESPACE --duration=15m)
    
    # Create scanner kubeconfig
    - |
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
          namespace: $KUBE_NAMESPACE
        name: scanner-context
      current-context: scanner-context
      users:
      - name: scanner-user
        user:
          token: $TOKEN
      EOF

  script:
    # Run scan
    - KUBECONFIG=scanner-kubeconfig.yaml cinc-auditor exec $INSPEC_PROFILE -t k8s-container://$KUBE_NAMESPACE/$KUBE_POD_NAME/$KUBE_CONTAINER_NAME --reporter json:scan-results.json cli
  
  artifacts:
    paths:
      - scan-results.json
    expire_in: 1 week

process_results:
  stage: process
  image: node:16-alpine
  dependencies:
    - scan
  before_script:
    - npm install -g @mitre/saf
  script:
    # Generate scan summary
    - saf summary --input scan-results.json --output-md scan-summary.md
    
    # Apply threshold check
    - saf threshold -i scan-results.json -t $THRESHOLD_SCORE
    - if [ $? -ne 0 ]; then echo "Threshold check failed"; exit 1; fi
    
    # Generate HTML report
    - saf report -i scan-results.json -o scan-report.html
  
  artifacts:
    paths:
      - scan-summary.md
      - scan-report.html
    expire_in: 1 week
    
cleanup:
  stage: cleanup
  before_script:
    - apt-get update && apt-get install -y kubectl
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
  script:
    - kubectl delete rolebinding scanner-binding -n $KUBE_NAMESPACE
    - kubectl delete role scanner-role -n $KUBE_NAMESPACE
    - kubectl delete serviceaccount scanner-sa -n $KUBE_NAMESPACE
  when: always
```

## Dynamic RBAC Scanning Example

This example demonstrates scanning pods based on label selectors:

```yaml
image: debian:stable-slim

variables:
  KUBE_NAMESPACE: default
  LABEL_SELECTOR: scan=true
  INSPEC_PROFILE: dev-sec/linux-baseline

stages:
  - scan
  - process
  - cleanup

scan:
  stage: scan
  before_script:
    - apt-get update && apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release jq
    - curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    - echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
    - apt-get update && apt-get install -y kubectl
    - curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor
    - cinc-auditor plugin install train-k8s-container

    # Setup Kubernetes access
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    
    # Parse label selector
    - LABEL_KEY=$(echo "$LABEL_SELECTOR" | cut -d= -f1)
    - LABEL_VALUE=$(echo "$LABEL_SELECTOR" | cut -d= -f2)
    
    # Create service account
    - kubectl create serviceaccount label-scanner-sa -n $KUBE_NAMESPACE
    
    # Create role with label selector
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: label-scanner-role
        namespace: $KUBE_NAMESPACE
      rules:
      - apiGroups: [""]
        resources: ["pods"]
        verbs: ["get", "list"]
      - apiGroups: [""]
        resources: ["pods/exec"]
        verbs: ["create"]
      EOF
    
    # Create role binding
    - kubectl create rolebinding label-scanner-binding --role=label-scanner-role --serviceaccount=$KUBE_NAMESPACE:label-scanner-sa -n $KUBE_NAMESPACE
    
    # Generate token
    - TOKEN=$(kubectl create token label-scanner-sa -n $KUBE_NAMESPACE --duration=15m)
    
    # Create scanner kubeconfig
    - |
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
          namespace: $KUBE_NAMESPACE
        name: scanner-context
      current-context: scanner-context
      users:
      - name: scanner-user
        user:
          token: $TOKEN
      EOF

  script:
    # Find pods with matching label
    - PODS=$(kubectl get pods -n $KUBE_NAMESPACE -l $LABEL_SELECTOR -o name | cut -d/ -f2)
    
    - if [ -z "$PODS" ]; then
    -   echo "No pods found with label $LABEL_SELECTOR"
    -   exit 1
    - fi
    
    - echo "Found pods with label $LABEL_SELECTOR:"
    - echo "$PODS"
    
    # Scan each pod
    - mkdir -p scan-results
    - |
      for POD in $PODS; do
        echo "Scanning pod: $POD"
        
        # Get first container name
        CONTAINER=$(kubectl get pod $POD -n $KUBE_NAMESPACE -o jsonpath='{.spec.containers[0].name}')
        
        # Run scan
        KUBECONFIG=scanner-kubeconfig.yaml cinc-auditor exec $INSPEC_PROFILE \
          -t k8s-container://$KUBE_NAMESPACE/$POD/$CONTAINER \
          --reporter json:scan-results/$POD-results.json cli
      done
  
  artifacts:
    paths:
      - scan-results/
    expire_in: 1 week

process_results:
  stage: process
  image: node:16-alpine
  dependencies:
    - scan
  before_script:
    - npm install -g @mitre/saf
  script:
    # Process each result file
    - mkdir -p scan-reports
    - |
      for RESULT_FILE in scan-results/*-results.json; do
        POD_NAME=$(basename $RESULT_FILE | cut -d- -f1)
        
        # Generate scan summary
        saf summary --input $RESULT_FILE --output-md scan-reports/$POD_NAME-summary.md
        
        # Generate HTML report
        saf report -i $RESULT_FILE -o scan-reports/$POD_NAME-report.html
      done
    
    # Generate combined report
    - echo "# Scan Results for Pods with Label $LABEL_SELECTOR" > combined-summary.md
    - for SUMMARY in scan-reports/*-summary.md; do
    -   POD_NAME=$(basename $SUMMARY | cut -d- -f1)
    -   echo "## Pod: $POD_NAME" >> combined-summary.md
    -   cat $SUMMARY >> combined-summary.md
    -   echo >> combined-summary.md
    - done
  
  artifacts:
    paths:
      - scan-reports/
      - combined-summary.md
    expire_in: 1 week
    
cleanup:
  stage: cleanup
  before_script:
    - apt-get update && apt-get install -y kubectl
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
  script:
    - kubectl delete rolebinding label-scanner-binding -n $KUBE_NAMESPACE
    - kubectl delete role label-scanner-role -n $KUBE_NAMESPACE
    - kubectl delete serviceaccount label-scanner-sa -n $KUBE_NAMESPACE
  when: always
```

## Sidecar Container with Services Example

This example demonstrates using GitLab's CI/CD services feature for sidecar container scanning:

```yaml
image: debian:stable-slim

variables:
  KUBE_NAMESPACE: default
  TARGET_POD_NAME: app-pod
  INSPEC_PROFILE: dev-sec/linux-baseline
  THRESHOLD_SCORE: 70

services:
  - name: registry.gitlab.com/your-org/cinc-scanner:latest
    alias: scanner

stages:
  - scan
  - process

before_script:
  - apt-get update && apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release
  - curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  - echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
  - apt-get update && apt-get install -y kubectl
  - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
  - export KUBECONFIG=kubeconfig.yaml

scan:
  stage: scan
  script:
    # Create pod with shared process namespace
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: Pod
      metadata:
        name: $TARGET_POD_NAME
        namespace: $KUBE_NAMESPACE
      spec:
        shareProcessNamespace: true
        containers:
        - name: app
          image: ${CI_REGISTRY_IMAGE}:${CI_COMMIT_SHORT_SHA}
          # Your container configuration here
        - name: scanner
          image: registry.gitlab.com/your-org/cinc-scanner:latest
          command: ["sleep", "600"]  # Keep the container alive for scanning
      EOF
    
    # Wait for pod to be ready
    - kubectl wait --for=condition=ready pod/$TARGET_POD_NAME -n $KUBE_NAMESPACE --timeout=120s
    
    # Run scan using the sidecar container
    - |
      kubectl exec -n $KUBE_NAMESPACE $TARGET_POD_NAME -c scanner -- bash -c "
        cinc-auditor exec $INSPEC_PROFILE --target chroot:///proc/1/root --reporter json:/tmp/scan-results.json
      "
    
    # Retrieve results
    - kubectl cp $KUBE_NAMESPACE/$TARGET_POD_NAME:/tmp/scan-results.json scan-results.json -c scanner
  
  artifacts:
    paths:
      - scan-results.json
    expire_in: 1 week

process_results:
  stage: process
  image: node:16-alpine
  dependencies:
    - scan
  before_script:
    - npm install -g @mitre/saf
  script:
    # Generate scan summary
    - saf summary --input scan-results.json --output-md scan-summary.md
    
    # Apply threshold check
    - saf threshold -i scan-results.json -t $THRESHOLD_SCORE
    - if [ $? -ne 0 ]; then echo "Threshold check failed"; exit 1; fi
    
    # Generate HTML report
    - saf report -i scan-results.json -o scan-report.html
  
  artifacts:
    paths:
      - scan-summary.md
      - scan-report.html
    reports:
      junit: scan-results.xml
    expire_in: 1 week

after_script:
  - kubectl delete pod $TARGET_POD_NAME -n $KUBE_NAMESPACE
```

## Distroless Container Scanning Example

This example demonstrates scanning distroless containers using the debug container approach:

```yaml
image: debian:stable-slim

variables:
  KUBE_NAMESPACE: default
  DISTROLESS_POD: distroless-app
  DISTROLESS_CONTAINER: app
  INSPEC_PROFILE: dev-sec/linux-baseline

stages:
  - setup
  - scan
  - process
  - cleanup

setup:
  stage: setup
  script:
    - apt-get update && apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release jq
    - curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    - echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
    - apt-get update && apt-get install -y kubectl
    
    # Setup Kubernetes access
    - echo "$KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    
    # Create service account with debug container permissions
    - kubectl create serviceaccount debug-scanner-sa -n $KUBE_NAMESPACE
    
    # Create role with debug container permissions
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: debug-scanner-role
        namespace: $KUBE_NAMESPACE
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
        resourceNames: ["$DISTROLESS_POD"]
      EOF
    
    # Create role binding
    - kubectl create rolebinding debug-scanner-binding --role=debug-scanner-role --serviceaccount=$KUBE_NAMESPACE:debug-scanner-sa -n $KUBE_NAMESPACE
    
    # Generate token
    - TOKEN=$(kubectl create token debug-scanner-sa -n $KUBE_NAMESPACE --duration=30m)
    - echo "SCANNER_TOKEN=$TOKEN" > scanner-token.txt
  
  artifacts:
    paths:
      - scanner-token.txt
      - kubeconfig.yaml

scan:
  stage: scan
  dependencies:
    - setup
  script:
    - apt-get update && apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release jq
    - curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    - echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
    - apt-get update && apt-get install -y kubectl
    - export KUBECONFIG=kubeconfig.yaml
    - export SCANNER_TOKEN=$(cat scanner-token.txt)
    
    # Create scanner kubeconfig
    - |
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
          namespace: $KUBE_NAMESPACE
        name: scanner-context
      current-context: scanner-context
      users:
      - name: scanner-user
        user:
          token: $SCANNER_TOKEN
      EOF
    
    # Get pod JSON
    - POD_JSON=$(kubectl get pod $DISTROLESS_POD -n $KUBE_NAMESPACE -o json)
    
    # Add debug container
    - |
      PATCHED_POD=$(echo "$POD_JSON" | jq --arg target "$DISTROLESS_CONTAINER" '.spec.ephemeralContainers += [{
        "name": "debugger",
        "image": "busybox:latest",
        "command": ["sleep", "3600"],
        "targetContainerName": $target
      }]')
    
    # Apply patch
    - echo "$PATCHED_POD" | kubectl replace --raw /api/v1/namespaces/$KUBE_NAMESPACE/pods/$DISTROLESS_POD/ephemeralcontainers -f -
    
    # Wait for debug container to start
    - sleep 10
    
    # Install CINC in the ephemeral container
    - curl -L https://omnitruck.cinc.sh/install.sh > install-cinc.sh
    
    # Create scan script
    - |
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
    
    # Copy scripts to debug container
    - export KUBECONFIG=scanner-kubeconfig.yaml
    - kubectl cp -n $KUBE_NAMESPACE install-cinc.sh $DISTROLESS_POD:install-cinc.sh -c debugger
    - kubectl cp -n $KUBE_NAMESPACE scan-distroless.sh $DISTROLESS_POD:scan-distroless.sh -c debugger
    - kubectl exec -n $KUBE_NAMESPACE $DISTROLESS_POD -c debugger -- chmod +x /scan-distroless.sh
    - kubectl exec -n $KUBE_NAMESPACE $DISTROLESS_POD -c debugger -- chmod +x /install-cinc.sh
    
    # Install CINC in debug container
    - kubectl exec -n $KUBE_NAMESPACE $DISTROLESS_POD -c debugger -- sh -c "apk add --no-cache bash && /install-cinc.sh -P cinc-auditor"
    
    # Run scan
    - kubectl exec -n $KUBE_NAMESPACE $DISTROLESS_POD -c debugger -- /scan-distroless.sh $INSPEC_PROFILE > distroless-results.json
  
  artifacts:
    paths:
      - distroless-results.json
    expire_in: 1 week

process_results:
  stage: process
  image: node:16-alpine
  dependencies:
    - scan
  before_script:
    - npm install -g @mitre/saf
  script:
    # Generate scan summary
    - saf summary --input distroless-results.json --output-md distroless-summary.md
    
    # Generate HTML report
    - saf report -i distroless-results.json -o distroless-report.html
  
  artifacts:
    paths:
      - distroless-summary.md
      - distroless-report.html
    expire_in: 1 week
    
cleanup:
  stage: cleanup
  dependencies:
    - setup
  before_script:
    - apt-get update && apt-get install -y kubectl
    - export KUBECONFIG=kubeconfig.yaml
  script:
    - kubectl delete rolebinding debug-scanner-binding -n $KUBE_NAMESPACE
    - kubectl delete role debug-scanner-role -n $KUBE_NAMESPACE
    - kubectl delete serviceaccount debug-scanner-sa -n $KUBE_NAMESPACE
  when: always
```

## Existing Cluster Integration Example

This example demonstrates scanning pods in an existing Kubernetes cluster:

```yaml
image: debian:stable-slim

variables:
  KUBE_NAMESPACE: production
  LABEL_SELECTOR: component=api
  INSPEC_PROFILE: dev-sec/linux-baseline
  THRESHOLD_SCORE: 85

stages:
  - scan
  - process
  - cleanup

scan:
  stage: scan
  before_script:
    - apt-get update && apt-get install -y curl apt-transport-https ca-certificates gnupg lsb-release jq
    - curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    - echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
    - apt-get update && apt-get install -y kubectl
    - curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor
    - cinc-auditor plugin install train-k8s-container

    # Setup Kubernetes access
    - echo "$PROD_KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
    
    # Create time-limited service account with least privilege
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: scanner-temp-sa
        namespace: $KUBE_NAMESPACE
        annotations:
          gitlab.io/ci-job: "${CI_JOB_ID}"
          gitlab.io/pipeline: "${CI_PIPELINE_ID}"
      EOF
    
    # Create role with label-based permissions
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: rbac.authorization.k8s.io/v1
      kind: Role
      metadata:
        name: scanner-temp-role
        namespace: $KUBE_NAMESPACE
        annotations:
          gitlab.io/ci-job: "${CI_JOB_ID}"
          gitlab.io/pipeline: "${CI_PIPELINE_ID}"
      rules:
      - apiGroups: [""]
        resources: ["pods"]
        verbs: ["get", "list"]
        resourceNames: []  # Will be filled dynamically
      - apiGroups: [""]
        resources: ["pods/exec"]
        verbs: ["create"]
        resourceNames: []  # Will be filled dynamically
      EOF
    
    # Find pods with matching label
    - PODS=$(kubectl get pods -n $KUBE_NAMESPACE -l $LABEL_SELECTOR -o name | cut -d/ -f2)
    
    - if [ -z "$PODS" ]; then
    -   echo "No pods found with label $LABEL_SELECTOR"
    -   exit 1
    - fi
    
    - echo "Found pods with label $LABEL_SELECTOR:"
    - echo "$PODS"
    
    # Update role with specific pod names
    - |
      POD_NAMES_JSON="[]"
      for POD in $PODS; do
        POD_NAMES_JSON=$(echo $POD_NAMES_JSON | jq --arg pod "$POD" '. + [$pod]')
      done
      
      ROLE_JSON=$(kubectl get role scanner-temp-role -n $KUBE_NAMESPACE -o json)
      
      # Update pod/get rule
      UPDATED_ROLE=$(echo $ROLE_JSON | jq --argjson pods "$POD_NAMES_JSON" '.rules[0].resourceNames = $pods')
      
      # Update pod/exec rule
      UPDATED_ROLE=$(echo $UPDATED_ROLE | jq --argjson pods "$POD_NAMES_JSON" '.rules[1].resourceNames = $pods')
      
      # Apply updated role
      echo $UPDATED_ROLE | kubectl apply -f -
    
    # Create role binding
    - |
      cat <<EOF | kubectl apply -f -
      apiVersion: rbac.authorization.k8s.io/v1
      kind: RoleBinding
      metadata:
        name: scanner-temp-binding
        namespace: $KUBE_NAMESPACE
        annotations:
          gitlab.io/ci-job: "${CI_JOB_ID}"
          gitlab.io/pipeline: "${CI_PIPELINE_ID}"
      subjects:
      - kind: ServiceAccount
        name: scanner-temp-sa
        namespace: $KUBE_NAMESPACE
      roleRef:
        apiGroup: rbac.authorization.k8s.io
        kind: Role
        name: scanner-temp-role
      EOF
    
    # Generate token
    - TOKEN=$(kubectl create token scanner-temp-sa -n $KUBE_NAMESPACE --duration=15m)
    
    # Create scanner kubeconfig
    - |
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
          namespace: $KUBE_NAMESPACE
        name: scanner-context
      current-context: scanner-context
      users:
      - name: scanner-user
        user:
          token: $TOKEN
      EOF

  script:
    # Scan each pod
    - mkdir -p scan-results
    - |
      for POD in $PODS; do
        echo "Scanning pod: $POD"
        
        # Get first container name
        CONTAINER=$(kubectl get pod $POD -n $KUBE_NAMESPACE -o jsonpath='{.spec.containers[0].name}')
        
        # Run scan
        KUBECONFIG=scanner-kubeconfig.yaml cinc-auditor exec $INSPEC_PROFILE \
          -t k8s-container://$KUBE_NAMESPACE/$POD/$CONTAINER \
          --reporter json:scan-results/$POD-results.json cli
      done
  
  artifacts:
    paths:
      - scan-results/
    expire_in: 1 week

process_results:
  stage: process
  image: node:16-alpine
  dependencies:
    - scan
  before_script:
    - npm install -g @mitre/saf
  script:
    # Process each result file
    - mkdir -p scan-reports
    - |
      for RESULT_FILE in scan-results/*-results.json; do
        if [ -f "$RESULT_FILE" ]; then
          POD_NAME=$(basename $RESULT_FILE | cut -d- -f1)
          
          # Generate scan summary
          saf summary --input $RESULT_FILE --output-md scan-reports/$POD_NAME-summary.md
          
          # Apply threshold check
          echo "Checking threshold for $POD_NAME"
          saf threshold -i $RESULT_FILE -t $THRESHOLD_SCORE
          THRESHOLD_RESULT=$?
          
          if [ $THRESHOLD_RESULT -ne 0 ]; then
            echo "Pod $POD_NAME failed threshold check!"
            FAILED_PODS="$FAILED_PODS $POD_NAME"
          fi
          
          # Generate HTML report
          saf report -i $RESULT_FILE -o scan-reports/$POD_NAME-report.html
        fi
      done
    
    # Generate combined report
    - echo "# Security Scan Results for Production Pods" > combined-report.md
    - echo "Label selector: \`$LABEL_SELECTOR\`" >> combined-report.md
    - echo "Threshold: $THRESHOLD_SCORE%" >> combined-report.md
    - echo >> combined-report.md
    
    - if [ -n "$FAILED_PODS" ]; then
    -   echo "## Failed Pods" >> combined-report.md
    -   echo "The following pods did not meet the minimum security threshold:" >> combined-report.md
    -   echo >> combined-report.md
    -   for POD in $FAILED_PODS; do
    -     echo "- $POD" >> combined-report.md
    -   done
    -   echo >> combined-report.md
    -   # Fail job if any pods failed threshold check
    -   echo "Some pods failed security threshold check"
    -   exit 1
    - fi
  
  artifacts:
    paths:
      - scan-reports/
      - combined-report.md
    expire_in: 1 week
    
cleanup:
  stage: cleanup
  before_script:
    - apt-get update && apt-get install -y kubectl
    - echo "$PROD_KUBE_CONFIG" | base64 -d > kubeconfig.yaml
    - export KUBECONFIG=kubeconfig.yaml
  script:
    - kubectl delete rolebinding scanner-temp-binding -n $KUBE_NAMESPACE
    - kubectl delete role scanner-temp-role -n $KUBE_NAMESPACE
    - kubectl delete serviceaccount scanner-temp-sa -n $KUBE_NAMESPACE
  when: always
```

## Related Resources

- [GitLab CI/CD Integration Guide](../platforms/gitlab-ci.md)
- [GitLab Services Integration Guide](../platforms/gitlab-services.md)
- [Standard Container Workflow](../workflows/standard-container.md)
- [Distroless Container Workflow](../workflows/distroless-container.md)
- [Sidecar Container Workflow](../workflows/sidecar-container.md)
- [Security Workflows](../workflows/security-workflows.md)
- [Approach Mapping](../approach-mapping.md)
- [GitLab Pipeline Examples](../../../gitlab-pipeline-examples/index.md)