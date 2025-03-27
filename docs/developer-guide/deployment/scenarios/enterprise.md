# Enterprise Production Environment

This guide provides a detailed approach for deploying the Secure CINC Auditor Kubernetes Container Scanning solution in an enterprise production environment.

## Use Case

Large organizations with multiple Kubernetes clusters requiring robust security scanning of all containers.

## Recommended Approach

**Helm Charts Deployment** is the recommended approach for enterprise environments due to its flexibility, scalability, and integration capabilities.

## Key Requirements

- High availability
- Centralized reporting
- Integration with security monitoring systems
- Comprehensive scan coverage
- Role-based access control

## Deployment Steps

### 1. Deploy Scanner Infrastructure

First, deploy the base scanner infrastructure across all required namespaces:

```bash
# Deploy base infrastructure
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set global.enterprise=true \
  --set global.monitoring.enabled=true
```

### 2. Configure RBAC

Configure RBAC with appropriate restrictions for your enterprise environment:

```yaml
# custom-rbac-values.yaml
rbac:
  strategy: label-based
  timeoutSeconds: 900
  labelSelector:
    scan: enabled
  clusterRoles:
    create: true
    restrictive: true
```

Apply the RBAC configuration:

```bash
helm upgrade scanner-infrastructure ./helm-charts/scanner-infrastructure \
  -f custom-rbac-values.yaml
```

### 3. Deploy Scanners

Deploy the appropriate scanner types based on your container types:

```bash
# Deploy standard scanner for regular containers
helm install standard-scanner ./helm-charts/standard-scanner \
  --set scanSchedule="0 0 * * *" \
  --set notifications.slack.enabled=true

# Set up distroless scanner if needed
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set kubernetes.version=1.16+
```

### 4. Configure Monitoring and Alerting

Set up monitoring and alerting for your scanning infrastructure:

```yaml
# monitoring-values.yaml
monitoring:
  enabled: true
  prometheus:
    scrape: true
  grafana:
    dashboards: true
  alerts:
    critical:
      threshold: 75
      channels: ["security-team", "ops-team"]
    warning:
      threshold: 50
      channels: ["security-team"]
```

Apply the monitoring configuration:

```bash
helm upgrade standard-scanner ./helm-charts/standard-scanner \
  -f monitoring-values.yaml
```

## Enterprise-Specific Considerations

### High Availability

For high availability in enterprise environments:

```yaml
# ha-values.yaml
replicaCount: 3
podDisruptionBudget:
  enabled: true
  minAvailable: 2
antiAffinity:
  enabled: true
  type: hard  # Or soft for flexible scheduling
```

### Data Retention

Configure appropriate data retention policies:

```yaml
# retention-values.yaml
dataRetention:
  enabled: true
  scanResults:
    retentionDays: 90
  reports:
    retentionDays: 365
  archiving:
    enabled: true
    destination: "s3://security-archive/container-scans"
```

### Enterprise Integration

Configure integration with enterprise security systems:

```yaml
# integration-values.yaml
integration:
  siem:
    enabled: true
    type: splunk  # or elasticsearch, etc.
    endpoint: "https://splunk.example.com:8088"
    token: "${SPLUNK_TOKEN}"
  ticketing:
    enabled: true
    type: jira
    endpoint: "https://jira.example.com/api"
    credentials:
      secretName: jira-credentials
  compliance:
    enabled: true
    reports:
      schedule: "0 0 * * 0"  # Weekly on Sundays
      formats: ["html", "pdf", "csv"]
```

## Validation and Testing

After deployment, validate your enterprise setup:

1. Verify scanner deployment across all namespaces:

   ```bash
   kubectl get pods -n scanner-system
   kubectl get pods -A -l app=scanner
   ```

2. Test scanning functionality:

   ```bash
   # Run a test scan
   ./kubernetes-scripts/scan-container.sh default test-pod test-container profiles/enterprise-baseline
   ```

3. Verify monitoring integration:

   ```bash
   # Check Prometheus targets
   kubectl port-forward svc/prometheus-server 9090:9090 -n monitoring
   # Open http://localhost:9090/targets in your browser
   ```

4. Test alerting:

   ```bash
   # Trigger a test alert
   kubectl annotate pod test-pod security.scan/test-alert=true
   ```

## Related Topics

- [Helm Deployment](../helm-deployment.md)
- [Advanced Deployment Topics](../advanced-topics/index.md)
- [Multi-Tenant Environment](multi-tenant.md)
- [Security Considerations](../../../security/index.md)
