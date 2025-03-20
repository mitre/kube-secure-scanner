# Deployment Scenarios

This document provides guidance on deploying the Secure CINC Auditor Kubernetes Container Scanning solution in various environments, from development to production.

## Overview

The container scanning solution can be deployed in several ways:

1. **Script-based Deployment**: Using helper scripts for direct deployment
2. **Helm Charts Deployment**: Using modular Helm charts for production deployment
3. **CI/CD Pipeline Integration**: Integrating scanning into existing CI/CD workflows

Each deployment method has its own advantages and is suitable for different scenarios.

## Deployment Prerequisites

Before deploying, ensure you have:

1. **Kubernetes Cluster Requirements**:
   - Kubernetes 1.16+ (for all features including ephemeral containers)
   - RBAC enabled
   - Service account support

2. **Tool Requirements**:
   - kubectl with cluster access
   - Helm 3+ (for Helm-based deployment)
   - CINC Auditor/InSpec
   - SAF CLI (for threshold validation)

3. **Access Requirements**:
   - Permissions to create namespaces, service accounts, and roles
   - Permissions to create and manage pods

## Script-based Deployment

Ideal for: Development, testing, and one-off scanning operations

### Local Development Environment

```bash
# Set up minikube for development
./scripts/setup-minikube.sh

# Run a scan against a specific container
./scripts/scan-container.sh namespace-name pod-name container-name
```

### Production Environment

```bash
# Configure access to production cluster
export KUBECONFIG=/path/to/production/kubeconfig

# Create restricted service account and role
kubectl apply -f kubernetes/templates/namespace.yaml
kubectl apply -f kubernetes/templates/service-account.yaml
kubectl apply -f kubernetes/templates/rbac.yaml

# Run scan with production settings
./scripts/scan-container.sh namespace-name pod-name container-name --production-mode
```

## Helm Charts Deployment

Ideal for: Production environments, automated deployments, and integration with existing Kubernetes workflows

### Basic Helm Deployment

```bash
# Add Helm repository (if hosted externally)
helm repo add secure-scanner https://example.com/helm-charts/
helm repo update

# Install scanner infrastructure
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure

# Install the appropriate scanner based on your container types
helm install standard-scanner ./helm-charts/standard-scanner
```

### Customized Helm Deployment

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

## CI/CD Pipeline Integration Deployment

Ideal for: Automated scanning in CI/CD workflows, DevSecOps pipelines

### GitHub Actions Deployment

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
           run: ./scripts/setup-minikube.sh
         - name: Run scan
           run: ./scripts/scan-container.sh default app-pod app-container
   ```

2. Configure repository secrets for any credentials needed.

### GitLab CI Deployment

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
       - ./scripts/setup-minikube.sh
   
   run_scan:
     stage: scan
     script:
       - ./scripts/scan-container.sh default app-pod app-container
   
   generate_report:
     stage: report
     script:
       - saf report -i results.json -o report.html
     artifacts:
       paths:
         - report.html
   ```

2. Configure CI/CD variables for any credentials needed.

## Deployment Scenarios

### Scenario 1: Enterprise Production Environment

**Recommended Approach**: Helm Charts Deployment

**Setup**:
1. Deploy scanner infrastructure across all required namespaces
2. Configure RBAC with appropriate restrictions
3. Set up automated scanning for critical namespaces
4. Integrate with central compliance monitoring

```bash
# Deploy base infrastructure
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set global.enterprise=true \
  --set global.monitoring.enabled=true

# Deploy scanners with appropriate configurations
helm install standard-scanner ./helm-charts/standard-scanner \
  --set scanSchedule="0 0 * * *" \
  --set notifications.slack.enabled=true

# Set up distroless scanner if needed
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set kubernetes.version=1.16+
```

### Scenario 2: Development Environment

**Recommended Approach**: Script-based Deployment

**Setup**:
1. Use the setup script to configure a local environment
2. Run scans on demand during development
3. Use direct commands for rapid iteration

```bash
# Set up development environment
./scripts/setup-minikube.sh --dev-mode

# Run scan during development
./scripts/scan-container.sh default app-pod app-container
```

### Scenario 3: CI/CD Pipeline Environment

**Recommended Approach**: CI/CD Pipeline Integration

**Setup**:
1. Integrate scanning into existing CI/CD pipelines
2. Configure threshold validation for pass/fail decisions
3. Generate and archive scan reports

For detailed examples, see the [CI/CD Integration](../integration/overview.md) documentation.

### Scenario 4: Multi-Tenant Kubernetes Environment

**Recommended Approach**: Helm Charts with Label-based RBAC

**Setup**:
1. Deploy scanner infrastructure with label-based RBAC
2. Configure namespaced service accounts
3. Implement strict time-bound token validation

```bash
# Deploy with label-based RBAC
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set rbac.strategy=label-based \
  --set rbac.labelSelector=scan=enabled
```

## Scaling Considerations

For environments with a large number of containers to scan:

1. **Parallel Scanning**:
   - Configure multiple scanner deployments
   - Use job queues for coordinating scans

2. **Resource Allocation**:
   - Allocate appropriate CPU and memory resources
   - Configure resource requests and limits

3. **Result Storage**:
   - Implement centralized result storage
   - Configure automatic cleanup of old results

## Security Considerations

When deploying in production:

1. **RBAC Restrictions**:
   - Use the most restrictive permissions possible
   - Implement time-bound tokens
   - Consider label-based targeting for multi-tenant environments

2. **Scanner Isolation**:
   - Run scanners in dedicated namespaces
   - Implement network policies to restrict scanner communications
   - Use non-privileged containers where possible

3. **Sensitive Data Handling**:
   - Ensure scan results are securely stored
   - Implement access controls for viewing results
   - Consider data retention policies

## Monitoring and Maintenance

For long-term deployment:

1. **Health Monitoring**:
   - Set up liveness and readiness probes
   - Monitor scanner resource usage
   - Configure alerts for scanner failures

2. **Version Updates**:
   - Plan for regular updates of scanner components
   - Test updates in a staging environment before production
   - Maintain version compatibility

3. **Backup and Recovery**:
   - Back up critical scanner configurations
   - Document recovery procedures
   - Test restoration processes

## Advanced Deployment Options

### Air-Gapped Environments

For environments without internet access:

1. Download and package all required container images
2. Prepare an internal registry for hosting images
3. Configure Helm charts and scripts to use internal resources

### High-Security Environments

For environments with strict security requirements:

1. Implement additional security controls
2. Use Mutual TLS for all communications
3. Configure audit logging for all scanner actions

## Deployment Verification

After deployment, verify the setup:

1. **Functionality Check**:
   ```bash
   # Run a test scan
   ./scripts/scan-container.sh default test-pod test-container
   ```

2. **Security Verification**:
   - Confirm RBAC restrictions are working
   - Verify token timeout functionality
   - Check proper cleanup of resources

3. **Integration Testing**:
   - Verify integration with monitoring systems
   - Test threshold validation
   - Confirm report generation and distribution

## Additional Resources

- [Helm Charts Documentation](../helm-charts/overview.md)
- [RBAC Configuration](../rbac/README.md)
- [Service Account Setup](../service-accounts/README.md)
- [Threshold Configuration](../thresholds.md)
- [Integration Options](../integration/overview.md)