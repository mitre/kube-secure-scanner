# Distroless Container Basics

This document explains what distroless containers are, their benefits, and the challenges they present for security scanning.

## What are Distroless Containers?

Distroless containers are minimalist container images that contain only the application and its runtime dependencies. They do not include:

- Shell
- Package managers
- Standard Linux utilities
- Debugging tools

These containers are designed for improved security by reducing the attack surface, but they present challenges for traditional container debugging and scanning approaches.

## Key Characteristics of Distroless Containers

### What's Included in Distroless Containers

1. **Application binaries and libraries**: Just the executables and shared libraries needed for the application to run
2. **Runtime dependencies**: Minimal set of files and libraries required by the runtime (e.g., Java JRE, Python interpreter)
3. **CA certificates**: For secure network connections
4. **Timezone data**: For correct time representation
5. **Non-root user**: Typically configured to run as a non-privileged user

### What's Explicitly Excluded

1. **Shell**: No `/bin/sh`, `/bin/bash`, or other shells
2. **Package manager**: No apt, dpkg, yum, etc.
3. **Common utilities**: No ls, cat, grep, etc.
4. **Development tools**: No compilers, debuggers, etc.
5. **Configuration tools**: No init system or service managers

## Benefits of Distroless Containers

1. **Reduced Attack Surface**: Fewer components mean fewer potential vulnerabilities
2. **Smaller Image Size**: Significantly smaller images, often 10-20% the size of standard images
3. **Improved Security Posture**: Limited capabilities for attackers if compromised
4. **Immutable Infrastructure**: Encourages proper CI/CD practices as containers can't be modified at runtime
5. **Simplified Dependency Management**: Clear definition of actual runtime dependencies
6. **Improved Performance**: Less overhead, faster startup times

## Examples of Distroless Container Images

Google's distroless containers project provides several base images:

- **distroless/static**: Ultra-minimal image for statically-linked binaries
- **distroless/base**: Minimal base image with glibc
- **distroless/java**: For Java applications
- **distroless/python**: For Python applications
- **distroless/nodejs**: For Node.js applications
- **distroless/cc**: For C/C++ applications

## The Challenge with Scanning Distroless Containers

The train-k8s-container transport plugin that CINC Auditor uses relies on the ability to execute commands within the target container. It typically does this by:

1. Using `kubectl exec` to run commands inside the container
2. Assuming the presence of a shell (like `/bin/sh`) in the container
3. Executing tests that often rely on standard Linux utilities

In distroless containers, these requirements are not met, making traditional scanning impossible.

### Common Errors When Attempting to Scan Distroless

When trying to scan a distroless container with the standard approach, you'll see errors like:

```
Error: Failed to execute command: 'sh -c command'. Error was: executable file not found: stat /bin/sh: no such file or directory
```

Or when using InSpec directly:

```
No such file or directory - /bin/sh
```

## Distroless Container Detection

Detecting distroless containers can be done by:

1. Attempting to execute a simple command and checking for failure
2. Testing for the presence of common shells
3. Looking at image metadata if available

Example detection code:

```bash
# Try to execute a command in the container
kubectl exec -n $NAMESPACE $POD_NAME -c $CONTAINER_NAME -- ls /bin/sh &>/dev/null
SHELL_CHECK=$?

# Check for common shells
kubectl exec -n $NAMESPACE $POD_NAME -c $CONTAINER_NAME -- which sh &>/dev/null || \
kubectl exec -n $NAMESPACE $POD_NAME -c $CONTAINER_NAME -- which bash &>/dev/null
WHICH_CHECK=$?

# If both checks fail, it's likely a distroless container
if [ $SHELL_CHECK -ne 0 ] && [ $WHICH_CHECK -ne 0 ]; then
  echo "Container appears to be distroless"
fi
```

## Common Distroless Scanning Approaches

There are several approaches to scanning distroless containers:

1. **Debug Container Approach**: Using Kubernetes ephemeral containers to inspect the distroless container (our recommended interim approach)
2. **Sidecar Approach**: Deploying sidecar containers with shared process namespace
3. **Static Analysis**: Scanning the container image rather than the running container
4. **Custom Tooling**: Building specialized tools for distroless containers

## Base Image Influence on Scanning Approach

The choice of distroless base image affects the scanning approach:

| Distroless Base | Key Characteristics | Scanning Considerations |
|-----------------|---------------------|-------------------------|
| Static | No libc, for statically-linked binaries | Most restricted, needs complete external access |
| Base | Includes glibc but no shell | Cannot execute commands, needs external tools |
| Java | JRE without shell or tools | Can analyze JVM but not execute shell commands |
| Python | Python runtime without shell | Can potentially use Python for some inspections |
| Node.js | Node runtime without shell | Can potentially use Node for some inspections |

## Container Security Considerations

Distroless containers provide security benefits:

1. **Attack Surface Reduction**: No shell means no easy execution for attackers
2. **Limited Privilege Escalation**: Fewer tools available if compromised
3. **Vulnerability Reduction**: No excess packages means fewer CVEs

However, they also introduce security challenges:

1. **Limited Inspectability**: Harder to debug and scan
2. **Specialized Knowledge Required**: Teams need more advanced container expertise
3. **Special Handling in Security Tooling**: Many security tools assume shell access

## Recommended InSpec Resources for Distroless

When creating InSpec profiles for distroless containers, focus on:

1. **file resource**: For checking file existence, permissions, content
2. **directory resource**: For checking directory attributes
3. **parse_config* resources**: For analyzing configuration files without commands
4. **packages resource**: Only for language-specific package analysis (npm, pip, etc.)
5. **simple matchers**: Resources that don't depend on command execution

Avoid resources that rely on command execution:

1. **command resource**: Will fail without a shell
2. **process resource**: Often depends on ps command
3. **service resource**: Requires service management tools
4. **user/group resources**: Often depend on commands like id, getent

## Related Resources

- [Google Distroless Container Images](https://github.com/GoogleContainerTools/distroless)
- [Debug Container Approach Implementation](implementation.md)
- [Approach Comparison](../comparison.md)
- [Sidecar Container Approach](../sidecar-container/index.md)
