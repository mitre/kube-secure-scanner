# Dynamic Kubeconfig Generation

This document covers methods for dynamically generating kubeconfig files in CI/CD pipelines and automated environments.

## Script-Based Generation

For CI/CD pipelines, you can generate configurations dynamically using a script:

```bash
#!/bin/bash
# generate-kubeconfig.sh
NAMESPACE=$1
SA_NAME=$2
OUTPUT_FILE=${3:-"./kubeconfig.yaml"}

# Get cluster information
SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')

# Create token
TOKEN=$(kubectl create token ${SA_NAME} -n ${NAMESPACE})

# Generate kubeconfig
cat > ${OUTPUT_FILE} << EOF
apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    server: ${SERVER}
    certificate-authority-data: ${CA_DATA}
  name: scanner-cluster
contexts:
- context:
    cluster: scanner-cluster
    namespace: ${NAMESPACE}
    user: ${SA_NAME}
  name: scanner-context
current-context: scanner-context
users:
- name: ${SA_NAME}
  user:
    token: ${TOKEN}
EOF

echo "Generated kubeconfig at ${OUTPUT_FILE}"
```

Usage:

```bash
./generate-kubeconfig.sh inspec-test inspec-scanner ./my-kubeconfig.yaml
```

## GitHub Actions Integration

For GitHub Actions, you can include dynamic kubeconfig generation in your workflow:

```yaml
name: Kubernetes Scanner

on:
  push:
    branches: [ main ]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Kubernetes
        uses: azure/k8s-set-context@v3
        with:
          kubeconfig: ${{ secrets.KUBECONFIG }}
      
      - name: Generate scanning kubeconfig
        run: |
          # Create service account if it doesn't exist
          kubectl get sa inspec-scanner -n inspec-test || \
            kubectl create sa inspec-scanner -n inspec-test
          
          # Generate kubeconfig for scanner
          ./kubernetes-scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./scanner-kubeconfig.yaml
          
          # Run scan with generated kubeconfig
          KUBECONFIG=./scanner-kubeconfig.yaml cinc-auditor exec profile -t k8s-container://inspec-test/target-pod/container
```

## GitLab CI Integration

For GitLab CI, you can integrate dynamic kubeconfig generation:

```yaml
stages:
  - scan

container-scan:
  stage: scan
  image: registry.gitlab.com/my-org/container-scanner:latest
  script:
    - |
      # Generate kubeconfig
      ./kubernetes-scripts/generate-kubeconfig.sh $NAMESPACE $SERVICE_ACCOUNT ./scanner-kubeconfig.yaml
      
      # Run scan with generated kubeconfig
      KUBECONFIG=./scanner-kubeconfig.yaml cinc-auditor exec $PROFILE_PATH \
        -t k8s-container://$NAMESPACE/$POD_NAME/$CONTAINER_NAME \
        --reporter json:scan-results.json
  variables:
    NAMESPACE: inspec-test
    SERVICE_ACCOUNT: inspec-scanner
    POD_NAME: target-pod
    CONTAINER_NAME: container
    PROFILE_PATH: profiles/container-baseline
```

## Token Expiration

When generating kubeconfig files dynamically, be aware of token expiration:

```bash
# Create a kubeconfig with a short-lived token (5 minutes)
TOKEN=$(kubectl create token inspec-scanner -n inspec-test --duration=5m)
# ... create kubeconfig ...

# After token expiration, kubeconfig must be regenerated
```

For CI/CD pipelines, you should ensure the token duration is appropriate for your job's expected execution time.

## Multiple Environments

Dynamic generation allows easy configuration for different environments:

```bash
# Development
./generate-kubeconfig.sh dev-namespace inspec-scanner ./kubeconfig-dev.yaml

# Staging
./generate-kubeconfig.sh staging-namespace inspec-scanner ./kubeconfig-staging.yaml

# Production
./generate-kubeconfig.sh prod-namespace inspec-scanner ./kubeconfig-prod.yaml
```

This approach is particularly useful for automated scanning across multiple environments.

## Related Topics

- [Kubeconfig Generation](generation.md)
- [Kubeconfig Management](management.md)
- [Security Considerations](security.md)
- [GitHub Actions Integration](../../integration/platforms/github-actions.md)
- [GitLab CI Integration](../../integration/platforms/gitlab-ci.md)
