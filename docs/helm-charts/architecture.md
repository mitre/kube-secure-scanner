# Helm Chart Architecture

This document provides a detailed overview of the architecture, relationships, and design principles of our Helm charts for Kubernetes container scanning.

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

## Component Details

### scanner-infrastructure

The scanner-infrastructure chart creates the foundational security components:

```mermaid
graph TD
    subgraph "scanner-infrastructure"
        SA[Service Account] --> RB[Role Binding]
        R[Role] --> RB
        N[Namespace] --> SA
        CM[ConfigMap: Scripts] --> SA
    end
```

Key components:
- **Namespace**: Isolated environment for scanning operations
- **Service Account**: Identity for scanning operations
- **Role**: Defines permissions needed for scanning
- **RoleBinding**: Associates role with service account
- **ConfigMap: Scripts**: Helper scripts for token generation

### common-scanner

The common-scanner chart provides shared components for scanning operations:

```mermaid
graph TD
    subgraph "common-scanner"
        SCS[ConfigMap: Scanning Scripts] --> SAFC[SAF CLI Integration]
        TC[ConfigMap: Thresholds] --> SAFC
    end
```

Key components:
- **ConfigMap: Scanning Scripts**: CINC Auditor execution scripts
- **ConfigMap: Thresholds**: Compliance threshold configuration
- **SAF CLI Integration**: MITRE SAF CLI integration for results processing

### standard-scanner (Kubernetes API Approach)

The standard-scanner chart implements the Kubernetes API Approach:

```mermaid
graph TD
    subgraph "standard-scanner"
        TP[Test Pod] --> CINC[CINC Auditor]
        CINC --> K8S[Kubernetes API]
        K8S --> TCP[Target Container Pod]
    end
```

Key components:
- **Test Pod**: Demo pod for validation
- **CINC Auditor**: Execution via train-k8s-container transport
- **Kubernetes API**: Direct interaction with target containers

### distroless-scanner (Debug Container Approach)

The distroless-scanner chart implements the Debug Container Approach:

```mermaid
graph TD
    subgraph "distroless-scanner"
        TP[Test Pod: Distroless] --> DC[Debug Container]
        DC --> FS[Filesystem Access]
        FS --> TCP[Target Container]
    end
```

Key components:
- **Test Pod: Distroless**: Demo distroless container
- **Debug Container**: Ephemeral container for scanning
- **Filesystem Access**: Access to target container's filesystem

### sidecar-scanner (Sidecar Container Approach)

The sidecar-scanner chart implements the Sidecar Container Approach:

```mermaid
graph TD
    subgraph "sidecar-scanner"
        TP[Pod with Two Containers] --> TC[Target Container]
        TP --> SC[Scanner Sidecar]
        SC --> SH[Shared Process Namespace]
        SH --> TC
    end
```

Key components:
- **Pod with Two Containers**: Combined target and scanner
- **Target Container**: Application container to scan
- **Scanner Sidecar**: Container with CINC Auditor
- **Shared Process Namespace**: Access between containers

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

## Security Model

The security model is implemented across all chart layers:

```mermaid
graph TD
    subgraph "Security Implementation"
        LP[Least Privilege] --> RBAC[RBAC Controls]
        RBAC --> SA[Service Account]
        SA --> TK[Short-lived Tokens]
        NS[Namespace Isolation] --> RBAC
    end
```

Key security features:
- **Least Privilege**: Minimal permissions required
- **RBAC Controls**: Fine-grained access control
- **Service Account**: Dedicated identity for scanning
- **Short-lived Tokens**: Time-limited access
- **Namespace Isolation**: Segmentation by namespace

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