# Standard Container Scanning

## Overview

!!! security-focus "Security Emphasis"
    This task implements security best practices including least privilege RBAC, short-lived tokens, and temporary credentials. The standard container scanning approach is the most secure scanning method for non-distroless containers.

<div class="grid cards" markdown>

-   :material-kubernetes:{ .lg .middle } **Standard Container Scanning**

    ---
    
    This task guides you through scanning a standard (non-distroless) container using the Kubernetes API approach. The approach uses the train-k8s-container transport to execute commands inside the target container through the Kubernetes API.

-   :material-timer-outline:{ .lg .middle } **Task Details**

    ---
    
    **Time to complete:** 10-15 minutes  
    **Security risk:** 🟡 Medium - Requires creation of temporary service accounts and RBAC resources  
    **Security approach:** Implements security best practices including ephemeral credentials, least-privilege RBAC, and proper resource lifecycle management

</div>

## Security Architecture

???+ abstract "Understanding Permission Layers"
    Standard container scanning involves multiple distinct permission layers that must be properly isolated:

    **1. Administrator/Operator Permissions**
    * **Control:** Ability to create service accounts, roles, and role bindings
    * **Risk area:** Over-privileged administrator access could affect other resources
    * **Mitigation:** Use service accounts with scoped permissions limited to RBAC management
    
    **2. Scanner Service Account Permissions**
    * **Control:** Scanner's ability to access and execute commands in target containers
    * **Risk area:** Overly permissive scanner permissions could allow unintended access
    * **Mitigation:** Create time-limited, namespace-scoped permissions for specific containers
    
    **3. Container Context Permissions**
    * **Control:** What the scanner can access inside the container during execution
    * **Risk area:** Root-level scanning might access sensitive container data
    * **Mitigation:** Run containers with non-root users and restricted capabilities

## Security Prerequisites

- [ ] Kubernetes cluster with RBAC enabled (see [Existing Cluster Requirements](../kubernetes-setup/existing-cluster-requirements.md))
- [ ] kubectl configured for the target cluster
- [ ] Permissions to create service accounts and roles in the target namespace
- [ ] CINC Auditor installed (see [prerequisites section](#step-1-verify-prerequisites))
- [ ] SAF CLI installed (will be automatically installed if missing)

!!! info "Kubernetes Setup"
    If you don't have a Kubernetes cluster available, you can set up a local test environment using our [Minikube Setup guide](../kubernetes-setup/minikube-setup.md).

## Step-by-Step Instructions

### Step 1: Verify Prerequisites

!!! security-note "Security Consideration"
    The scanner uses CINC Auditor (open-source InSpec) to avoid licensing issues in automated environments.

Ensure you have CINC Auditor installed:

```bash
# Check if CINC Auditor is installed
cinc-auditor version

# If not installed, install it following the project documentation
# For example, on Ubuntu/Debian:
# sudo apt-get install cinc-auditor
```

Verify kubectl access to the cluster:

```bash
# Check kubectl connection
kubectl get nodes
```

### Step 2: Locate or Create a Profile

!!! security-note "Security Consideration"
    Using appropriate security profiles is crucial. Ensure the profile matches the container's purpose and requirements.

```bash
# Example for using the built-in container baseline profile
# The project includes sample profiles in examples/cinc-profiles/
cd /path/to/kube-secure-scanner
ls examples/cinc-profiles/container-baseline
```

You can use the built-in examples or provide your own InSpec profile path.

### Step 3: Run the Scanning Script

!!! security-note "Security Consideration"
    The script creates temporary resources with minimal permissions and short-lived tokens (default 1 hour). All resources are cleaned up after the scan completes.

```bash
# Syntax: ./kubernetes-scripts/scan-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]
./kubernetes-scripts/scan-container.sh default nginx-pod nginx-container examples/cinc-profiles/container-baseline
```

For advanced usage with threshold validation:

```bash
# Using a custom threshold file
./kubernetes-scripts/scan-container.sh default nginx-pod nginx-container examples/cinc-profiles/container-baseline examples/thresholds/strict.yml
```

### Step 4: Review Scan Results

The script will output the scan results to the console and save detailed results to JSON and Markdown files.

```bash
# View detailed results (replace timestamp with actual value)
cat scan-results-1616844322.json

# View summary report (replace timestamp with actual value)
cat scan-summary-1616844322.md
```

## Security Best Practices

- Use namespace-specific service accounts for isolation
- Implement threshold validation to ensure compliance requirements are met
- Run scans with least privilege - only scan containers you need to assess
- Store scan results securely if they contain sensitive information
- Consider using GitOps to manage scanning profiles in version control
- Configure scan thresholds to align with your organization's compliance requirements

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

## Troubleshooting

<div class="grid cards" markdown>

-   :octicons-alert-24:{ .lg .middle .text-red-500 } **Permission Denied**

    ---
    
    Ensure you have permissions to create service accounts and roles in the target namespace.
    
    ```bash
    # Check your permissions
    kubectl auth can-i create serviceaccount --namespace=default
    kubectl auth can-i create role --namespace=default
    kubectl auth can-i create rolebinding --namespace=default
    ```

-   :material-cube-outline:{ .lg .middle .text-orange-500 } **Container Not Found**

    ---
    
    Verify the namespace, pod name, and container name.
    
    ```bash
    # List available pods
    kubectl get pods -n <namespace>
    
    # Get details of a specific pod
    kubectl describe pod <pod-name> -n <namespace>
    ```

-   :octicons-file-code-24:{ .lg .middle .text-blue-500 } **InSpec Profile Errors**

    ---
    
    Ensure the profile exists and is correctly formatted.
    
    ```bash
    # Check profile structure
    ls -la <profile-path>
    
    # Validate profile syntax
    cinc-auditor check <profile-path>
    ```

-   :material-package-variant-closed:{ .lg .middle .text-green-500 } **SAF CLI Not Found**

    ---
    
    The script attempts to install SAF CLI automatically, but you may need to install Node.js first.
    
    ```bash
    # Check Node.js installation
    node -v
    
    # Install SAF CLI manually if needed
    npm install -g @mitre/saf
    ```

-   :material-alert-decagram:{ .lg .middle .text-purple-500 } **Threshold Validation Failed**

    ---
    
    Review scan results and adjust either your container security posture or threshold requirements.
    
    ```bash
    # View detailed scan results
    cat scan-results-*.json | jq '.profiles[0].controls[] | select(.status=="failed")'
    ```

</div>

## Next Steps

<div class="grid cards" markdown>

-   :material-threshold:{ .lg .middle } **Configure Security Thresholds**

    ---
    
    Set up automated compliance validation with custom threshold files.
    
    [:octicons-arrow-right-24: Configure Thresholds](thresholds-configuration.md)

-   :material-sync:{ .lg .middle } **CI/CD Integration**

    ---
    
    Automate scanning in your continuous integration pipelines.
    
    [:octicons-arrow-right-24: GitHub Actions](github-integration.md) · [:octicons-arrow-right-24: GitLab CI](gitlab-integration.md)

-   :material-shield-account:{ .lg .middle } **Security Hardening**

    ---
    
    Fine-tune RBAC permissions and access controls.
    
    [:octicons-arrow-right-24: RBAC Configuration](rbac-setup.md)

-   :material-flask-outline:{ .lg .middle } **Advanced Scanning**

    ---
    
    Explore scanning of specialized container types.
    
    [:octicons-arrow-right-24: Distroless Container Scanning](distroless-container-scan.md)

</div>

## Compliance and Security Considerations

<div class="grid cards" markdown>

-   :material-shield-search:{ .lg .middle } **Risk Analysis**

    ---
    
    Review comprehensive security risk assessment for this approach:
    
    - [Kubernetes API Security Risks](../security/risk/kubernetes-api.md)
    - Key risk: Minimal - uses standard K8s APIs
    - Overall risk rating: 🟢 Low
    
    [:octicons-arrow-right-24: Full Risk Analysis](../security/risk/kubernetes-api.md)

-   :material-check-decagram:{ .lg .middle } **Compliance Impact**

    ---
    
    This approach has strong compliance alignment:
    
    - DoD 8500.01: ✅ Full alignment (standard interfaces)
    - SRG-APP-000142: ✅ Full alignment (least privilege)
    - STIG V-242423: ✅ Full alignment (clear RBAC implementation)
    - CIS 5.2.4: ✅ Full alignment (no process sharing needed)
    
    [:octicons-arrow-right-24: Compliance Comparison](../security/compliance/approach-comparison.md)

-   :material-shield-lock:{ .lg .middle } **Security Principles**

    ---
    
    Core security principles applied in this task:
    
    - [Least Privilege Principle](../security/principles/least-privilege.md)
    - [RBAC Security](../rbac/index.md)
    - [Security Threat Model](../security/threat-model/index.md)
    - [Token Exposure Protection](../security/threat-model/token-exposure.md)
    
    [:octicons-arrow-right-24: Security Principles](../security/principles/index.md)

-   :material-file-document-alert:{ .lg .middle } **Documentation Requirements**

    ---
    
    For compliance documentation:
    
    - Standard documentation of RBAC implementation is sufficient
    - No special risk acceptance documentation required
    - Document token lifecycle management
    - Include audit logging configuration
    
    [:octicons-arrow-right-24: Risk Documentation](../security/compliance/risk-documentation.md)

</div>
