# Plugin Customization

!!! info "Directory Inventory"
    See the [Plugins Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

This section provides documentation for customizing InSpec plugins for specialized container scanning needs.

## Plugin Customization Overview

InSpec uses plugins for transport-specific operations. The `train-k8s-container` plugin enables scanning Kubernetes containers via the Kubernetes API. This section covers how to modify and extend this plugin for advanced scanning scenarios.

> **STRATEGIC PRIORITY**: Enhancing the train-k8s-container plugin to support distroless containers through the Kubernetes API Approach represents our **highest strategic priority** for enterprise container scanning. This is the recommended approach for production environments and is essential for comprehensive security compliance.

## Customization Guides

- [Distroless Container Support](distroless.md) - Modifications for scanning distroless containers
- [Implementation Guide](implementation.md) - Detailed implementation steps
- [Testing Guide](testing.md) - Testing modifications and customizations

## Common Use Cases

| Use Case | Guide | Description |
|----------|-------|-------------|
| Distroless Containers | [Distroless Support](distroless.md) | Enable scanning for containers without shells |
| Implementation | [Implementation](implementation.md) | Step-by-step implementation guide |
| Testing | [Testing](testing.md) | Test your modifications thoroughly |

## Getting Started

Before customizing plugins, you should understand the current architecture. The train-k8s-container plugin works by:

1. Creating a connection to a Kubernetes cluster via kubeconfig
2. Using `kubectl exec` to execute commands in the target container
3. Running CINC Auditor controls that rely on command execution

Key files in the plugin that would need modification:

1. `lib/train/k8s/container/connection.rb` - Main connection class
2. `lib/train/k8s/container/kubectl_exec_client.rb` - Handles command execution
3. `lib/train/transport/k8s_container.rb` - Transport entry point

## Strategic Importance

Plugin customization, particularly for distroless container support, is a top strategic priority because:

1. **Consistent User Experience**: Users will use identical commands for all container types
2. **Maximum Security Compliance**: The Kubernetes API Approach maintains all security boundaries
3. **Enterprise Scalability**: One solution for all container types simplifies deployment
4. **Simplified CI/CD Integration**: CI/CD pipelines can use a single approach for all workloads
5. **Unified Documentation**: Streamlined documentation and training

## Related Topics

- [Kubernetes API Approach](../../approaches/kubernetes-api/index.md)
- [Debug Container Approach](../../approaches/debug-container/index.md)
- [Distroless Container Basics](../../approaches/debug-container/distroless-basics.md)
