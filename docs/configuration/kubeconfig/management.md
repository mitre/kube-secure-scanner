# Kubeconfig Management

This document covers best practices for managing kubeconfig files across different environments and scenarios.

## Basic Management Principles

Follow these core principles when managing kubeconfig files:

1. **Isolation**: Use separate kubeconfig files for different environments
2. **Least Privilege**: Configure each kubeconfig with minimal required permissions
3. **Expiration**: Use short-lived tokens and rotate them regularly
4. **Security**: Apply proper file permissions and secure storage
5. **Automation**: Automate kubeconfig generation where possible

## File Organization

Organize kubeconfig files sensibly:

```
/secure-configs/
  ├── dev/
  │   ├── kubeconfig-team1.yaml
  │   └── kubeconfig-team2.yaml
  ├── staging/
  │   ├── kubeconfig-team1.yaml
  │   └── kubeconfig-team2.yaml
  └── prod/
      ├── kubeconfig-teamA.yaml
      └── kubeconfig-teamB.yaml
```

Ensure proper permissions on all files and directories:

```bash
chmod -R 700 /secure-configs
find /secure-configs -type f -name "*.yaml" -exec chmod 600 {} \;
```

## Multiple Environments

Manage configurations for different environments:

```bash
# Development
./generate-kubeconfig.sh dev-namespace inspec-scanner-dev ./kubeconfig-dev.yaml

# Staging
./generate-kubeconfig.sh staging-namespace inspec-scanner-staging ./kubeconfig-staging.yaml

# Production
./generate-kubeconfig.sh prod-namespace inspec-scanner-prod ./kubeconfig-prod.yaml
```

Use naming conventions that clearly indicate the environment to prevent confusion.

## Using Environment Variables

Set the `KUBECONFIG` environment variable to specify which configuration file to use:

```bash
# Use development configuration
export KUBECONFIG=/secure-configs/dev/kubeconfig-team1.yaml
cinc-auditor exec profile -t k8s-container://dev-namespace/pod/container

# Use production configuration
export KUBECONFIG=/secure-configs/prod/kubeconfig-teamA.yaml
cinc-auditor exec profile -t k8s-container://prod-namespace/pod/container
```

## Merging Kubeconfig Files

You can merge multiple kubeconfig files when needed:

```bash
KUBECONFIG=config1.yaml:config2.yaml:config3.yaml kubectl config view --flatten > merged-config.yaml
```

This creates a single file with all contexts, which can be useful for managing multiple clusters.

## CI/CD Pipeline Management

For CI/CD pipelines, manage kubeconfig files carefully:

### GitHub Actions Example

```yaml
name: Scan Container

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to scan (dev/staging/prod)'
        required: true
        default: 'dev'

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      # Set up the appropriate kubeconfig based on environment
      - name: Configure Kubernetes
        run: |
          mkdir -p $HOME/.kube
          if [ "${{ github.event.inputs.environment }}" == "prod" ]; then
            echo "$PROD_KUBECONFIG" > $HOME/.kube/config
          elif [ "${{ github.event.inputs.environment }}" == "staging" ]; then
            echo "$STAGING_KUBECONFIG" > $HOME/.kube/config
          else
            echo "$DEV_KUBECONFIG" > $HOME/.kube/config
          fi
          chmod 600 $HOME/.kube/config
        env:
          DEV_KUBECONFIG: ${{ secrets.DEV_KUBECONFIG }}
          STAGING_KUBECONFIG: ${{ secrets.STAGING_KUBECONFIG }}
          PROD_KUBECONFIG: ${{ secrets.PROD_KUBECONFIG }}
```

### GitLab CI Example

```yaml
scan_job:
  stage: scan
  script:
    - mkdir -p $HOME/.kube
    - |
      if [ "$CI_ENVIRONMENT_NAME" == "production" ]; then
        echo "$PROD_KUBECONFIG" > $HOME/.kube/config
      elif [ "$CI_ENVIRONMENT_NAME" == "staging" ]; then
        echo "$STAGING_KUBECONFIG" > $HOME/.kube/config
      else
        echo "$DEV_KUBECONFIG" > $HOME/.kube/config
      fi
    - chmod 600 $HOME/.kube/config
    - cinc-auditor exec profile -t k8s-container://$NAMESPACE/$POD_NAME/$CONTAINER_NAME
  variables:
    NAMESPACE: inspec-test
  environment:
    name: $CI_ENVIRONMENT_NAME
```

## Token Rotation

Implement regular token rotation for better security:

```bash
#!/bin/bash
# rotate-kubeconfig.sh
NAMESPACE=$1
SA_NAME=$2
CONFIG_FILE=$3

# Backup existing config
if [ -f "$CONFIG_FILE" ]; then
  cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
fi

# Generate new config with fresh token
./generate-kubeconfig.sh "$NAMESPACE" "$SA_NAME" "$CONFIG_FILE"

echo "Rotated kubeconfig for $SA_NAME in $NAMESPACE"
```

Schedule this script to run regularly via cron or CI/CD pipelines.

## Related Topics

- [Kubeconfig Generation](generation.md)
- [Security Considerations](security.md)
- [Dynamic Configuration](dynamic.md)
- [RBAC Configuration](../../rbac/index.md)
- [Service Accounts](../../service-accounts/index.md)
