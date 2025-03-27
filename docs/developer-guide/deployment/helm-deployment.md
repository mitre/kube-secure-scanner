# Helm Charts Deployment

This guide provides detailed instructions for deploying the Secure CINC Auditor Kubernetes Container Scanning solution using Helm charts.

## Overview

Helm-based deployment is ideal for:

- Production environments
- Automated deployments
- Integration with existing Kubernetes workflows
- Customized scanning configurations

Helm charts provide a standardized, repeatable way to deploy the scanner with various configurations.

## Available Helm Charts

The project includes several modular Helm charts:

- **scanner-infrastructure**: Base infrastructure including namespaces, service accounts, and RBAC
- **common-scanner**: Common components and configurations shared by all scanner types
- **standard-scanner**: Scanner for standard containers using the Kubernetes API approach
- **distroless-scanner**: Scanner for distroless containers using the debug container approach
- **sidecar-scanner**: Scanner using the sidecar container approach

## Basic Helm Deployment

For a simple deployment with default settings:

```bash
# Add Helm repository (if hosted externally)
helm repo add secure-scanner https://example.com/helm-charts/
helm repo update

# Install scanner infrastructure
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure

# Install the appropriate scanner based on your container types
helm install standard-scanner ./helm-charts/standard-scanner
```

## Customized Helm Deployment

For customized deployments, create a values file:

```bash
# Create custom values file
cat > custom-values.yaml << EOF
global:
  namespace: security-scanning
  serviceAccount:
    create: true
    name: restricted-scanner
  rbac:
    timeoutSeconds: 900
    podSelector:
      matchLabels:
        scan: enabled
EOF

# Install with custom values
helm install -f custom-values.yaml scanner-infrastructure ./helm-charts/scanner-infrastructure
```

### Common Customization Options

The following customization options are available for all charts:

- **Namespace Configuration**: Customize the namespace for scanner deployment
- **RBAC Settings**: Configure role-based access control rules
- **Service Account**: Configure service account settings
- **Resource Limits**: Set CPU and memory limits for scanner components
- **Scanning Parameters**: Configure scan frequency, timeouts, and targets

## Chart-Specific Configurations

### Scanner Infrastructure Chart

```yaml
# scanner-infrastructure values.yaml
global:
  namespace: scanner-system
  createNamespace: true

rbac:
  strategy: label-based  # or "namespace-based"
  timeoutSeconds: 600
  labelSelector:
    scan: enabled

serviceAccount:
  create: true
  name: scanner-sa
  annotations:
    custom.annotation: value
```

### Standard Scanner Chart

```yaml
# standard-scanner values.yaml
global:
  namespace: scanner-system

scanner:
  image:
    repository: cinc/auditor
    tag: latest
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi

profiles:
  - name: container-baseline
    path: profiles/container-baseline
  - name: kube-baseline
    path: profiles/kube-baseline

schedule: "0 0 * * *"  # Daily at midnight (cron format)
```

### Distroless Scanner Chart

```yaml
# distroless-scanner values.yaml
global:
  namespace: scanner-system

debugContainer:
  image:
    repository: busybox
    tag: latest
  command: ["/bin/sh"]
  
scanner:
  image:
    repository: cinc/auditor
    tag: latest
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 1Gi

profiles:
  - name: container-baseline
    path: profiles/container-baseline
```

## Production Deployment Recommendations

For production deployments, consider the following recommendations:

1. **Use Version Pinning**:

   ```yaml
   scanner:
     image:
       repository: cinc/auditor
       tag: 5.18.14  # Pin to specific version
   ```

2. **Configure Resource Limits**:

   ```yaml
   resources:
     requests:
       cpu: 500m
       memory: 512Mi
     limits:
       cpu: 2000m
       memory: 1Gi
   ```

3. **Enable Security Features**:

   ```yaml
   securityContext:
     runAsUser: 1000
     runAsGroup: 1000
     fsGroup: 1000
     runAsNonRoot: true
     readOnlyRootFilesystem: true
   ```

4. **Configure Persistent Storage**:

   ```yaml
   persistence:
     enabled: true
     storageClass: standard
     size: 10Gi
   ```

## Helm Deployment Workflow

The Helm-based deployment follows this general workflow:

1. **Planning**: Determine which charts and configurations you need
2. **Configuration**: Create custom values files for your environment
3. **Installation**: Install the charts using Helm
4. **Verification**: Verify the deployment is working correctly
5. **Maintenance**: Update values and upgrade charts as needed

## Upgrading Helm Deployments

To update an existing deployment:

```bash
# Update custom values file with new settings
nano custom-values.yaml

# Upgrade the deployment
helm upgrade -f custom-values.yaml scanner-infrastructure ./helm-charts/scanner-infrastructure
```

## Uninstalling Helm Deployments

To remove a deployment:

```bash
# Uninstall charts
helm uninstall standard-scanner
helm uninstall scanner-infrastructure

# Clean up persistent resources if needed
kubectl delete namespace scanner-system
```

## Advanced Helm Features

### Using Helm Dependencies

For complex deployments, you can use Helm dependencies:

```yaml
# Chart.yaml
dependencies:
  - name: scanner-infrastructure
    version: 1.0.0
    repository: https://example.com/helm-charts/
    condition: scanner-infrastructure.enabled
  - name: standard-scanner
    version: 1.0.0
    repository: https://example.com/helm-charts/
    condition: standard-scanner.enabled
```

### Using Helm Post-Render

For advanced customization, consider using post-render hooks:

```bash
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --post-renderer ./scripts/customize-yamls.sh
```

## Related Topics

- [Helm Charts Documentation](../../helm-charts/overview/index.md)
- [Deployment Scenarios](scenarios/index.md)
- [Advanced Deployment Topics](advanced-topics/index.md)
- [RBAC Configuration](../../rbac/index.md)
