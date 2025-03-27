# Architecture Diagrams

This section provides WCAG-compliant Mermaid diagrams that visualize key aspects of the Kubernetes CINC Secure Scanner architecture.

!!! info "Directory Contents"
    For a complete listing of all files in this section, see the [Diagrams Documentation Inventory](inventory.md).

## Diagram Types

The architecture diagrams are organized into the following categories:

1. **Component Diagrams** - Visualizing system components and their relationships
2. **Workflow Diagrams** - Illustrating end-to-end workflow processes
3. **Deployment Diagrams** - Showing different deployment architectures

## Diagram Standards

All diagrams follow these standards:

- **WCAG Compliance**: Colors chosen for accessibility
- **Consistent Styling**: Uniform node and edge styles
- **Clarity**: Clear labels and relationships
- **Light/Dark Mode Support**: Visibility in both light and dark themes
- **Mermaid Syntax**: Using Mermaid for rendering in GitHub and MkDocs

## Sample Component Diagram

```mermaid
flowchart TD
    subgraph MiniKubeCluster["MINIKUBE CLUSTER"]
        direction TB
        subgraph ControlNode["CONTROL NODE"]
            direction TB
            apiserver["kube-apiserver"]
            etcd["etcd"]
        end
        
        subgraph WorkerNode1["WORKER NODE 1"]
            direction TB
            containers["Target Containers"]
            scanner_pods["Scanner Pods"]
        end
        
        subgraph WorkerNode2["WORKER NODE 2"]
            direction TB
            debug_containers["Debug Containers"]
            sidecar_pods["Sidecar Pods"]
        end
    end
    
    MiniKubeCluster --- cinc["CINC Profiles\n(Compliance Controls)"]
    MiniKubeCluster --- rbac["Service Accounts\nand RBAC\n(Access Control)"]
    MiniKubeCluster --- saf["SAF CLI\n(Reporting &\nThresholds)"]
    
    %% WCAG-compliant styling for subgraph labels - works in both light/dark
    style MiniKubeCluster fill:none,stroke:#505050,stroke-width:4px
    style ControlNode fill:none,stroke:#0066CC,stroke-width:4px
    style WorkerNode1 fill:none,stroke:#0066CC,stroke-width:4px
    style WorkerNode2 fill:none,stroke:#0066CC,stroke-width:4px
    
    %% Component styling
    style apiserver fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style etcd fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style containers fill:#505050,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style scanner_pods fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style debug_containers fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style sidecar_pods fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cinc fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style saf fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Diagram Documentation

For detailed diagrams of specific aspects of the architecture, see these documents:

- [Component Diagrams](component-diagrams.md) - Visualization of system components
- [Workflow Diagrams](workflow-diagrams.md) - Visualization of workflow processes
- [Deployment Diagrams](deployment-diagrams.md) - Visualization of deployment architectures

## Next Steps

- Explore the [Component Architecture](../components/index.md) documentation
- Review the [Workflow Processes](../workflows/index.md) documentation
- See the [Deployment Options](../deployment/index.md) documentation
