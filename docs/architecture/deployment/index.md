# Deployment Architectures

This section provides detailed information about the different deployment architectures supported by the Kubernetes CINC Secure Scanner.

!!! info "Directory Contents"
    For a complete listing of all files in this section, see the [Deployment Documentation Inventory](inventory.md).

## Deployment Options

The scanning system can be deployed using several different architectures:

1. **Script-based Deployment** - Using shell scripts for direct execution
2. **Helm Chart Deployment** - Using Helm charts for production environments
3. **CI/CD Integration** - Embedded in CI/CD pipelines

## Common Deployment Characteristics

While specific implementations differ, all deployment architectures share these characteristics:

1. **Security-First Approach**: All deployments implement least-privilege access controls
2. **Modular Design**: Components can be deployed independently as needed
3. **Configuration Flexibility**: Extensive configuration options for all deployment types
4. **Cleanup Mechanisms**: Automatic cleanup of temporary resources
5. **Threshold Validation**: Integration with the MITRE SAF CLI for compliance validation

## Deployment Documentation

For detailed information about specific deployment architectures, see these documents:

- [Script Deployment](script-deployment.md) - Using shell scripts for direct execution
- [Helm Deployment](helm-deployment.md) - Using Helm charts for production environments
- [CI/CD Deployment](ci-cd-deployment.md) - Integrating with CI/CD pipelines

## Deployment Architecture Diagram

```mermaid
flowchart TD
    subgraph User["USER ENVIRONMENT"]
        direction TB
        scripts["Scanning Scripts"]
        helm["Helm Deployment"]
        cicd["CI/CD Integration"]
    end
    
    subgraph Kubernetes["KUBERNETES CLUSTER"]
        direction TB
        subgraph Resources["SCANNER RESOURCES"]
            components["Scanner Components"]
            rbac["RBAC Resources"]
            credentials["Credentials"]
        end
        
        subgraph Targets["TARGET RESOURCES"]
            containers["Target Containers"]
        end
    end
    
    subgraph Results["RESULTS PROCESSING"]
        reports["Compliance Reports"]
        thresholds["Threshold Validation"]
    end
    
    %% Component relationships
    User -->|deploys to| Kubernetes
    scripts -->|creates| Resources
    helm -->|installs| Resources
    cicd -->|manages| Resources
    Resources -->|scans| Targets
    Resources -->|produces| Results
    
    %% WCAG-compliant styling
    style User fill:none,stroke:#0066CC,stroke-width:4px
    style Kubernetes fill:none,stroke:#505050,stroke-width:4px
    style Resources fill:none,stroke:#DD6100,stroke-width:4px
    style Targets fill:none,stroke:#217645,stroke-width:4px
    style Results fill:none,stroke:#4C366B,stroke-width:4px
    
    %% Component styling
    style scripts fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style helm fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style cicd fill:#0066CC,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style components fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style rbac fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style credentials fill:#DD6100,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style containers fill:#217645,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style reports fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
    style thresholds fill:#4C366B,stroke:#FFFFFF,stroke-width:2px,color:#FFFFFF
```

## Next Steps

- Explore the [Component Architecture](../components/index.md) documentation
- Review the [Workflow Processes](../workflows/index.md) documentation
- See the [Integration Options](../integrations/index.md) documentation
