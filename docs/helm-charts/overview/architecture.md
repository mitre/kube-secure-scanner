# Helm Chart Architecture

!!! info "Directory Context"
    This document is part of the [Overview Directory](index.md). See the [Overview Directory Inventory](inventory.md) for related resources.

## Chart Relationship Diagram

```mermaid
graph TD
    subgraph "Core Infrastructure"
        A[scanner-infrastructure] --> A1[RBAC]
        A --> A2[Service Accounts]
        A --> A3[Token Management]
        A --> A4[Namespace]
    end
    
    subgraph "Common Components"
        B[common-scanner] --> B1[Scanning Scripts]
        B --> B2[SAF CLI Integration]
        B --> B3[Threshold Configuration]
    end
    
    subgraph "Scanning Approaches"
        C[standard-scanner] --> C1[Kubernetes API Scanning]
        D[distroless-scanner] --> D1[Debug Container Scanning]
        E[sidecar-scanner] --> E1[Sidecar Container Scanning]
    end
    
    A --> B
    B --> C
    B --> D
    B --> E

    classDef core fill:#f9f,stroke:#333,stroke-width:2px
    classDef common fill:#bbf,stroke:#333,stroke-width:2px
    classDef scanning fill:#bfb,stroke:#333,stroke-width:2px
    
    class A,A1,A2,A3,A4 core
    class B,B1,B2,B3 common
    class C,C1,D,D1,E,E1 scanning
```

## Layered Architecture

Our Helm charts follow a layered architecture pattern with three distinct layers:

1. **Core Infrastructure Layer** (scanner-infrastructure)
   - Foundation for all scanning operations
   - RBAC and security model implementation
   - Service account and access control
   - Namespace management

2. **Common Components Layer** (common-scanner)
   - Reusable scanning utilities and scripts
   - SAF CLI integration for compliance validation
   - Threshold configuration for pass/fail criteria
   - Results processing and reporting

3. **Scanning Approaches Layer** (approach-specific charts)
   - Specialized components for each scanning approach
   - Test pods for demonstration and validation
   - Approach-specific configurations
   - Usage examples

## Value Flow

Values flow through the chart hierarchy, allowing configuration at multiple levels:

```mermaid
graph TD
    A[User Values] --> B[standard-scanner Values]
    B --> C[common-scanner Values]
    C --> D[scanner-infrastructure Values]
    D --> E[Final Configuration]
```

This allows:
- Global values set at top level
- Approach-specific overrides
- Component-specific settings
- Local environment customization

## Deployment Flow

The typical deployment flow involves these steps:

```mermaid
sequenceDiagram
    participant User
    participant Helm
    participant K8s as Kubernetes
    participant Scanner
    
    User->>Helm: Install Chart
    Helm->>K8s: Create Resources
    User->>K8s: Generate Tokens
    User->>Scanner: Run Scan
    Scanner->>K8s: Access Container
    Scanner->>User: Return Results
```

1. User installs Helm chart
2. Helm creates Kubernetes resources
3. User generates short-lived tokens
4. User runs scanning operation
5. Scanner accesses container via K8s API
6. Results returned to user

## Integration Points

Our charts provide integration points with external systems:

```mermaid
graph TD
    subgraph "Integration Points"
        Charts[Helm Charts] --> CI[CI/CD Systems]
        Charts --> SM[Secret Management]
        Charts --> LO[Logging/Monitoring]
        Charts --> CMDB[CMDB/Inventory]
    end
```

Key integration points:
- **CI/CD Systems**: Pipeline integration
- **Secret Management**: External secrets for tokens
- **Logging/Monitoring**: Result tracking and alerting
- **CMDB/Inventory**: Asset tracking and management

## Chart Dependencies

Formal Helm chart dependencies are defined in Chart.yaml files:

| Chart | Dependencies |
|-------|-------------|
| scanner-infrastructure | None |
| common-scanner | scanner-infrastructure |
| standard-scanner | common-scanner |
| distroless-scanner | common-scanner |
| sidecar-scanner | common-scanner |

These dependencies ensure proper installation order and value inheritance.