# Multi-Tenant Kubernetes Environment

This guide provides a detailed approach for deploying the Secure CINC Auditor Kubernetes Container Scanning solution in a multi-tenant Kubernetes environment.

## Use Case

Shared Kubernetes cluster with multiple teams or applications requiring secure container scanning with strong isolation between tenants.

## Recommended Approach

**Helm Charts with Label-based RBAC** is the recommended approach for multi-tenant environments.

## Key Requirements

- Strong isolation between tenants
- Granular access controls
- Tenant-specific configurations
- Centralized management

## Deployment Steps

### 1. Deploy Infrastructure with Label-based RBAC

First, deploy the scanner infrastructure with label-based RBAC:

```bash
# Deploy with label-based RBAC
helm install scanner-infrastructure ./helm-charts/scanner-infrastructure \
  --set rbac.strategy=label-based \
  --set rbac.labelSelector=scan=enabled
```

The label-based approach ensures:

- Only containers with specific labels are scanned
- Access permissions are strictly limited to labeled resources
- Different teams can manage their own scanned resources

### 2. Configure Namespaced Service Accounts

Configure separate service accounts for each tenant namespace:

```yaml
# tenant-values.yaml
serviceAccounts:
  perNamespace: true
  namespaces:
    - name: team-a
      labels:
        team: a
        scan: enabled
    - name: team-b
      labels:
        team: b
        scan: enabled
```

Apply the configuration:

```bash
helm upgrade scanner-infrastructure ./helm-charts/scanner-infrastructure \
  -f tenant-values.yaml
```

### 3. Implement Strict Security Controls

Add time-bound token validation and additional security measures:

```yaml
# security-values.yaml
security:
  tokenTimeout: 300  # 5 minutes
  requireAnnotations: true
  auditEvents: true
```

Apply the security controls:

```bash
helm upgrade scanner-infrastructure ./helm-charts/scanner-infrastructure \
  -f security-values.yaml
```

### 4. Configure Tenant-Specific Scanners

Deploy separate scanner instances for each tenant:

```bash
# Deploy tenant-specific scanners
for team in team-a team-b team-c; do
  helm install $team-scanner ./helm-charts/standard-scanner \
    --set global.namespace=$team \
    --set scanner.serviceAccount=$team-scanner-sa \
    --set profiles.configMap=$team-profiles
done
```

## Multi-Tenant-Specific Considerations

### Tenant Isolation

Enhance tenant isolation with network policies:

```yaml
# network-policy-values.yaml
networkPolicies:
  enabled: true
  defaultDeny: true
  allowedNamespaces:
    - team-a
    - team-b
    - team-c
  rules:
    - from:
        namespaceSelector:
          matchLabels:
            name: team-a
      to:
        namespaceSelector:
          matchLabels:
            name: team-a
```

### Resource Quotas

Implement resource quotas to prevent resource contention:

```yaml
# resource-quota-values.yaml
resourceQuotas:
  enabled: true
  quotas:
    - namespace: team-a
      limits:
        cpu: "4"
        memory: 8Gi
    - namespace: team-b
      limits:
        cpu: "4"
        memory: 8Gi
```

### Tenant-Specific Profiles and Thresholds

Configure tenant-specific security profiles and thresholds:

```yaml
# tenant-profiles-values.yaml
profiles:
  tenantSpecific: true
  configMaps:
    - name: team-a-profiles
      namespace: team-a
      data:
        baseline: |
          name: team-a-baseline
          controls:
            - id: TA-001
              desc: Team A specific control
    - name: team-b-profiles
      namespace: team-b
      data:
        baseline: |
          name: team-b-baseline
          controls:
            - id: TB-001
              desc: Team B specific control

thresholds:
  tenantSpecific: true
  configMaps:
    - name: team-a-thresholds
      namespace: team-a
      data:
        thresholds.yml: |
          failure:
            critical: 0
            high: 3
    - name: team-b-thresholds
      namespace: team-b
      data:
        thresholds.yml: |
          failure:
            critical: 1
            high: 5
```

## Role-Based Access for Different Teams

Implement role-based access for different tenant teams:

```yaml
# rbac-values.yaml
tenantRBAC:
  enabled: true
  roles:
    - name: scanner-admin
      rules:
        - apiGroups: [""]
          resources: ["pods", "configmaps"]
          verbs: ["get", "list"]
    - name: scanner-viewer
      rules:
        - apiGroups: [""]
          resources: ["pods"]
          verbs: ["get", "list"]
  
  roleBindings:
    - name: team-a-admin
      namespace: team-a
      role: scanner-admin
      subjects:
        - kind: Group
          name: team-a-admins
    - name: team-b-viewer
      namespace: team-b
      role: scanner-viewer
      subjects:
        - kind: Group
          name: team-b-users
```

## Centralized Reporting with Tenant Filtering

Configure centralized reporting with tenant filtering:

```yaml
# reporting-values.yaml
reporting:
  centralized:
    enabled: true
    storage:
      type: s3
      bucket: scanner-reports
    tenantFiltering:
      enabled: true
      attributeField: namespace
    access:
      rbac:
        globalAdmins: true
        tenantScopedAccess: true
```

## Validation and Testing

After deployment, validate your multi-tenant setup:

1. Verify tenant isolation:

   ```bash
   # Attempt to scan across namespace boundaries
   ./kubernetes-scripts/scan-container.sh team-b app-pod app-container profiles/baseline --service-account team-a-scanner-sa
   # Should fail due to RBAC restrictions
   ```

2. Test tenant-specific scanning:

   ```bash
   # Scan a team-a container
   ./kubernetes-scripts/scan-container.sh team-a app-pod app-container profiles/baseline --service-account team-a-scanner-sa
   # Should succeed
   ```

3. Verify label-based targeting:

   ```bash
   # Add scan label to pod
   kubectl label pod app-pod -n team-a scan=enabled
   
   # Run the scanner
   helm test team-a-scanner
   ```

## Related Topics

- [Helm Deployment](../helm-deployment.md)
- [RBAC Configuration](../../../rbac/index.md)
- [Label-based RBAC](../../../rbac/label-based.md)
- [Advanced Deployment Topics](../advanced-topics/index.md)
- [Enterprise Environment](enterprise.md)
