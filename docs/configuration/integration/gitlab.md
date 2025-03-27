# GitLab CI Integration

This guide covers configuring GitLab CI for integration with our CINC Auditor container scanning solution.

## Overview

GitLab CI/CD allows you to automate container scanning as part of your pipeline. This provides several benefits:

1. Automated security checks on every merge request or commit
2. Consistent security validation across all environments
3. Integration with your existing GitLab pipelines
4. Rich reporting and feedback directly in GitLab

## Basic Configuration

Create a GitLab CI configuration in `.gitlab-ci.yml`:

```yaml
stages:
  - scan

container-security-scan:
  stage: scan
  image: ruby:3.1-alpine
  before_script:
    # Install dependencies
    - apk add --no-cache curl bash nodejs npm
    - curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P auditor
    - npm install -g @mitre/saf
    
    # Set up kubeconfig
    - mkdir -p $HOME/.kube
    - echo "$KUBECONFIG" > $HOME/.kube/config
    - chmod 600 $HOME/.kube/config
  script:
    # Run the scan
    - cinc-auditor exec ./profiles/container-baseline \
        -t k8s-container://${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} \
        --reporter json:scan-results.json
    
    # Generate reports
    - saf summary --input scan-results.json --output-md summary.md
    - cat summary.md
    
    # Validate thresholds
    - saf threshold -i scan-results.json -t threshold.yml
  variables:
    NAMESPACE: default
    POD_NAME: nginx-pod
    CONTAINER_NAME: nginx
  artifacts:
    paths:
      - scan-results.json
      - summary.md
    when: always
```

## Required Variables

You'll need to configure these GitLab CI/CD variables:

- `KUBECONFIG`: Base64-encoded kubeconfig file for accessing your Kubernetes cluster

To set up these variables:

1. Navigate to your project on GitLab
2. Go to Settings > CI/CD > Variables
3. Click "Add Variable"
4. Add the required variables (mark sensitive ones as "Protected" and "Masked")

## Customizing the Pipeline

### Using Different Target Containers

```yaml
container-security-scan:
  parallel:
    matrix:
      - NAMESPACE: [default, kube-system]
        POD_NAME: [nginx-pod, redis-pod]
        CONTAINER_NAME: [nginx, redis]
  # ... other configuration ...
  script:
    - cinc-auditor exec ./profiles/container-baseline \
        -t k8s-container://${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} \
        --reporter json:scan-results-${CONTAINER_NAME}.json
```

### Environment-Specific Thresholds

```yaml
container-security-scan:
  # ... other configuration ...
  script:
    # ... scan script ...
    
    # Select threshold based on environment
    - |
      if [ "$CI_ENVIRONMENT_NAME" == "production" ]; then
        cp ./thresholds/production.yml ./threshold.yml
      elif [ "$CI_ENVIRONMENT_NAME" == "staging" ]; then
        cp ./thresholds/staging.yml ./threshold.yml
      else
        cp ./thresholds/development.yml ./threshold.yml
      fi
    
    # Validate thresholds
    - saf threshold -i scan-results.json -t threshold.yml
  environment:
    name: development
```

### Merge Request Comments

```yaml
container-security-scan:
  # ... other configuration ...
  script:
    # ... scan and validation ...
    
    # Add comment to merge request
    - |
      if [ -n "$CI_MERGE_REQUEST_IID" ]; then
        SUMMARY=$(cat summary.md)
        curl --request POST \
          --header "PRIVATE-TOKEN: $GITLAB_API_TOKEN" \
          --header "Content-Type: application/json" \
          --data "{ \"body\": \"## Security Scan Results\n\n${SUMMARY}\" }" \
          "${CI_API_V4_URL}/projects/${CI_PROJECT_ID}/merge_requests/${CI_MERGE_REQUEST_IID}/notes"
      fi
```

## Advanced Configurations

### Using GitLab Kubernetes Integration

This configuration uses GitLab's Kubernetes integration:

```yaml
container-security-scan:
  image: ruby:3.1-alpine
  before_script:
    - apk add --no-cache curl bash nodejs npm
    - curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P auditor
    - npm install -g @mitre/saf
  script:
    - cinc-auditor exec ./profiles/container-baseline \
        -t k8s-container://${KUBE_NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} \
        --reporter json:scan-results.json
    - saf threshold -i scan-results.json -t threshold.yml
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    kubernetes:
      namespace: $KUBE_NAMESPACE
```

### Using Docker-in-Docker Services

This configuration uses Docker-in-Docker to run a local Kubernetes cluster:

```yaml
container-security-scan:
  image: docker:20.10.16
  services:
    - docker:20.10.16-dind
  variables:
    DOCKER_HOST: tcp://docker:2376
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - apk add --no-cache curl bash nodejs npm git
    - curl -LO "https://dl.k8s.io/release/v1.25.0/bin/linux/amd64/kubectl"
    - chmod +x kubectl && mv kubectl /usr/local/bin/
    - curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    - chmod +x get_helm.sh && ./get_helm.sh
    - curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P auditor
    - npm install -g @mitre/saf
    
    # Set up kind cluster
    - apk add --no-cache python3 py3-pip
    - pip install kind
    - kind create cluster
    - kind get kubeconfig > $HOME/.kube/config
    
    # Deploy test container
    - kubectl create deployment nginx --image=nginx
    - kubectl wait --for=condition=available deployment/nginx --timeout=60s
    - export POD_NAME=$(kubectl get pods -l app=nginx -o name | cut -d/ -f2)
    - echo "POD_NAME=$POD_NAME" >> $BASH_ENV
  script:
    - cinc-auditor exec ./profiles/container-baseline \
        -t k8s-container://default/$POD_NAME/nginx \
        --reporter json:scan-results.json
    - saf threshold -i scan-results.json -t threshold.yml
```

### Using Different Profiles

```yaml
container-security-scan:
  parallel:
    matrix:
      - PROFILE: [container-baseline, kubernetes-cis]
  # ... other configuration ...
  script:
    - cinc-auditor exec ./profiles/${PROFILE} \
        -t k8s-container://${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} \
        --reporter json:scan-results-${PROFILE}.json
```

## Examples

See our GitLab CI examples for complete implementations:

- [Basic GitLab CI](../../gitlab-pipeline-examples/gitlab-ci.yml)
- [GitLab CI with Services](../../gitlab-pipeline-examples/gitlab-ci-with-services.yml)
- [Dynamic RBAC Scanning](../../gitlab-pipeline-examples/dynamic-rbac-scanning.yml)
- [Existing Cluster Scanning](../../gitlab-pipeline-examples/existing-cluster-scanning.yml)
- [Sidecar Scanner](../../gitlab-pipeline-examples/gitlab-ci-sidecar.yml)
- [Sidecar Scanner with Services](../../gitlab-pipeline-examples/gitlab-ci-sidecar-with-services.yml)

## Related Topics

- [SAF CLI Integration](saf-cli.md)
- [Threshold Configuration](../thresholds/index.md)
- [GitLab Pipelines](../../gitlab-pipeline-examples/index.md)
- [CI/CD Integration](../../integration/index.md)
