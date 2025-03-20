# Debugging Distroless Containers

This guide explains how to "shell into" a distroless container for debugging purposes, even though distroless containers don't include a shell by design.

## The Challenge with Distroless Containers

Distroless containers intentionally don't include shells, package managers, or other debugging tools. This is excellent for security but presents challenges when you need to:

- Debug running applications
- Troubleshoot issues
- Inspect the container's filesystem
- Analyze running processes

## Solution: Kubernetes Ephemeral Containers

Kubernetes provides a feature called "ephemeral containers" that allows you to attach a debugging container to a running pod without modifying the pod specification.

## Debugging a Distroless Container

### Prerequisites

- Kubernetes cluster v1.18+ (ephemeral containers are beta in v1.23+)
- kubectl v1.18+
- Appropriate permissions to create ephemeral containers

### Basic Approach

```bash
# Shell into a distroless container using kubectl debug
kubectl debug -it <pod-name> --image=busybox:latest --target=<container-name>
```

This command:
1. Creates a new ephemeral container using the busybox image
2. Attaches it to the specified pod
3. Targets the specified container within the pod
4. Opens an interactive terminal session

### Step-by-Step Example

1. **First, identify your distroless pod and container**

```bash
# List all pods
kubectl get pods -n <namespace>

# Describe the pod to find container names
kubectl describe pod <pod-name> -n <namespace>
```

2. **Try to shell into the container directly (this will fail for distroless)**

```bash
kubectl exec -it <pod-name> -n <namespace> -c <container-name> -- /bin/sh
# This will fail with something like: "OCI runtime exec failed: exec failed: container_linux.go:380: 
# starting container process caused: exec: "/bin/sh": stat /bin/sh: no such file or directory"
```

3. **Use kubectl debug to attach a debugging container**

```bash
kubectl debug -it <pod-name> -n <namespace> \
  --image=busybox:latest \
  --target=<container-name> \
  --share-processes
```

**Important:** This command does NOT drop you into the distroless container's shell (since it doesn't have one). Instead, it launches a new debug container with its own shell and binaries, which runs alongside your distroless container in the same pod. You'll be in the shell of this debug container, not the distroless container itself.

4. **Access the distroless container's filesystem**

Once inside the debug container, you can access the target container's filesystem:

```bash
# Find the process IDs of the target container
ps aux

# Look for the main process of your application
# For example, if your app is a Java application:
ps aux | grep java

# Once you have the PID, you can access the container's filesystem
ls -la /proc/<PID>/root/

# Change directory to explore the target container's filesystem
cd /proc/<PID>/root/
```

### Advanced Debugging with Additional Tools

You might need more advanced debugging tools. In that case, use a more feature-rich debug image:

```bash
# Using a debug image with more tools
kubectl debug -it <pod-name> -n <namespace> \
  --image=nicolaka/netshoot \
  --target=<container-name>
```

Popular debug images include:
- `busybox:latest` - Minimal utilities
- `alpine:latest` - Lightweight with package manager
- `nicolaka/netshoot` - Network troubleshooting tools
- `ubuntu:latest` - Full featured OS for debugging

## Example: Debug a Spring Boot Distroless Application

```bash
# Find the pod running the Spring application
kubectl get pods -n production | grep spring-app

# Try to shell in directly (will fail)
kubectl exec -it spring-app-pod-abc123 -n production -c app -- /bin/sh
# Error: OCI runtime exec failed: exec failed: container_linux.go:380: ...

# Attach debug container
kubectl debug -it spring-app-pod-abc123 -n production \
  --image=eclipse-temurin:17 \
  --target=app \
  --share-processes

# Inside the debug container, find Java process
ps aux | grep java

# Example output: 
# 1 user  3213200 ... java -jar /app/spring-boot-app.jar

# Access filesystem and explore
cd /proc/1/root/
ls -la

# Check application logs
cat /proc/1/root/logs/application.log

# Check config files
cat /proc/1/root/app/application.properties
```

## Security Considerations

Remember that adding a debug container temporarily increases the attack surface of your pod. Best practices:

1. Use ephemeral debugging only when needed
2. Apply RBAC restrictions to limit who can create ephemeral containers
3. Choose the minimal debug image needed for your task
4. Avoid leaving debug containers running longer than necessary

## Notes for CI/CD Environments

When using ephemeral containers in CI/CD pipelines for security scanning:

1. Create appropriate service accounts with limited permissions
2. Use the minimal debug image needed for scanning
3. Make sure to properly clean up ephemeral containers after scanning
4. Consider using specialized InSpec profiles for distroless containers
5. Focus scans on filesystem analysis rather than command execution

## Troubleshooting

### "ephemeral containers are disabled for this cluster"

Your Kubernetes cluster doesn't have the feature enabled. Check Kubernetes version and feature gates.

### Permission denied

You need RBAC permissions for pods/ephemeralcontainers. Ensure your service account has the right privileges.

### Can't access filesystem

Make sure you're using the correct process ID. Use `ps aux` to identify the main process in the target container.