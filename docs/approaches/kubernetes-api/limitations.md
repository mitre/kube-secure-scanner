# Limitations and Requirements for Kubernetes API Approach

This document outlines the requirements and limitations of the Kubernetes API approach for container scanning.

## Technical Requirements

The Kubernetes API approach requires:

- **Standard shell** in the target container (typically `/bin/sh` or `/bin/bash`)
- Command execution capability in the target container
- Proper RBAC permissions to execute commands in containers
- Access to the Kubernetes API server

## Environment Requirements

- **Kubernetes Cluster**: Any version of Kubernetes is supported
- **kubectl**: For script-based scanning
- **CINC Auditor/InSpec**: For executing compliance controls
- **Kubeconfig**: Properly configured for cluster access

## Container Requirements

- **Shell Access**: Target container must have a shell
- **Command Execution**: Target container must allow command execution
- **Standard Utilities**: Many InSpec resources rely on standard commands (`ps`, `ls`, etc.)

## Known Limitations

### Distroless Containers

The primary limitation is with distroless containers, which:

- Lack a shell (`/bin/sh` or `/bin/bash`)
- Don't have standard utilities
- Cannot execute arbitrary commands

For distroless containers, consider:

- [Debug Container Approach](../debug-container/index.md) as an interim solution
- [Sidecar Container Approach](../sidecar-container/index.md) as an alternative
- Wait for the planned distroless support in the train-k8s-container plugin

### Windows Containers

- Limited support for Windows containers
- Requires Windows-specific profiles
- Command execution may work differently than in Linux containers

### Container Security Constraints

Containers with certain security constraints may not work:

- Containers running without shell access
- Containers with AppArmor/SELinux profiles that block command execution
- Containers with restricted capabilities

### Network Considerations

- Requires network access to the Kubernetes API server
- May be impacted by network policies restricting pod communication
- Can be affected by firewall rules between scanning client and Kubernetes API

## Workarounds for Limitations

### For Distroless Containers

1. **Short-Term**: Use the Debug Container or Sidecar Container approach
2. **Long-Term**: Monitor project progress for native distroless container support

### For Network Restrictions

1. **API Access**: Ensure network policies allow access to the Kubernetes API
2. **Proxy Configuration**: Configure kubectl to use appropriate proxy settings if required
3. **VPN/Tunnel**: Set up secure tunneling if operating across network boundaries

## Planned Solutions

Work is in progress to address these limitations:

1. **Enhanced Plugin**: Modifying the train-k8s-container plugin to support distroless containers
2. **Special Handlers**: Creating special resource handlers for non-standard containers
3. **Alternative Access Methods**: Developing alternative filesystem access methods

## Compatibility Matrix

| Container Type | Compatible | Notes |
|----------------|------------|-------|
| Standard Linux containers | ✅ Yes | Fully supported |
| Alpine containers | ✅ Yes | Requires sh shell (default in Alpine) |
| Minimal containers | ✅ Yes | As long as they have a shell |
| Distroless containers | ❌ No | Currently unsupported, in development |
| Windows containers | ⚠️ Limited | Limited functionality |
| Secure sandbox containers | ⚠️ Limited | Depends on security constraints |

## Performance Considerations

The Kubernetes API approach may have performance limitations:

- **Command Round-Trips**: Each command requires a round-trip to the Kubernetes API
- **Large File Transfers**: Reading large files via exec can be slow
- **API Rate Limiting**: Possible API server rate limiting on high-volume scanning

## Related Resources

- [Debug Container Approach](../debug-container/index.md) - Alternative for distroless containers
- [Sidecar Container Approach](../sidecar-container/index.md) - Alternative universal approach
- [Approach Comparison](../comparison.md) - Compare approaches for different scenarios
- [Future Work](../../project/roadmap.md) - Planned enhancements to address limitations
