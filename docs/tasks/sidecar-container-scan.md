# Sidecar Container Scanning

## Overview

!!! security-focus "Security Emphasis"
    The sidecar container approach provides an alternative scanning method that works for both standard and distroless containers. It offers enhanced security by not requiring privileged debug containers, making it suitable for environments with strict security policies.

This task guides you through scanning a container using the sidecar container approach, which utilizes a shared process namespace to enable scanning of both standard and distroless containers. This approach is particularly useful in environments where ephemeral containers are not available.

**Time to complete:** 15-20 minutes

**Security risk:** 🟡 Medium - Requires shared process namespace between containers

**Security approach:** Implements container isolation with controlled shared process namespace, proper pod-level security contexts, and least-privilege sidecar configuration

## Security Architecture

???+ abstract "Understanding Permission Layers"
    Sidecar container scanning involves careful management of shared boundaries:

    **1. Pod-Level Security Context**
    * **Control:** Overall pod security context including shared process namespace
    * **Risk area:** Shared namespaces could allow unwanted visibility between containers
    * **Mitigation:** Configure minimal shared resources and apply pod security policies
    
    **2. Sidecar Container Permissions**
    * **Control:** Scanner's access to target container processes and filesystem
    * **Risk area:** Over-permissive sidecar could expose more container data than intended
    * **Mitigation:** Run sidecar with non-root user and restricted capabilities
    
    **3. Target Container Isolation**
    * **Control:** Primary container's isolation despite shared namespace
    * **Risk area:** Target container operation could be affected by sidecar activities
    * **Mitigation:** Run sidecar with read-only filesystem access and no write capabilities

## Security Prerequisites

- [ ] Kubernetes cluster with shared process namespace support (v1.17+) (see [Existing Cluster Requirements](../kubernetes-setup/existing-cluster-requirements.md))
- [ ] kubectl configured for the target cluster
- [ ] Permissions to create pods and service accounts in the target namespace
- [ ] Container image to scan
- [ ] CINC Auditor profile for scanning
- [ ] Optional: Threshold file for compliance validation

!!! info "Kubernetes Setup"
    If you don't have a Kubernetes cluster available, you can set up a local test environment using our [Minikube Setup guide](../kubernetes-setup/minikube-setup.md).

## Step-by-Step Instructions

### Step 1: Verify Prerequisites

!!! security-note "Security Consideration"
    The sidecar approach requires the ability to create pods with a shared process namespace. Ensure your cluster's security policies allow this feature, as it enables containers within the same pod to see each other's processes.

Ensure your Kubernetes cluster supports shared process namespaces:

```bash
# Check Kubernetes version - should be 1.17+
kubectl version --short

# Verify you have permissions to create pods in the target namespace
kubectl auth can-i create pods --namespace=default
```

### Step 2: Prepare Your InSpec Profile

!!! security-note "Security Consideration"
    Select an appropriate InSpec profile that aligns with your security requirements. For distroless containers, focus on filesystem checks rather than process or package checks.

```bash
# Example for using the built-in container baseline profile
# The project includes sample profiles in examples/cinc-profiles/
cd /path/to/kube-cinc-secure-scanner
ls examples/cinc-profiles/container-baseline
```

You can use the built-in examples or provide your own InSpec profile path.

### Step 3: Run the Scanning Script

!!! security-note "Security Consideration"
    The script creates a pod with shared process namespace, which allows the scanner container to access the target container's filesystem. While this is more secure than privileged containers, it still represents a reduction in container isolation.

```bash
# Syntax: ./kubernetes-scripts/scan-with-sidecar.sh <namespace> <target-image> <profile-path> [threshold_file]
./kubernetes-scripts/scan-with-sidecar.sh default busybox:latest examples/cinc-profiles/container-baseline
```

For advanced usage with threshold validation:

```bash
# Using a custom threshold file
./kubernetes-scripts/scan-with-sidecar.sh default busybox:latest examples/cinc-profiles/container-baseline examples/thresholds/strict.yml
```

### Step 4: Review and Retrieve Results

!!! security-note "Security Consideration"
    The scan results may identify security issues in your container. Review the results carefully and address any critical findings promptly.

The script automatically retrieves the scan results and displays a summary. The results are also saved to a local directory.

```bash
# View the results directory (timestamped)
ls -la scan-results-*

# View detailed results
cat scan-results-*/scan-results.json

# View summary report
cat scan-results-*/scan-summary.md
```

### Step 5: Cleanup Resources (Optional)

The script will ask if you want to clean up the resources it created. If you choose not to clean up during the script execution, you can do it manually later:

```bash
# Replace with the actual pod name and namespace
kubectl delete pod/sidecar-scanner-1234567890 -n default
kubectl delete configmap/inspec-profile-1234567890 -n default
kubectl delete configmap/inspec-threshold-1234567890 -n default
```

## Security Best Practices

- Use dedicated namespaces for scanning operations to isolate the scanner from other workloads
- Apply strict resource limits to scanner pods to prevent resource exhaustion
- Use read-only filesystem mounts where possible to minimize risk
- Implement network policies to restrict scanner pod communications
- Use custom profiles that align with your organization's security requirements
- Implement threshold validation to ensure compliance with security standards
- Clean up scanner pods immediately after use to minimize the security exposure window
- Use RBAC to limit which users can create pods with shared process namespaces
- Regularly update your scanner image to include the latest security fixes

## Verification Steps

1. Verify the scan completed successfully

   ```bash
   cat scan-results-*/threshold-result.txt
   # Should show THRESHOLD_RESULT=0 for a passing scan
   ```

2. Check that the scan results contain valid data

   ```bash
   # Check file size - should be non-zero
   ls -la scan-results-*/scan-results.json
   
   # Check that the JSON is valid
   cat scan-results-*/scan-results.json | jq '.'
   ```

3. Verify resources were cleaned up (if you chose to clean up)

   ```bash
   # These should return "No resources found" if cleanup was performed
   kubectl get pods -l run-id=1234567890 -n default
   kubectl get configmap/inspec-profile-1234567890 -n default
   kubectl get configmap/inspec-threshold-1234567890 -n default
   ```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "shareProcessNamespace is invalid" | Your Kubernetes version may not support shared process namespaces. Upgrade to v1.17+ or use a different scanning approach. |
| Permission denied | Ensure you have permissions to create pods and ConfigMaps in the target namespace. Check cluster RBAC settings. |
| "Target process not found" | The scanner couldn't identify the main process in the target container. You may need to modify the `TARGET_PROCESS` variable in the script to match your specific container. |
| Scan times out | Increase the timeout value in the script or check if the target container is functioning properly. |
| "Failed to scan target filesystem" | The target container's filesystem might not be accessible through /proc. Check if the container uses a custom mount namespace or PID namespace. |
| InSpec profile errors | Ensure the profile is compatible with the target container's operating system and configuration. |

## Next Steps

After completing this task, consider:

- [Configuring Thresholds](thresholds-configuration.md) for automated compliance validation
- [GitLab CI Integration](gitlab-integration.md) or [GitHub Actions Integration](github-integration.md) to automate scanning
- [RBAC Configuration](rbac-setup.md) for fine-tuning scanner permissions
- Compare with other scanning approaches: [Standard Container Scanning](standard-container-scan.md) or [Distroless Container Scanning](distroless-container-scan.md)

## Compliance and Security Considerations

<div class="grid cards" markdown>

-   :material-shield-search:{ .lg .middle } **Risk Analysis**

    ---
    
    Review comprehensive security risk assessment for this approach:
    
    - [Sidecar Container Security Risks](../security/risk/sidecar-container.md)
    - Key risk: Permanent container isolation compromise
    - Overall risk rating: 🟠 Medium-High
    
    [:octicons-arrow-right-24: Full Risk Analysis](../security/risk/sidecar-container.md)

-   :material-check-decagram:{ .lg .middle } **Compliance Impact**

    ---
    
    This approach has significant compliance implications:
    
    - CIS 5.2.4: ❌ Non-alignment (requires process namespace sharing)
    - STIG V-242432: ⚠️ Partial alignment (breaks process isolation)
    - DoD 8500.01: ⚠️ Partial alignment (non-standard access pattern)
    
    [:octicons-arrow-right-24: Compliance Comparison](../security/compliance/approach-comparison.md)

-   :material-shield-lock:{ .lg .middle } **Security Principles**

    ---
    
    Core security principles to consider:
    
    - [Resource Isolation](../security/principles/resource-isolation.md)
    - [Least Privilege Principle](../security/principles/least-privilege.md)
    - [Secure Transport](../security/principles/secure-transport.md)
    
    [:octicons-arrow-right-24: Security Principles](../security/principles/index.md)

-   :material-file-document-alert:{ .lg .middle } **Documentation Requirements**

    ---
    
    For compliance documentation, you MUST:
    
    - Create formal risk acceptance documentation
    - Justify the business need for process namespace sharing
    - Document all mitigations implemented
    - Include sign-off from security authority
    - Establish enhanced monitoring controls
    
    [:octicons-arrow-right-24: Risk Documentation](../security/compliance/risk-documentation.md)

</div>
