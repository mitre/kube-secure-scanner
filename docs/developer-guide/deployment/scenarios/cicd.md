# CI/CD Pipeline Environment

This guide provides a detailed approach for integrating the Secure CINC Auditor Kubernetes Container Scanning solution into CI/CD pipelines.

## Use Case

Automated container scanning as part of CI/CD pipelines to enforce security policies before deployment.

## Recommended Approach

**CI/CD Pipeline Integration** is the recommended approach for automated security scanning in deployment pipelines.

## Key Requirements

- Automated execution
- Pass/fail criteria
- Artifact generation
- Integration with CI/CD tools

## GitHub Actions Integration

### Basic GitHub Actions Workflow

Create a GitHub Actions workflow file to scan containers:

```yaml
# .github/workflows/container-scan.yml
name: Container Security Scan
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Kubernetes
        uses: engineerd/setup-kind@v0.5.0
      
      - name: Deploy scanner
        run: ./kubernetes-scripts/setup-minikube.sh
      
      - name: Build container
        run: |
          docker build -t test-app:${{ github.sha }} .
          kind load docker-image test-app:${{ github.sha }}
          kubectl apply -f kubernetes/deploy-test-app.yaml
      
      - name: Run scan
        run: |
          ./kubernetes-scripts/scan-container.sh default test-app test-container profiles/ci-baseline
      
      - name: Validate against thresholds
        run: |
          saf validate -i results.json -f thresholds/ci-thresholds.yml
```

### Advanced GitHub Actions Workflow

For more complex scenarios, use matrix builds to scan multiple containers:

```yaml
# .github/workflows/advanced-scan.yml
name: Advanced Container Security Scan
on:
  push:
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
      
      - name: Run scan
        run: ./kubernetes-scripts/scan-container.sh default ${{ matrix.container }}-pod ${{ matrix.container }} profiles/${{ matrix.profile }}
      
      - name: Process results
        run: |
          saf report -i results.json -o report-${{ matrix.container }}-${{ matrix.profile }}.html
      
      - name: Upload scan results
        uses: actions/upload-artifact@v2
        with:
          name: scan-results-${{ matrix.container }}-${{ matrix.profile }}
          path: report-${{ matrix.container }}-${{ matrix.profile }}.html
```

## GitLab CI Integration

### Basic GitLab CI Pipeline

Create a GitLab CI pipeline file for container scanning:

```yaml
# .gitlab-ci.yml
stages:
  - build
  - deploy
  - scan
  - validate

build_container:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA

deploy_to_test:
  stage: deploy
  script:
    - kubectl apply -f <(sed "s/IMAGE_TAG/$CI_COMMIT_SHORT_SHA/g" kubernetes/deploy-test-app.yaml)

scan_container:
  stage: scan
  script:
    - ./kubernetes-scripts/scan-container.sh default test-app test-container profiles/ci-baseline

validate_results:
  stage: validate
  script:
    - saf validate -i results.json -f thresholds/ci-thresholds.yml
  artifacts:
    paths:
      - results.json
    when: always
```

### Advanced GitLab CI Pipeline

For more comprehensive scanning in GitLab:

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

## CI/CD-Specific Considerations

### Thresholds for Automated Pipelines

Create threshold files for pass/fail criteria:

```yaml
# thresholds/ci-thresholds.yml
failure:
  critical: 1   # Fail on any critical findings
  high: 5       # Allow up to 5 high findings
warning:
  critical: 0   # Warn on any critical findings
  high: 1       # Warn on any high findings
  medium: 10    # Warn if more than 10 medium findings
```

### Integration with Security Gates

Configure security gates in your CI/CD pipeline:

```yaml
# Example security gate configuration
security_gate:
  stage: verify
  script:
    - |
      if [ -f security-gate-failed ]; then
        echo "Security gate failed - critical vulnerabilities found"
        cat security-findings.txt
        exit 1
      fi
  allow_failure:
    exit_codes: 1
```

### Notifications for Security Issues

Set up notifications for security findings:

```yaml
# Example notification configuration
notify_security_team:
  stage: notify
  script:
    - |
      if [ -f security-findings.txt ]; then
        curl -X POST -H "Content-Type: application/json" \
          -d "{\"text\":\"Security issues found in build $CI_PIPELINE_ID\"}" \
          ${SLACK_WEBHOOK_URL}
      fi
  when: always
```

## Best Practices for CI/CD Integration

1. **Define clear thresholds**:
   - Establish appropriate thresholds based on your security policies
   - Consider different thresholds for different environments (dev/staging/prod)

2. **Store scan artifacts**:
   - Preserve scan results for future reference
   - Link results to specific build artifacts

3. **Implement graduated enforcement**:
   - Start with warnings-only mode to avoid blocking pipelines
   - Gradually increase enforcement as teams address findings

4. **Ensure good reporting**:
   - Generate comprehensive reports with actionable items
   - Make reports easily accessible to development teams

5. **Optimize for performance**:
   - Use caching where possible
   - Parallelize scanning for multiple containers
   - Consider scanning only changed components

## Related Topics

- [CI/CD Integration Guide](../cicd-deployment.md)
- [GitHub Workflow Examples](../../../github-workflow-examples/index.md)
- [GitLab Pipeline Examples](../../../gitlab-pipeline-examples/index.md)
- [Threshold Configuration](../../../configuration/thresholds/index.md)
