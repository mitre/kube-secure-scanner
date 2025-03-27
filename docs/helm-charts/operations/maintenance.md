# Maintenance Procedures

!!! info "Directory Context"
    This document is part of the [Operations Directory](index.md). See the [Operations Directory Inventory](inventory.md) for related resources.

## Overview

This document outlines maintenance procedures for the Secure Kubernetes Container Scanning Helm charts. Regular maintenance is essential for keeping your scanning infrastructure secure, up-to-date, and running efficiently.

## Routine Maintenance Tasks

### 1. Helm Chart Updates

Regularly update Helm charts to get the latest features and security fixes:

```bash
# Update Helm repository
helm repo update

# Check for chart updates
helm list -A

# Update specific chart
helm upgrade standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --reuse-values
```

### 2. Scanner Image Updates

Keep scanner container images up to date:

```bash
# Update to latest CINC Auditor image
helm upgrade sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set scanner.image=chef/inspec:latest \
  --reuse-values
```

For debug containers:

```bash
# Update debug container image
helm upgrade distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set debugContainer.image=alpine:latest \
  --reuse-values
```

### 3. Compliance Profile Updates

Keep compliance profiles up to date:

```bash
# Update profiles in ConfigMap
kubectl create configmap inspec-profiles -n scanning-namespace \
  --from-file=./updated-profiles \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 4. RBAC Maintenance

Regularly review and update RBAC permissions:

```bash
# Check current RBAC configuration
kubectl get role scanner-role -n scanning-namespace -o yaml

# Update RBAC for new pod patterns
helm upgrade scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set targetNamespace=scanning-namespace \
  --set rbac.useLabelSelector=true \
  --set rbac.podSelectorLabels.app=target-app \
  --set rbac.podSelectorLabels.scannable=true \
  --reuse-values
```

### 5. Token Rotation

Regularly rotate service account tokens:

```bash
# Delete existing token secrets to force rotation
kubectl delete secrets -n scanning-namespace -l kubernetes.io/service-account.name=inspec-scanner

# Regenerate kubeconfig with fresh token
./kubernetes-scripts/generate-kubeconfig.sh scanning-namespace inspec-scanner ./kubeconfig.yaml
```

## Scheduled Maintenance Procedures

### Monthly Maintenance Checklist

Implement a monthly maintenance schedule:

```bash
#!/bin/bash
# monthly-maintenance.sh
NAMESPACE="scanning-namespace"

echo "Monthly Scanner Maintenance"
echo "=========================="

# 1. Update Helm charts
helm dependency update ./helm-charts/standard-scanner
helm upgrade standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=$NAMESPACE \
  --reuse-values

# 2. Update scanner images
kubectl set image deployment/scanner-deployment scanner=chef/inspec:latest -n $NAMESPACE

# 3. Update profiles
kubectl create configmap inspec-profiles -n $NAMESPACE \
  --from-file=./updated-profiles \
  --dry-run=client -o yaml | kubectl apply -f -

# 4. Review and update RBAC
kubectl get role scanner-role -n $NAMESPACE -o yaml

# 5. Rotate tokens
kubectl delete secrets -n $NAMESPACE -l kubernetes.io/service-account.name=inspec-scanner
./kubernetes-scripts/generate-kubeconfig.sh $NAMESPACE inspec-scanner ./kubeconfig.yaml

# 6. Verify scanner functionality
./kubernetes-scripts/scan-container.sh $NAMESPACE test-pod container-name ./profiles/container-baseline

echo "Maintenance complete!"
```

### Quarterly Security Review

Conduct quarterly security reviews:

```bash
#!/bin/bash
# quarterly-security-review.sh
NAMESPACE="scanning-namespace"

echo "Quarterly Security Review"
echo "========================="

# 1. Review RBAC permissions
kubectl get rolebinding -n $NAMESPACE -o json | jq '.items[] | select(.roleRef.name=="scanner-role")'

# 2. Check for unused permissions
kubectl auth can-i --list --as=system:serviceaccount:$NAMESPACE:inspec-scanner -n $NAMESPACE

# 3. Review network policies
kubectl get networkpolicy -n $NAMESPACE -o yaml

# 4. Audit scanner usage
kubectl logs -n $NAMESPACE deployment/scanner-deployment --since=90d | grep "Scan completed" | wc -l

# 5. Check for security updates
helm dependency update ./helm-charts/standard-scanner
helm diff upgrade standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=$NAMESPACE \
  --reuse-values

echo "Security review complete!"
```

## Version Upgrades

### Minor Version Upgrades

For minor version upgrades, a simple update is usually sufficient:

```bash
# Minor version upgrade
helm upgrade standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --reuse-values
```

### Major Version Upgrades

For major version upgrades, follow a more careful process:

```bash
# 1. Review release notes and changes

# 2. Backup existing configuration
helm get values standard-scanner > standard-scanner-values-backup.yaml

# 3. Test upgrade in a non-production environment
helm upgrade standard-scanner-test ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=test-namespace \
  -f standard-scanner-values-backup.yaml

# 4. Verify functionality in test environment
./kubernetes-scripts/scan-container.sh test-namespace test-pod container-name ./profiles/container-baseline

# 5. Schedule production upgrade during maintenance window
helm upgrade standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  -f standard-scanner-values-backup.yaml
```

## Monitoring and Logging

### Configure Monitoring

Set up monitoring for scanner components:

```yaml
# prometheus-servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: scanner-monitor
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: scanner
  namespaceSelector:
    matchNames:
      - scanning-namespace
  endpoints:
  - port: metrics
    interval: 30s
```

### Log Collection

Configure log collection for scanner components:

```yaml
# fluentd-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: logging
data:
  fluent.conf: |
    <match kubernetes.var.log.containers.scanner-**>
      @type elasticsearch
      host elasticsearch.logging
      port 9200
      logstash_format true
      logstash_prefix scanner
      <buffer>
        @type file
        path /var/log/fluentd-buffers/scanner
        flush_mode interval
        retry_type exponential_backoff
        flush_thread_count 2
        flush_interval 5s
      </buffer>
    </match>
```

## Backup and Recovery

### Backup Configurations

Regularly backup Helm chart configurations:

```bash
# Backup all Helm release configurations
mkdir -p helm-backups/$(date +%Y-%m-%d)
helm list -A -o json | jq -r '.[] | .name + " " + .namespace' | while read -r release namespace; do
  helm get values $release -n $namespace > helm-backups/$(date +%Y-%m-%d)/$release-$namespace.yaml
done
```

### Recovery Procedures

If you need to recover from a failure:

```bash
# Restore from backup
helm install standard-scanner ./helm-charts/standard-scanner \
  -f helm-backups/2025-03-24/standard-scanner-scanning-namespace.yaml
```

## Cleanup Procedures

### Resource Cleanup

Regularly clean up old scan results and temporary resources:

```bash
# Clean up old scan results
kubectl exec -n scanning-namespace scanner-pod -- find /results -type f -mtime +30 -delete

# Remove old kubeconfig files
find /path/to/kubeconfig-files -name "kubeconfig-*.yaml" -mtime +7 -delete

# Delete completed jobs
kubectl delete jobs -n scanning-namespace --field-selector status.successful=1
```

### Namespace Cleanup

Periodically review and clean up scanning namespaces:

```bash
# List all scanner namespaces
kubectl get ns -l purpose=scanning

# Clean up resources in a namespace
kubectl delete all -n old-scanning-namespace -l app.kubernetes.io/instance=scanner
```

## Retirement and Decommissioning

When retiring a scanner deployment:

```bash
# 1. Revoke tokens
kubectl delete secrets -n scanning-namespace -l kubernetes.io/service-account.name=inspec-scanner

# 2. Remove Helm releases
helm uninstall standard-scanner -n scanning-namespace
helm uninstall scanner-infrastructure -n scanning-namespace

# 3. Clean up any remaining resources
kubectl delete configmap -n scanning-namespace -l app.kubernetes.io/part-of=scanner
kubectl delete secret -n scanning-namespace -l app.kubernetes.io/part-of=scanner

# 4. Remove namespace if no longer needed
kubectl delete namespace scanning-namespace
```

## Related Documentation

- [Troubleshooting](troubleshooting.md)
- [Performance Optimization](performance.md)
- [Usage & Customization](../usage/index.md)
- [Security Considerations](../security/index.md)
