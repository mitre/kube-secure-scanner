# GitLab CI/CD Integration

This guide explains how to integrate secure container scanning using CINC Auditor with the train-k8s-container plugin into GitLab CI/CD pipelines.

> **Strategic Priority**: We strongly recommend the Kubernetes API Approach using the train-k8s-container plugin for enterprise-grade container scanning. Our highest priority is enhancing this plugin to support distroless containers. See [Approach Comparison](../../approaches/comparison.md) and [Security Compliance](../../security/compliance/index.md) for more details.

## Overview

The integration handles these key steps:

1. Creating a container to scan in Kubernetes
2. Generating dynamic, restricted access to that container
3. Running CINC Auditor with the train-k8s-container transport
4. Using MITRE SAF-CLI for results processing and quality gates
5. Cleaning up temporary resources

## Prerequisites

### GitLab Runner Setup

1. A GitLab Runner with access to your Kubernetes cluster
2. The runner needs:
   - kubectl installed
   - Access to the cluster (kubeconfig)
   - Permissions to create service accounts and roles
   - Node.js installed (for SAF-CLI)

### Kubernetes Requirements

1. A namespace for the scanner infrastructure
2. Permission to create and manage:
   - Pods
   - Service accounts
   - Roles and RoleBindings

## Configuration

### GitLab CI Variables

Set up these CI/CD variables in GitLab:

- `KUBE_CONFIG`: Base64-encoded kubeconfig with permissions to manage RBAC
- `SCANNER_NAMESPACE`: The namespace for scanner resources
- `CINC_PROFILE_PATH`: Path to the CINC Auditor profile to run
- `THRESHOLD_VALUE`: Minimum passing score (0-100) for security scans

### .gitlab-ci.yml Example with SAF-CLI

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
      # Generate token
      TOKEN=$(kubectl create token scanner-sa-${CI_PIPELINE_ID} \
        -n ${SCANNER_NAMESPACE} --duration=30m)
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
      # Create a kubeconfig file
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

## Using the SAF-CLI in Your Pipeline

The MITRE SAF-CLI provides powerful capabilities for security scan results:

### Installation

```yaml
# Install SAF-CLI
npm install -g @mitre/saf
```

### Generate Summaries

```yaml
# Create a markdown summary
saf summary --input scan-results.json --output-md scan-summary.md

# Create a JSON summary
saf summary --input scan-results.json --output scan-summary.json
```

### Threshold Quality Gates

```yaml
# Check against a threshold (exits with non-zero if below threshold)
saf threshold -i scan-results.json -t 70

# More advanced threshold options
saf threshold -i scan-results.json -t 70 --failed-critical 0 --failed-high 2
```

### Visualization and Reports

```yaml
# Generate a standalone HTML report
saf view -i scan-results.json --output report.html
```

## Security Enhancements

### Pipeline-Specific Token Durations

Adjust token durations based on scan complexity:

```yaml
# For simple scans
TOKEN=$(kubectl create token scanner-sa-${CI_PIPELINE_ID} -n ${SCANNER_NAMESPACE} --duration=15m)

# For complex scans
TOKEN=$(kubectl create token scanner-sa-${CI_PIPELINE_ID} -n ${SCANNER_NAMESPACE} --duration=60m)
```

### Pipeline-Specific Namespaces

For stricter isolation, create a dedicated namespace per pipeline:

```yaml
deploy_container:
  script:
    - |
      # Create namespace with unique name
      kubectl create namespace ${SCANNER_NAMESPACE}-${CI_PIPELINE_ID}
      
      # Set variable for other stages
      echo "PIPELINE_NAMESPACE=${SCANNER_NAMESPACE}-${CI_PIPELINE_ID}" >> deploy.env
      
      # Create pod in isolated namespace
      # ...

cleanup:
  script:
    - |
      # Delete entire namespace
      kubectl delete namespace ${PIPELINE_NAMESPACE}
```

## Implementing Quality Gates

You can configure the pipeline to fail based on scan results:

```yaml
run_scan:
  script:
    # ... run scan ...
    
    # Threshold check
    saf threshold -i scan-results.json -t ${THRESHOLD_VALUE}
    THRESHOLD_RESULT=$?
    
    # Fail the pipeline if below threshold
    exit ${THRESHOLD_RESULT}
```

For more advanced quality gates:

```yaml
# Zero critical failures, at most 2 high failures, overall score of 70%
saf threshold -i scan-results.json -t 70 --failed-critical 0 --failed-high 2
```

## Troubleshooting

### Common Issues

1. **SAF-CLI installation fails**: Make sure Node.js is installed correctly on your runner
2. **Token expiration**: If scans take longer than expected, increase the token duration
3. **Threshold failures**: Adjust threshold values or temporarily disable enforcement during initial implementation

### Debugging

Add these steps to your pipeline for better visibility:

```yaml
# Display SAF-CLI version
saf --version

# Debug specific controls that are failing
jq '.profiles[0].controls[] | select(.status=="failed") | {id, title, status}' scan-results.json

# Examine compliance score
jq '.profiles[0].statistics.percent_passed' scan-results.json
```

## Security Dashboard Integration {#security-dashboard-integration}

GitLab provides built-in security dashboard capabilities that can be integrated with CINC Auditor scan results:

### Converting Scan Results for GitLab Security Dashboard

1. Create a converter script to transform CINC results into GitLab Security Report format:

```yaml
convert_results:
  stage: report
  needs: [run_scan]
  script:
    - |
      # Install jq for JSON processing
      apt-get update && apt-get install -y jq
      
      # Convert CINC report to GitLab security report format
      jq -r '
        {
          "version": "2.0",
          "vulnerabilities": [
            .profiles[0].controls[] | 
            select(.status=="failed") | 
            {
              "id": .id,
              "category": "container_scanning",
              "name": .title,
              "message": .desc,
              "description": .desc,
              "severity": (
                if .impact >= 0.7 then "Critical" 
                elif .impact >= 0.4 then "High"
                elif .impact >= 0.2 then "Medium"
                else "Low" end
              ),
              "solution": .refs[0].url,
              "scanner": {
                "id": "cinc_auditor",
                "name": "CINC Auditor"
              },
              "location": {
                "image": env.TARGET_IMAGE,
                "operating_system": "Linux",
                "dependency": {
                  "package": {}
                }
              },
              "identifiers": [
                {
                  "type": "cinc_control",
                  "name": .id,
                  "value": .id
                }
              ]
            }
          ],
          "scan": {
            "scanner": {
              "id": "cinc_auditor",
              "name": "CINC Auditor",
              "version": "5.0.0",
              "vendor": {
                "name": "CINC Project"
              }
            },
            "analyzer": {
              "id": "container_scanning",
              "name": "Container Scanning",
              "version": "1.0",
              "vendor": {
                "name": "GitLab"
              }
            },
            "type": "container_scanning",
            "start_time": "",
            "end_time": "",
            "status": "success"
          }
        }
      ' scan-results.json > gl-container-scanning-report.json
  artifacts:
    reports:
      container_scanning: gl-container-scanning-report.json
```

### Using GitLab Security Dashboards

Once you have converted the reports, they will be automatically integrated into GitLab's security features:

1. The Security Dashboard in the Security section of your project
2. The Security tab in Merge Requests
3. The Vulnerability Report for tracking security issues

### Compliance Reports

For compliance focused reports, you can also configure the pipeline to generate:

```yaml
compliance_report:
  stage: report
  needs: [run_scan]
  script:
    - |
      # Generate compliance summary report
      saf compliance-overview -i scan-results.json -o gl-compliance-report.json
      
      # Display summary in job
      cat gl-compliance-report.json | jq .
  artifacts:
    paths:
      - gl-compliance-report.json
    reports:
      compliance_report:
        report_format: json
        report_type: sast
        report_path: gl-compliance-report.json
```

## Related Integration Resources

- [Standard Container Workflow Integration](../workflows/standard-container.md)
- [Distroless Container Workflow Integration](../workflows/distroless-container.md)
- [Sidecar Container Workflow Integration](../workflows/sidecar-container.md)
- [GitLab Examples](../examples/gitlab-examples.md)
- [GitLab Services Integration](gitlab-services.md)
- [Integration Configuration](../configuration/index.md)
