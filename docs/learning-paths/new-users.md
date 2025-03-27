# New User Guide

## Overview

!!! security-focus "Security Emphasis"
    Security is a foundational principle of Kube CINC Secure Scanner. This guide establishes secure practices from the beginning, ensuring your implementation follows security best practices from day one.

This learning path guides you through setting up and using Kube CINC Secure Scanner for the first time. By completing this path, you will understand how to deploy the scanner, run your first security scan, and interpret the results while maintaining a strong security posture.

**Time to complete:** 45-60 minutes

**Target audience:** New users, DevOps engineers, Security professionals

**Security level:** Basic

## Prerequisites

- [ ] A running Kubernetes cluster (minikube, kind, or production cluster)
- [ ] kubectl configured to access your cluster
- [ ] Basic understanding of Kubernetes concepts (pods, deployments, namespaces)

!!! info "Kubernetes Setup"
    If you don't have a Kubernetes cluster set up, follow our [Minikube Setup Guide](../kubernetes-setup/minikube-setup.md) to create a local environment.
    For existing clusters, check our [Existing Cluster Requirements](../kubernetes-setup/existing-cluster-requirements.md) to ensure compatibility.

## Learning Path Steps

### Step 1: Environment Setup {#step-1}

!!! security-note "Security Consideration"
    Always use separate namespaces for scanner components to implement proper isolation and follow the principle of least privilege.

In this step, you'll set up your environment to run Kube CINC Secure Scanner.

<div class="grid" markdown>

:material-source-repository:{ .lg .middle } **Clone Repository**

```bash
git clone https://github.com/mitre/kube-secure-scanner.git
cd kube-secure-scanner
```

:material-kubernetes:{ .lg .middle } **Set Up Minikube**

```bash
./kubernetes-scripts/setup-minikube.sh
```

:material-check-circle-outline:{ .lg .middle } **Verify Setup**

```bash
kubectl get pods -A
```

</div>

<div class="progress" markdown>
- [x] Setup started
- [x] Repository cloned
- [x] Minikube running
- [ ] First scan completed
</div>

**Estimated time:** 10 minutes

**Success criteria:** Minikube is running and you can see pods in the kube-system namespace.

---

### Step 2: Understanding Scanner Approaches {#step-2}

!!! security-note "Security Consideration"
    Different scanning approaches have different security implications. Understanding these is crucial for making appropriate implementation decisions.

Kube CINC Secure Scanner supports multiple approaches for scanning containers:

<div class="grid cards" markdown>

-   :material-book-open-variant:{ .lg .middle } **Documentation**

    ---
    
    Review the approaches documentation:
    
    - [Approaches Overview](../approaches/index.md)
    - [Approach Comparison](../approaches/comparison.md)
    - [Decision Matrix](../approaches/decision-matrix.md)

-   :material-compare:{ .lg .middle } **Scanning Approaches**

    ---
    
    === "Standard Container"
        **Kubernetes API Approach**
        
        - Most common approach
        - Uses train-k8s-container transport
        - Best for standard containers
        - [Learn more](../approaches/kubernetes-api/index.md)
    
    === "Sidecar Container"
        **Process Namespace Sharing**
        
        - Enhanced isolation
        - Requires pod modifications
        - Works with any container type
        - [Learn more](../approaches/sidecar-container/index.md)
    
    === "Debug Container"
        **Ephemeral Container Approach**
        
        - Designed for distroless containers
        - Requires K8s 1.16+ with ephemeral containers
        - No changes to target containers
        - [Learn more](../approaches/debug-container/index.md)

</div>

<div class="progress" markdown>
- [x] Setup started
- [x] Repository cloned
- [x] Minikube running
- [x] Approaches reviewed
- [ ] First scan completed
</div>

**Estimated time:** 15 minutes

**Success criteria:** You can explain the different scanning approaches and their security implications.

---

### Step 3: Running Your First Scan {#step-3}

!!! security-note "Security Consideration"
    Start with scanning in a non-production environment until you're comfortable with the process and have validated the security implications.

Now you'll run your first container security scan:

1. Create a test pod:

   ```bash
   kubectl apply -f test-pod.yaml
   ```

2. Wait for the pod to be ready:

   ```bash
   kubectl get pods
   ```

3. Run a scan using the standard approach:

   ```bash
   ./kubernetes-scripts/scan-container.sh default test-pod test-container examples/cinc-profiles/container-baseline
   ```

4. Review the scan results:

   ```bash
   # Results are stored in JSON format
   cat results/container-scan-results.json
   ```

**Estimated time:** 15 minutes

**Success criteria:** You've successfully scanned a container and can view the security assessment results.

---

### Step 4: Understanding Scan Results {#step-4}

!!! security-note "Security Consideration"
    Learn to interpret results correctly to avoid false negatives that could leave vulnerabilities unaddressed.

1. Open and examine the scan results:
   - Identify the controls that passed and failed
   - Understand the severity levels
   - Note recommendations for remediation

2. Learn about thresholds and how they're used to determine scan pass/fail:
   - [Basic Thresholds](../configuration/thresholds/basic.md)
   - [Advanced Thresholds](../configuration/thresholds/advanced.md)

**Estimated time:** 10 minutes

**Success criteria:** You can interpret scan results and understand what actions might be needed to address findings.

---

## Security Considerations

This section provides a comprehensive overview of security considerations for new users:

- Always use the principle of least privilege when configuring RBAC for the scanner
- Consider using namespaces to isolate scanner components from your application
- Evaluate the security implications of each scanning approach before implementation
- Ensure scan results are securely stored and not exposed to unauthorized users
- Consider integrating scanning into your CI/CD pipeline for continuous security assessment

## Compliance Relevance

This learning path helps address the following compliance requirements:

- Container Security - Establishes a foundation for systematic container security assessment
- Configuration Compliance - Helps identify misconfigurations that could violate compliance requirements
- Continuous Monitoring - Sets up a process for ongoing security monitoring

## Next Steps

After completing this learning path, consider:

- [Security-First Implementation](security-first.md) - Implement with security as the primary focus
- [Core Concepts](core-concepts.md) - Deepen your understanding of fundamental concepts
- [Implementation Guide](implementation.md) - Get detailed implementation instructions

## Related Resources

- [Security Overview](../security/index.md)
- [Configuration Guide](../configuration/index.md)
- [Architecture Overview](../architecture/index.md)
