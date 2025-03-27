# Pod Configuration for Sidecar Container Scanning

This document explains how to configure Kubernetes pods to use the sidecar container scanning approach.

## Overview

When using the sidecar container approach, you need to configure your pods to include the CINC Auditor scanner container alongside your target container. The two containers share the same pod, allowing the scanner to access the target container's filesystem.

## Configuration Requirements

To enable sidecar scanning, your pod configuration needs:

1. The main application container
2. A CINC Auditor scanner container in the same pod
3. Shared process namespace between containers
4. Appropriate volume mounts for results storage

## Example Pod Configuration

Here is an example pod configuration with a sidecar scanner:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-scanner-sidecar
spec:
  # Enable shared process namespace
  shareProcessNamespace: true
  # Configure containers
  containers:
  # Your application container
  - name: app
    image: your-application-image:tag
    # Container configuration...
    
  # Scanner sidecar container
  - name: scanner
    image: cinc-auditor-scanner:latest
    # Mount volumes for scan results
    volumeMounts:
    - name: results-volume
      mountPath: /opt/scan-results
    # Scanner environment variables
    env:
    - name: TARGET_CONTAINER
      value: "app"
    - name: PROFILE_PATH
      value: "/opt/profiles/container-baseline"
    - name: RESULT_PATH
      value: "/opt/scan-results"
  
  # Volumes for storing results
  volumes:
  - name: results-volume
    emptyDir: {}
```

## Using with Deployments and StatefulSets

To apply this pattern to Deployments or StatefulSets, add the sidecar configuration to the pod template spec:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-scanner
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      shareProcessNamespace: true
      containers:
      - name: app
        # Application container config...
      - name: scanner
        # Scanner container config...
```

## Helm Chart Support

For simplified deployment using Helm, use the provided `sidecar-scanner` chart:

```bash
helm install scanner-sidecar ./helm-charts/sidecar-scanner/ \
  --set targetPod.name=your-app-pod \
  --set targetContainer.name=app
```

The Helm chart handles the sidecar configuration automatically.

## Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `shareProcessNamespace` | Enables process namespace sharing | `true` |
| `TARGET_CONTAINER` | Name of the container to scan | None (required) |
| `PROFILE_PATH` | Path to InSpec profile | `/opt/profiles/container-baseline` |
| `RESULT_PATH` | Path to store results | `/opt/scan-results` |

## Next Steps

After configuring your pods, learn about:

- [Retrieving Results](retrieving-results.md) - How to access and use scan results
- [Implementation Details](implementation.md) - How the sidecar scanning works
