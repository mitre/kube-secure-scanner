# Distroless Container Scanning

## Overview

!!! security-focus "Security Emphasis"
    Distroless containers provide enhanced security by minimizing the attack surface, but they're challenging to scan. This task uses ephemeral debug containers to inspect distroless containers without modifying them, maintaining their security benefits while enabling compliance validation.

This task guides you through scanning a distroless container using the ephemeral debug container approach. This method allows you to scan containers that lack a shell or basic OS utilities without compromising their security benefits.

**Time to complete:** 15-20 minutes

**Security risk:** 🔴 High - Requires ephemeral debug containers with elevated privileges

**Security approach:** Implements controlled use of ephemeral debug containers with proper isolation, limited-scope access, and secure chroot techniques

## Security Architecture

???+ abstract "Understanding Permission Layers"
    Distroless container scanning requires managing permissions across specialized layers:

    **1. Debug Container Permissions**
    * **Control:** Ability to create and attach ephemeral debug containers
    * **Risk area:** Debug containers have elevated access to inspect distroless containers
    * **Mitigation:** Use short-lived debug containers with strict lifecycle management
    
    **2. Process Namespace Permissions**
    * **Control:** Access to shared process namespaces between containers
    * **Risk area:** Potential for cross-container visibility and information leakage
    * **Mitigation:** Carefully configure pod security context and limit debug container capabilities
    
    **3. Filesystem Access Permissions**
    * **Control:** Access to distroless container filesystem through chroot
    * **Risk area:** Improper access could expose sensitive files or alter container state
    * **Mitigation:** Implement read-only filesystem access with controlled mount points

## Security Prerequisites

- [ ] Kubernetes cluster with ephemeral containers support (v1.23+) (see [Existing Cluster Requirements](../kubernetes-setup/existing-cluster-requirements.md))
- [ ] kubectl configured for the target cluster
- [ ] Permissions to create ephemeral containers
- [ ] Permissions to create service accounts and roles in the target namespace
- [ ] CINC Auditor installed (see [prerequisites section](#step-1-verify-prerequisites))
- [ ] SAF CLI installed (will be automatically installed if missing)

!!! info "Kubernetes Setup"
    If you don't have a Kubernetes cluster available, you can set up a local test environment using our [Minikube Setup guide](../kubernetes-setup/minikube-setup.md) with the `--with-distroless` flag.

## Step-by-Step Instructions

### Step 1: Verify Prerequisites

!!! security-note "Security Consideration"
    The debug container approach requires elevated permissions to create ephemeral containers. Use dedicated service accounts with least privilege permissions for this operation.

Ensure you have CINC Auditor installed:

```bash
# Check if CINC Auditor is installed
cinc-auditor version

# Verify kubectl access and ephemeral container capability
kubectl version --short
```

Check if your cluster supports ephemeral containers:

```bash
# API Resources should include pods/ephemeralcontainers
kubectl api-resources | grep ephemeralcontainers
```

### Step 2: Locate or Create a Profile

!!! security-note "Security Consideration"
    Distroless containers require specialized profiles that focus on filesystem checks rather than process or package checks, as they have minimal operating system components.

```bash
# Example for using the built-in container baseline profile
# The project includes sample profiles in examples/cinc-profiles/
cd /path/to/kube-secure-scanner
ls examples/cinc-profiles/container-baseline
```

You can use the built-in examples or provide your own InSpec profile path.

### Step 3: Run the Scanning Script

!!! security-note "Security Consideration"
    The script creates temporary resources with minimal permissions and short-lived tokens. The ephemeral debug container is removed immediately after the scan completes, minimizing the security exposure window.

```bash
# Syntax: ./kubernetes-scripts/scan-distroless-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]
./kubernetes-scripts/scan-distroless-container.sh default distroless-pod app-container examples/cinc-profiles/container-baseline
```

For advanced usage with threshold validation:

```bash
# Using a custom threshold file
./kubernetes-scripts/scan-distroless-container.sh default distroless-pod app-container examples/cinc-profiles/container-baseline examples/thresholds/strict.yml
```

### Step 4: Review Scan Results

!!! security-note "Security Consideration"
    The scan results may include system configuration findings that can help identify security misconfigurations in your distroless container.

The script will output the scan results to the console and save detailed results to JSON and Markdown files.

```bash
# View detailed results (replace timestamp with actual value)
cat scan-results-1616844322.json

# View summary report (replace timestamp with actual value)
cat scan-summary-1616844322.md
```

## Security Best Practices

- Use custom profiles designed specifically for distroless containers that focus on filesystem and static configuration checks
- Implement threshold validation to ensure security compliance requirements are met
- Use a dedicated restricted service account for scanning operations
- Run the scanner in a separate namespace with strict network policies
- Ensure ephemeral containers are removed immediately after scanning
- Configure the ephemeral container with the minimum necessary privileges
- Store scan results securely if they contain sensitive information
- Consider scanning distroless container images before deployment using pre-deployment pipelines

## Verification Steps

1. Verify the scan completed successfully with an exit code of 0

   ```bash
   echo $?
   ```

2. Check the scan results files exist

   ```bash
   ls scan-results-*.json scan-summary-*.md
   ```

3. Verify temporary resources were cleaned up

   ```bash
   # Should return "No resources found"
   kubectl get serviceaccount scanner-* -n default
   kubectl get role scanner-role-* -n default
   kubectl get rolebinding scanner-binding-* -n default
   ```

4. Verify the ephemeral container was removed

   ```bash
   # Should not show any debug containers
   kubectl get pod distroless-pod -n default -o jsonpath='{.status.ephemeralContainerStatuses}'
   ```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Ephemeral containers are disabled" | Upgrade your Kubernetes cluster to v1.23+ or enable the EphemeralContainers feature gate. |
| Permission denied | Ensure you have permissions to create ephemeral containers and service accounts in the target namespace. Check cluster RBAC settings. |
| Container not found | Verify the namespace, pod name, and container name. Use `kubectl get pods -n <namespace>` to list available pods. |
| Scan fails with "chroot: command not found" | The Alpine debug container image may be missing required tools. Use a more comprehensive debug image like busybox or cincproject/auditor. |
| InSpec profile errors | Ensure the profile is designed for distroless containers with a focus on filesystem checks rather than package or process checks. |

## Next Steps

After completing this task, consider:

- [Configuring Thresholds](thresholds-configuration.md) for automated compliance validation
- [GitLab CI Integration](gitlab-integration.md) or [GitHub Actions Integration](github-integration.md) to automate scanning
- [RBAC Configuration](rbac-setup.md) for fine-tuning scanner permissions
- Try [Sidecar Container Scanning](sidecar-container-scan.md) for an alternative approach to scanning distroless containers

## Compliance and Security Considerations

<div class="grid cards" markdown>

-   :material-shield-search:{ .lg .middle } **Risk Analysis**

    ---
    
    Review comprehensive security risk assessment for this approach:
    
    - [Debug Container Security Risks](../security/risk/debug-container.md)
    - Key risk: Temporary container isolation disruption
    - Overall risk rating: 🟠 Moderate
    
    [:octicons-arrow-right-24: Full Risk Analysis](../security/risk/debug-container.md)

-   :material-check-decagram:{ .lg .middle } **Compliance Impact**

    ---
    
    This approach has specific compliance implications:
    
    - DoD 8500.01: ⚠️ Partial alignment (uses debug features)
    - STIG V-242433: ⚠️ Partial alignment (requires debug privileges)
    - CIS 5.2.1: ⚠️ Partial alignment (may need elevated privileges)
    
    [:octicons-arrow-right-24: Compliance Comparison](../security/compliance/approach-comparison.md)

-   :material-shield-lock:{ .lg .middle } **Security Principles**

    ---
    
    Core security principles applied in this task:
    
    - [Ephemeral Credentials](../security/principles/ephemeral-creds.md)
    - [Resource Isolation](../security/principles/resource-isolation.md)
    - [Container Security Threat Model](../security/threat-model/index.md)
    
    [:octicons-arrow-right-24: Security Principles](../security/principles/index.md)

-   :material-file-document-alert:{ .lg .middle } **Documentation Requirements**

    ---
    
    For compliance documentation, be sure to:
    
    - Document the security rationale for using this approach
    - Explain mitigations implemented for identified risks
    - Include time-limited nature of debug container access
    - Reference formal risk acceptance if required for your environment
    
    [:octicons-arrow-right-24: Risk Documentation](../security/compliance/risk-documentation.md)

</div>
