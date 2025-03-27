# Helm Chart Deployment

## Overview

!!! security-focus "Security Emphasis"
    This task implements a secure Helm-based deployment that follows security best practices including proper RBAC isolation, least-privilege service accounts, and secure configuration management, ensuring that your container scanning infrastructure maintains a strong security posture.

This task guides you through deploying Kube CINC Secure Scanner using Helm charts. Helm charts provide a standardized, repeatable method for deploying the scanner infrastructure with proper security controls and configuration.

**Time to complete:** 30-45 minutes

**Security risk:** 🟡 Medium - Involves deploying infrastructure components with Kubernetes permissions

**Security approach:** Implements layered security architecture with proper separation of concerns, RBAC isolation, and secure default configurations

## Security Architecture

???+ abstract "Understanding Permission Layers"
    Helm deployment of scanner infrastructure involves multiple permission boundaries:

    **1. Helm Installation Permissions**
    * **Control:** Ability to deploy Helm charts to the cluster
    * **Risk area:** Excessive Helm permissions could allow unauthorized deployments
    * **Mitigation:** Use dedicated service accounts with limited scope for Helm operations
    
    **2. Chart RBAC Permissions**
    * **Control:** What permissions are granted to deployed components
    * **Risk area:** Overly permissive RBAC in charts could compromise security
    * **Mitigation:** Charts implement least-privilege RBAC with proper isolation
    
    **3. Runtime Scanner Permissions**
    * **Control:** What deployed scanner components can access at runtime
    * **Risk area:** Insecure configurations could grant excessive access
    * **Mitigation:** Implement security contexts, network policies, and proper isolation

## Security Prerequisites

- [ ] Kubernetes cluster with Helm v3 installed
- [ ] Administrative access to create namespaces and RBAC resources
- [ ] Local machine with kubectl configured for cluster access
- [ ] Basic understanding of Helm chart structure and values
- [ ] Understanding of [Kubernetes setup requirements](../kubernetes-setup/existing-cluster-requirements.md)

## Step-by-Step Instructions

### Step 1: Understand Chart Structure

!!! security-note "Security Consideration"
    Understanding the chart structure helps ensure you deploy only the components you need, reducing attack surface.

The Kube CINC Secure Scanner Helm charts follow a modular, layered design:

1. **scanner-infrastructure**: Core RBAC, service accounts, and base infrastructure
2. **common-scanner**: Shared components used by all scanner types
3. **standard-scanner**: For scanning standard containers using Kubernetes API
4. **distroless-scanner**: For scanning distroless containers using ephemeral debug containers
5. **sidecar-scanner**: For scanning containers using the sidecar approach

### Step 2: Deploy the Scanner Infrastructure

!!! security-note "Security Consideration"
    The scanner infrastructure chart creates the base security components including namespaces, service accounts, and RBAC.

1. Clone the repository and navigate to the helm-charts directory:

```bash
cd helm-charts/
```

2. Review the infrastructure chart values:

```bash
cat scanner-infrastructure/values.yaml
```

3. Create a custom values file for the infrastructure:

```bash
cat > my-infrastructure-values.yaml << EOF
namespace:
  name: cinc-scanner
  labels:
    purpose: security-scanning

serviceAccount:
  create: true
  name: scanner-sa
  annotations:
    security.owner: "security-team"

rbac:
  create: true
  strictMode: true  # Enforce strict RBAC permissions
EOF
```

4. Install the scanner infrastructure:

```bash
helm install scanner-infrastructure ./scanner-infrastructure \
  --values my-infrastructure-values.yaml \
  --namespace cinc-scanner \
  --create-namespace
```

### Step 3: Deploy the Common Scanner Components

!!! security-note "Security Consideration"
    The common scanner chart deploys shared components used by all scanner types with secure defaults.

1. Review the common scanner values:

```bash
cat common-scanner/values.yaml
```

2. Create a custom values file for common components:

```bash
cat > my-common-values.yaml << EOF
# Reference the infrastructure chart components
infrastructure:
  serviceAccount:
    name: scanner-sa

# Configure scripts and thresholds
configMaps:
  scripts:
    create: true
  thresholds:
    create: true
    defaultThreshold: 80  # Minimum passing score percentage
    criticalFailures: 0   # No critical failures allowed
    highFailures: 2       # Maximum allowed high severity failures

security:
  podSecurityContext:
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 1000
    fsGroup: 1000
EOF
```

3. Install the common scanner components:

```bash
helm install common-scanner ./common-scanner \
  --values my-common-values.yaml \
  --namespace cinc-scanner
```

### Step 4: Deploy a Scanner Type

!!! security-note "Security Consideration"
    Choose the scanner type that best matches your security requirements. The standard scanner is the most secure for regular containers.

#### For Standard Container Scanning

1. Review the standard scanner values:

```bash
cat standard-scanner/values.yaml
```

2. Create a custom values file:

```bash
cat > my-standard-values.yaml << EOF
# Reference common components
common:
  enabled: true
  serviceAccount:
    name: scanner-sa

# Scanner configuration
scanner:
  image:
    repository: ghcr.io/mitre/cinc-auditor-container
    tag: latest
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    capabilities:
      drop:
      - ALL

# Profile configuration
profiles:
  - name: linux-baseline
    source: dev-sec/linux-baseline
    threshold: 80
EOF
```

3. Install the standard scanner:

```bash
helm install standard-scanner ./standard-scanner \
  --values my-standard-values.yaml \
  --namespace cinc-scanner
```

#### For Distroless Container Scanning

```bash
cat > my-distroless-values.yaml << EOF
# Reference common components
common:
  enabled: true
  serviceAccount:
    name: scanner-sa

# Scanner configuration
scanner:
  image:
    repository: ghcr.io/mitre/cinc-auditor-debug-container
    tag: latest
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
      - ALL

# Profile configuration
profiles:
  - name: linux-baseline
    source: dev-sec/linux-baseline
    threshold: 75
EOF

helm install distroless-scanner ./distroless-scanner \
  --values my-distroless-values.yaml \
  --namespace cinc-scanner
```

#### For Sidecar Container Scanning

```bash
cat > my-sidecar-values.yaml << EOF
# Reference common components
common:
  enabled: true
  serviceAccount:
    name: scanner-sa

# Scanner configuration
scanner:
  image:
    repository: ghcr.io/mitre/cinc-auditor-sidecar
    tag: latest
  resources:
    limits:
      cpu: 300m
      memory: 384Mi
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000

# Pod configuration
pod:
  shareProcessNamespace: true
  
# Profile configuration
profiles:
  - name: linux-baseline
    source: dev-sec/linux-baseline
    threshold: 80
EOF

helm install sidecar-scanner ./sidecar-scanner \
  --values my-sidecar-values.yaml \
  --namespace cinc-scanner
```

### Step 5: Verify the Deployment

1. Check that all components deployed successfully:

```bash
helm list -n cinc-scanner
kubectl get all -n cinc-scanner
```

2. Verify RBAC resources:

```bash
kubectl get serviceaccounts,roles,rolebindings -n cinc-scanner
```

3. Check configmaps for scripts and thresholds:

```bash
kubectl get configmaps -n cinc-scanner
```

### Step 6: Run a Test Scan

!!! security-note "Security Consideration"
    Running a test scan validates that your deployment has the correct permissions while also checking your container security.

1. Deploy a test pod:

```bash
# For standard scanner
kubectl apply -f standard-scanner/templates/test-pod.yaml -n cinc-scanner

# For distroless scanner
kubectl apply -f distroless-scanner/templates/test-pod.yaml -n cinc-scanner

# For sidecar scanner
kubectl apply -f sidecar-scanner/templates/test-pod.yaml -n cinc-scanner
```

2. Wait for the pod to complete:

```bash
kubectl wait --for=condition=complete job/scanner-test-job -n cinc-scanner --timeout=300s
```

3. Check the scan results:

```bash
kubectl logs job/scanner-test-job -n cinc-scanner
```

## Security Best Practices

- Review chart values thoroughly before deployment
- Use custom values files rather than modifying chart files directly
- Enable the strictMode RBAC option for tighter security controls
- Configure resource limits for all containers to prevent resource exhaustion
- Implement proper pod security contexts with non-root execution
- Set appropriate threshold values based on your security requirements
- Use a specific image tag rather than 'latest' for production deployments
- Apply network policies to restrict scanner communication
- Store sensitive values in Kubernetes secrets rather than values files
- Regularly update scanner images to include security patches

## Verification Steps

1. Verify service account permissions

   ```bash
   kubectl auth can-i --as=system:serviceaccount:cinc-scanner:scanner-sa \
     get pods -n cinc-scanner
   
   kubectl auth can-i --as=system:serviceaccount:cinc-scanner:scanner-sa \
     create pods/exec -n cinc-scanner
   ```

2. Validate security contexts

   ```bash
   kubectl get pods -n cinc-scanner -o jsonpath='{.items[*].spec.securityContext}'
   ```

3. Check resource limits

   ```bash
   kubectl get pods -n cinc-scanner -o jsonpath='{.items[*].spec.containers[*].resources}'
   ```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Helm chart installation fails** | Verify Helm version (v3+) and proper cluster access |
| **Permission denied errors** | Check RBAC configuration and service account permissions |
| **Scanner pods failing to start** | Inspect logs with `kubectl logs` and verify image exists and is accessible |
| **Security context issues** | Verify that your cluster's Pod Security Admission allows the security contexts defined in values |
| **Charts not finding dependencies** | Make sure you're in the helm-charts directory and dependency charts are available |

## Next Steps

After completing this task, consider:

- [Configure scanning thresholds](thresholds-configuration.md) to set appropriate security baselines
- [Set up CI/CD integration](github-integration.md) to automate container scanning
- [Implement custom profiles](../configuration/plugins/implementation.md) for your specific security requirements
- [Configure RBAC for multi-tenant environments](rbac-setup.md) to enhance isolation

## Related Security Considerations

- [Helm Chart Security Best Practices](../helm-charts/security/best-practices.md)
- [RBAC Hardening](../helm-charts/security/rbac-hardening.md)
- [Kubernetes Setup](../kubernetes-setup/index.md)
- [Container Scanner Security Models](../security/risk/model.md)
