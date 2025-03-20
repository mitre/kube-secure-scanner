# Scanning Distroless Containers

This document outlines the approach for scanning distroless containers using CINC Auditor with Kubernetes ephemeral containers.

## What are Distroless Containers?

Distroless containers are minimalist container images that contain only the application and its runtime dependencies. They do not include:

- Shell
- Package managers
- Standard Linux utilities
- Debugging tools

These containers are designed for improved security by reducing the attack surface, but they present challenges for traditional container scanning approaches.

## The Challenge with Distroless Containers

The train-k8s-container transport plugin that CINC Auditor uses relies on the ability to execute commands within the target container. It typically does this by:

1. Using `kubectl exec` to run commands inside the container
2. Assuming the presence of a shell (like `/bin/sh`) in the container
3. Executing tests that often rely on standard Linux utilities

In distroless containers, these requirements are not met, making traditional scanning impossible.

## Solution: Using Ephemeral Containers

Kubernetes ephemeral containers feature provides a solution:

> "Ephemeral containers are temporary containers that run within a pod's namespace. They allow you to run utilities in a pod's namespace without modifying the original pod specification."

We can leverage ephemeral containers to:

1. Create a temporary debug container attached to the distroless container's pod
2. Share filesystem and process namespaces with the target distroless container
3. Execute CINC Auditor tests from the debug container
4. Access the distroless container's filesystem through the debug container

### Key Understanding Points

**Important:** It's critical to understand how this approach works and its limitations:

1. **Non-intrusive Approach**: The ephemeral debug container (using Alpine/Busybox) doesn't actually modify the distroless container itself. The distroless container remains distroless - we're not adding anything to it or changing its security properties.

2. **Filesystem Access**: The ephemeral container can access the distroless container's filesystem through the proc filesystem (typically via `/proc/[pid]/root/`). This gives us read access to the files without modifying the distroless container.

3. **Limited Resource Usage**: Standard InSpec profiles like the RHEL9 STIG baseline wouldn't work as-is because they rely on commands and utilities that don't exist in distroless containers. Many InSpec resources that rely on command execution wouldn't function properly.

4. **Focus on Filesystem Analysis**: For distroless scanning, we need specialized profiles focusing primarily on:
   - File existence and permissions
   - File content analysis
   - Configuration validation
   - Binary verification

5. **External Analysis**: This approach is similar to how security teams might audit a read-only filesystem - we're examining the state without executing commands within the actual target.

This understanding is crucial for developing effective scanning strategies for distroless containers and setting appropriate expectations for what can be validated in these environments.

## Approaches for Scanning Distroless Containers

There are two main approaches we can take to scan distroless containers:

### Approach 1: Modify the train-k8s-container Plugin

This approach involves forking and modifying the train-k8s-container plugin to work with ephemeral containers:

- Detect if a target container is distroless
- Support connection through ephemeral containers
- Access the target container's filesystem via the ephemeral container

Key files to modify:
- `lib/train/k8s/container/kubectl_exec_client.rb` - Add ephemeral container creation and connection
- `lib/train/k8s/container/connection.rb` - Add distroless detection and alternative connection path

### Approach 2: Direct Chroot Scanning (Alternative)

A more direct approach would be to use a chroot-based method:

1. Create an ephemeral debug container with CINC Auditor pre-installed (requires full Ruby environment)
2. Use chroot to make the distroless container's filesystem appear as the root filesystem
3. Run CINC Auditor locally within the chroot environment

This approach has different technical characteristics:
- More direct but less elegant approach
- Avoids modifying the train-k8s-container plugin but introduces complexity elsewhere
- Standard InSpec profiles work without path modifications, but requires specialized container setup
- More of a "hammer" approach than a scalable enterprise solution

Note: This approach requires:
- The debug container to run with elevated privileges (to use chroot)
- A full Ruby environment with all CINC Auditor dependencies
- A specialized container image based on something like the [CINC Auditor Docker image](https://gitlab.com/cinc-project/docker-images/-/tree/master/docker-auditor)

### User Experience Considerations

When choosing between these approaches, it's important to consider the end-user experience:

#### Approach 1: Modified Plugin (Transparent to Users)

**User Experience Benefits:**
- Users run the exact same commands for both regular and distroless containers
- No additional knowledge required by teams
- Scales easily across many teams
- Teams don't need to understand the underlying mechanics
- Consistent experience regardless of container type

**Adoption Considerations:**
- Easier organizational adoption due to consistent workflow
- Lower training burden
- Better for multi-team environments

#### Approach 2: Chroot Approach (Requires More User Awareness)

**User Experience Challenges:**
- Requires specialized debug containers
- May require different commands or workflows for distroless vs. regular containers
- More complexity visible to end users
- Potentially more friction for wide adoption
- Teams need to understand more about the underlying mechanism

**Recommendation:** Approach 1 (plugin modification) is clearly the better choice for a true enterprise-grade solution. While Approach 2 might work as a proof-of-concept or in very limited scenarios, it doesn't offer the transparency, consistency, or scalability needed for organization-wide adoption. For a solution that multiple teams will rely on regularly, the investment in modifying the transport plugin is well justified by the significantly improved user experience and adoption potential.

## Required Changes to Our Scripts

Regardless of which approach we choose, our scanning scripts need to be updated to:

```bash
# Detect if container is distroless
if ! kubectl exec -n ${NAMESPACE} ${POD_NAME} -c ${CONTAINER_NAME} -- /bin/sh -c "echo test" &>/dev/null; then
  echo "Detected distroless container, using ephemeral container approach"
  # Use Debug Container Approach
else
  # Use Kubernetes API Approach
fi
```

### 3. RBAC Updates

Additional RBAC permissions would be needed:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-role-distroless
  namespace: ${NAMESPACE}
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/ephemeralcontainers"]
  verbs: ["get", "create", "update"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["${POD_NAME}"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
  resourceNames: ["${POD_NAME}"]
```

## Implementation Plan

### 1. Enhanced Scanning Script

Create a new script `scan-distroless-container.sh` that:

```bash
#!/bin/bash
# scan-distroless-container.sh - Script to scan distroless containers using ephemeral debug containers
# Usage: ./scan-distroless-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]

set -e

# Input validation and variable setup

# Create ephemeral container
DEBUG_CONTAINER_NAME="debug-scanner-${RUN_ID}"
kubectl debug -it ${POD_NAME} -n ${NAMESPACE} --image=alpine:latest --target=${CONTAINER_NAME} --container=${DEBUG_CONTAINER_NAME} -- sleep 3600 &
EPHEMERAL_PID=$!

# Wait for ephemeral container to be ready
sleep 5

# Run CINC Auditor scan using ephemeral container
# This would require a modified transport plugin or custom transport approach

# Process results with SAF-CLI (same as our current approach)

# Clean up ephemeral container
kill ${EPHEMERAL_PID}
```

### 2. Ephemeral Container Image

Create a specialized debug container image with:

- CINC Auditor pre-installed
- Required utilities for scanning
- Minimal size for quick deployment

### 3. Fork and Modify train-k8s-container

Create a fork of the train-k8s-container plugin with:

```ruby
# Pseudocode for the modified transport
module Train::Kubernetes::Container
  class Connection < Train::Plugins::Transport::BaseConnection
    def initialize(options)
      @target_container = options[:target_container]
      @namespace = options[:namespace]
      @pod = options[:pod]
      
      if distroless?(@namespace, @pod, @target_container)
        setup_ephemeral_container
        # Connect through ephemeral container
      else
        # Standard connection
      end
    end
    
    def distroless?(namespace, pod, container)
      # Check if shell exists in container
      cmd = ["kubectl", "exec", "-n", namespace, pod, "-c", container, "--", "/bin/sh", "-c", "echo test"]
      begin
        result = Train::Extras::CommandWrapper.run(cmd.join(" "))
        return false # Container has shell
      rescue
        return true # Container is likely distroless
      end
    end
    
    def setup_ephemeral_container
      # Create ephemeral container for debugging
    end
  end
end
```

## Testing and Validation

1. Create test distroless containers:
   - Use Google's distroless images
   - Create test pods with these containers

2. Test scanning capabilities:
   - Validate filesystem access
   - Verify command execution through ephemeral containers
   - Ensure results are properly collected

3. Test RBAC restrictions:
   - Verify proper permissions for ephemeral container creation
   - Ensure secure access control

## Future Work

1. Support for different distroless base images
2. Performance optimizations for ephemeral container approach
3. Integration with CI/CD pipelines for distroless scanning
4. Comprehensive documentation on distroless container scanning

## Workflow Diagrams

To better understand the approaches for scanning distroless containers, refer to the [Workflow Diagrams](../architecture/workflows.md) document, which includes:

- Kubernetes API Approach workflow
- Debug Container Approach workflow
- Sidecar Container Approach workflow
- CI/CD integration with scanner services

These visual representations help clarify the differences between approaches and their integration points.

## GitLab CI Integration

For implementing distroless container scanning in GitLab CI pipelines, see:

- [Standard GitLab CI Integration](../integration/gitlab.md)
- [GitLab Pipeline Examples](../gitlab-pipeline-examples/index.md) for reference implementations

Our GitLab CI example with services includes a dedicated job for distroless container scanning using specialized service containers, making it easier to integrate into existing pipelines.

## Security and Compliance Considerations

### Container Security Best Practices

When implementing container scanning for distroless containers, it's important to adhere to security best practices:

1. **Minimize Attack Surface**: Distroless containers already provide security benefits by reducing the attack surface. Our scanning approaches are designed to preserve these benefits:
   - The Debug Container Approach uses temporary debug containers that are removed after scanning
   - The Sidecar Container Approach maintains isolation between containers while enabling scanning
   - The Kubernetes API Approach (with future distroless support) will maintain complete container isolation

2. **Principle of Least Privilege**: All scanning approaches implement least-privilege RBAC permissions:
   - Limited to specific namespaces
   - Time-bound credentials
   - Restricted API access
   - Specific pod targeting

3. **Container Isolation**: Following Docker's best practice of "one application per container":
   - The Kubernetes API Approach best preserves this principle
   - Debug Container Approach temporarily breaks this principle but is removed after scanning
   - Sidecar Container Approach introduces a second process but maintains namespace boundaries

### Alignment with Security Frameworks

Our container scanning approaches align with key security frameworks and guidance:

| Security Framework | Alignment | Notes |
|-------------------|-----------|-------|
| **NIST SP 800-190** | High | Follows container security principles for access control, isolation, and minimizing attack surface |
| **CIS Docker Benchmark** | High | Adheres to container security configurations and least-privilege access |
| **CIS Kubernetes Benchmark** | High | Follows recommended RBAC and namespace isolation practices |
| **NSA/CISA Kubernetes Hardening Guidelines** | High | Implements recommended scanning practices and security controls |
| **MITRE ATT&CK for Containers** | Medium-High | Helps mitigate techniques in the MITRE ATT&CK for Containers matrix |

### MITRE ATT&CK Considerations

Our scanning approaches help mitigate several container-specific attack techniques identified in the MITRE ATT&CK framework:

- **T1610 - Deploy Container**: Prevents unauthorized container deployment through least-privilege RBAC
- **T1613 - Container and Resource Discovery**: Limits visibility of container resources
- **T1543.005 - Create or Modify System Process: Container Service**: Prevents modification of container configurations

## References

- [Kubernetes Ephemeral Containers Documentation](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/)
- [Google Distroless Container Images](https://github.com/GoogleContainerTools/distroless)
- [InSpec train-k8s-container transport](https://github.com/inspec/train-k8s-container)
- [CINC Project Docker Images](https://gitlab.com/cinc-project/docker-images/-/tree/master/docker-auditor)
- [NIST SP 800-190: Application Container Security Guide](https://nvlpubs.nist.gov/nistpubs/specialpublications/nist.sp.800-190.pdf)
- [NSA/CISA Kubernetes Hardening Guidance](https://www.nsa.gov/Press-Room/News-Highlights/Article/Article/2716980/nsa-cisa-release-kubernetes-hardening-guidance/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [MITRE ATT&CK for Containers](https://attack.mitre.org/matrices/enterprise/containers/)
- [Docker Best Practices](https://docs.docker.com/build/building/best-practices/)
