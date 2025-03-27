# CI/CD Pipeline Integration

This guide explains how to integrate the Secure CINC Auditor Kubernetes Container Scanning solution into CI/CD pipelines.

## Overview

CI/CD integration is ideal for:

- Automated security scanning in deployment pipelines
- DevSecOps workflows
- Container validation before deployment
- Continuous compliance monitoring

Integrating container scanning into CI/CD pipelines helps catch security issues early in the development lifecycle.

## Integration Approaches

There are several approaches to CI/CD integration:

1. **Direct Script Integration**: Execute scanning scripts directly in pipelines
2. **Container-based Integration**: Run scanners as containers in pipeline stages
3. **Helm-based Integration**: Deploy and execute scanners using Helm in pipelines
4. **API-based Integration**: Trigger scans via API calls from pipelines

## GitHub Actions Integration

### Basic GitHub Actions Integration

1. Add the GitHub Actions workflow to your repository:

```yaml
# .github/workflows/container-scan.yml
name: Container Security Scan
on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Kubernetes
        uses: engineerd/setup-kind@v0.5.0
        
      - name: Deploy scanner
        run: ./kubernetes-scripts/setup-minikube.sh
        
      - name: Run scan
        run: ./kubernetes-scripts/scan-container.sh default app-pod app-container profiles/container-baseline
```

2. Configure repository secrets for any credentials needed.

### Advanced GitHub Actions Integration

For more advanced use cases, create a comprehensive workflow:

```yaml
# .github/workflows/advanced-container-scan.yml
name: Advanced Container Security Scan
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * *'  # Daily scan

jobs:
  prepare:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    steps:
      - uses: actions/checkout@v2
      
      - name: Set scan matrix
        id: set-matrix
        run: |
          echo "::set-output name=matrix::{\"container\":[\"app\",\"api\",\"worker\"],\"profile\":[\"container-baseline\",\"cis-kubernetes\"]}"
  
  scan:
    needs: prepare
    runs-on: ubuntu-latest
    strategy:
      matrix: ${{ fromJson(needs.prepare.outputs.matrix) }}
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Kubernetes
        uses: engineerd/setup-kind@v0.5.0
      
      - name: Build and deploy test containers
        run: |
          docker build -t ${{ matrix.container }}-image ./containers/${{ matrix.container }}
          kind load docker-image ${{ matrix.container }}-image
          kubectl apply -f ./kubernetes/deploy-${{ matrix.container }}.yaml
      
      - name: Deploy scanner
        run: ./kubernetes-scripts/setup-minikube.sh
      
      - name: Run scan
        run: ./kubernetes-scripts/scan-container.sh default ${{ matrix.container }}-pod ${{ matrix.container }} profiles/${{ matrix.profile }}
      
      - name: Process results
        run: |
          saf report -i results.json -o report.html
      
      - name: Upload scan results
        uses: actions/upload-artifact@v2
        with:
          name: scan-results-${{ matrix.container }}-${{ matrix.profile }}
          path: report.html
```

For more examples, see the [GitHub Workflow Examples](../../github-workflow-examples/index.md).

## GitLab CI Integration

### Basic GitLab CI Integration

1. Add the GitLab CI pipeline to your repository:

```yaml
# .gitlab-ci.yml
stages:
  - deploy
  - scan
  - report

deploy_scanner:
  stage: deploy
  script:
    - ./kubernetes-scripts/setup-minikube.sh

run_scan:
  stage: scan
  script:
    - ./kubernetes-scripts/scan-container.sh default app-pod app-container profiles/container-baseline

generate_report:
  stage: report
  script:
    - saf report -i results.json -o report.html
  artifacts:
    paths:
      - report.html
```

2. Configure CI/CD variables for any credentials needed.

### Advanced GitLab CI Integration

For more robust GitLab CI integration:

```yaml
# .gitlab-ci.yml
variables:
  KUBERNETES_VERSION: 1.23.5
  SCANNER_IMAGE: cinc/auditor:latest
  SAF_CLI_VERSION: 2.0.0

stages:
  - build
  - deploy
  - scan
  - report
  - cleanup

.kubernetes_template: &kubernetes_setup
  before_script:
    - apt-get update && apt-get install -y curl
    - curl -LO "https://dl.k8s.io/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl"
    - chmod +x kubectl && mv kubectl /usr/local/bin/
    - curl -Lo ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
    - chmod +x ./kind && mv ./kind /usr/local/bin/kind
    - kind create cluster --name scanner-cluster
    - kubectl cluster-info
    - kubectl get nodes

build_containers:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t app-image ./containers/app
    - docker build -t api-image ./containers/api
    - docker save app-image > app-image.tar
    - docker save api-image > api-image.tar
  artifacts:
    paths:
      - app-image.tar
      - api-image.tar

deploy_containers:
  stage: deploy
  <<: *kubernetes_setup
  script:
    - kind load image-archive app-image.tar
    - kind load image-archive api-image.tar
    - kubectl apply -f ./kubernetes/deployments/

deploy_scanner:
  stage: deploy
  <<: *kubernetes_setup
  script:
    - ./kubernetes-scripts/setup-minikube.sh
    - kubectl get pods -A

scan_job:
  stage: scan
  parallel:
    matrix:
      - CONTAINER: ["app", "api"]
        PROFILE: ["container-baseline", "cis-kubernetes"]
  script:
    - ./kubernetes-scripts/scan-container.sh default ${CONTAINER}-pod ${CONTAINER} profiles/${PROFILE}
    - mkdir -p ./results/${CONTAINER}/${PROFILE}
    - cp results.json ./results/${CONTAINER}/${PROFILE}/
  artifacts:
    paths:
      - ./results/

generate_reports:
  stage: report
  image: ruby:latest
  script:
    - gem install saf-cli -v ${SAF_CLI_VERSION}
    - mkdir -p ./reports
    - |
      for dir in ./results/*; do
        CONTAINER=$(basename $dir)
        for profile_dir in $dir/*; do
          PROFILE=$(basename $profile_dir)
          saf report -i $profile_dir/results.json -o ./reports/${CONTAINER}-${PROFILE}.html
        done
      done
  artifacts:
    paths:
      - ./reports/
    expire_in: 1 week

cleanup:
  stage: cleanup
  <<: *kubernetes_setup
  script:
    - kind delete cluster --name scanner-cluster
  when: always
```

For more examples, see the [GitLab Pipeline Examples](../../gitlab-pipeline-examples/index.md).

## Jenkins Integration

Add a Jenkinsfile to your repository:

```groovy
pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubernetes
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  - name: scanner
    image: cinc/auditor:latest
    command:
    - cat
    tty: true
"""
        }
    }
    
    stages {
        stage('Deploy Scanner') {
            steps {
                container('kubernetes') {
                    sh './kubernetes-scripts/setup-minikube.sh'
                }
            }
        }
        
        stage('Run Scan') {
            steps {
                container('scanner') {
                    sh './kubernetes-scripts/scan-container.sh default app-pod app-container profiles/container-baseline'
                }
            }
        }
        
        stage('Process Results') {
            steps {
                container('scanner') {
                    sh 'saf report -i results.json -o report.html'
                    archiveArtifacts artifacts: 'report.html', fingerprint: true
                }
            }
        }
    }
}
```

## CI/CD Integration Best Practices

1. **Automate Everything**:
   - Avoid manual steps in your scanning workflow
   - Parameterize configurations for flexibility

2. **Scan Early and Often**:
   - Integrate scanning in multiple pipeline stages
   - Scan both development and production images

3. **Manage Thresholds Appropriately**:
   - Use stricter thresholds for production-bound containers
   - Consider progressive thresholds for different environments

4. **Handle Results Properly**:
   - Archive scan results as pipeline artifacts
   - Integrate with security dashboards and notification systems

5. **Fail Builds Appropriately**:
   - Decide whether scans should be blocking or informational
   - Consider using warning thresholds vs. failure thresholds

## Integration with Kubernetes Controllers

For ongoing scanning in Kubernetes environments:

```yaml
# scan-cronjob.yaml
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: container-security-scan
spec:
  schedule: "0 */6 * * *"  # Every 6 hours
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: scanner-sa
          containers:
          - name: scanner
            image: cinc/auditor:latest
            command:
            - /bin/sh
            - -c
            - ./kubernetes-scripts/scan-container.sh default app-pod app-container profiles/container-baseline
          restartPolicy: OnFailure
```

## Related Topics

- [GitHub Workflow Examples](../../github-workflow-examples/index.md)
- [GitLab Pipeline Examples](../../gitlab-pipeline-examples/index.md)
- [Deployment Scenarios](scenarios/index.md)
- [Threshold Configuration](../../configuration/thresholds/index.md)
