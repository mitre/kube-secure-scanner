# Workflow Diagrams

This document provides workflow diagrams to help visualize the scanning process and approaches used in the Kubernetes CINC Secure Scanner. The diagrams are created using Mermaid syntax and can be rendered in GitHub and GitLab markdown viewers.

## Standard Container Scanning Workflow

```mermaid
flowchart TD
    A[Start] --> B[Create Minimal RBAC]
    B --> C[Generate Short-lived Token]
    C --> D[Create Scanner Kubeconfig]
    D --> E[Run CINC Auditor Scan]
    E --> F[Generate Reports]
    F --> G[Validate Against Thresholds]
    G --> H[Cleanup Resources]
    H --> I[End]

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#bbf,stroke:#333,stroke-width:2px
    style G fill:#bfb,stroke:#333,stroke-width:2px
    style I fill:#f9f,stroke:#333,stroke-width:2px
```

## Distroless Container Scanning Approaches

### Approach 1: Modified Transport Plugin

This approach involves modifying the train-k8s-container plugin to support distroless containers by detecting when standard commands are unavailable and using alternative methods.

```mermaid
flowchart TD
    A[Start] --> B[Create Minimal RBAC]
    B --> C[Generate Short-lived Token]
    C --> D[Create Scanner Kubeconfig]
    D --> E[Run CINC Auditor with Modified Plugin]
    E --> F1{Commands Available?}
    F1 -->|Yes| G1[Use Standard Commands]
    F1 -->|No| H1[Use Alternative Approaches]
    G1 --> I[Execute Controls]
    H1 --> I
    I --> J[Generate Reports]
    J --> K[Validate Against Thresholds]
    K --> L[Cleanup Resources]
    L --> M[End]

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#bbf,stroke:#333,stroke-width:2px
    style F1 fill:#fbb,stroke:#333,stroke-width:2px
    style K fill:#bfb,stroke:#333,stroke-width:2px
    style M fill:#f9f,stroke:#333,stroke-width:2px
```

### Approach 2: Debug Container with CINC Auditor

This approach involves creating a debug container that mounts the target container's filesystem and scans it using chroot.

```mermaid
flowchart TD
    A[Start] --> B[Create Minimal RBAC]
    B --> C[Generate Short-lived Token]
    C --> D[Create Scanner Kubeconfig]
    D --> E[Deploy Debug Container]
    E --> F[Mount Target Filesystem]
    F --> G[Run CINC Auditor in Debug Container]
    G --> H[Chroot into Target Filesystem]
    H --> I[Execute Controls]
    I --> J[Bridge Results to Host]
    J --> K[Generate Reports]
    K --> L[Validate Against Thresholds]
    L --> M[Cleanup Resources]
    M --> N[End]

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style E fill:#bbf,stroke:#333,stroke-width:2px
    style G fill:#bbf,stroke:#333,stroke-width:2px
    style L fill:#bfb,stroke:#333,stroke-width:2px
    style N fill:#f9f,stroke:#333,stroke-width:2px
```

## CI/CD Integration Workflow

```mermaid
flowchart TD
    A[Start CI/CD Pipeline] --> B[Deploy Test Container]
    B --> C[Create Minimal RBAC]
    C --> D[Generate Short-lived Token]
    D --> E[Create Scanner Kubeconfig]
    E --> F{Container Type}
    F -->|Standard| G1[Run Standard Scan]
    F -->|Distroless| G2[Run Distroless Scan]
    G1 --> H[Generate Reports]
    G2 --> H
    H --> I[Validate Against Thresholds]
    I --> J{Threshold Met?}
    J -->|Yes| K[Mark as Passed]
    J -->|No| L[Mark as Failed]
    K --> M[Cleanup Resources]
    L --> M
    M --> N[End Pipeline]

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style F fill:#fbb,stroke:#333,stroke-width:2px
    style J fill:#fbb,stroke:#333,stroke-width:2px
    style K fill:#bfb,stroke:#333,stroke-width:2px
    style L fill:#fbb,stroke:#333,stroke-width:2px
    style N fill:#f9f,stroke:#333,stroke-width:2px
```

## Minikube Setup and Scanning Workflow

This diagram shows the complete workflow from setting up a Minikube environment to scanning containers.

```mermaid
flowchart TD
    A[Start] --> B[Run setup-minikube.sh]
    B --> C{With Distroless Flag?}
    
    C -->|No| D1[Create Standard Minikube Cluster]
    C -->|Yes| D2[Create Minikube with Distroless Support]
    
    D1 --> E1[Deploy Standard RBAC]
    D2 --> E2[Deploy Extended RBAC with Ephemeral Container Support]
    
    E1 --> F1[Deploy Test Containers]
    E2 --> F2[Deploy Test Containers + Distroless Containers]
    
    F1 --> G1[Generate Scanner Kubeconfig]
    F2 --> G2[Generate Scanner Kubeconfig]
    
    G1 --> H1[Run scan-container.sh]
    G2 --> H2{Container Type?}
    
    H2 -->|Standard| H3[Run scan-container.sh]
    H2 -->|Distroless| H4[Run scan-distroless-container.sh]
    
    H1 --> I1[Generate Reports]
    H3 --> I1
    H4 --> I1
    
    I1 --> J[Validate with SAF-CLI]
    J --> K[Clean Up Resources]
    K --> L[End]

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style B fill:#bbf,stroke:#333,stroke-width:2px
    style C fill:#fbb,stroke:#333,stroke-width:2px
    style H2 fill:#fbb,stroke:#333,stroke-width:2px
    style J fill:#bfb,stroke:#333,stroke-width:2px
    style L fill:#f9f,stroke:#333,stroke-width:2px
```

## CINC Auditor Sidecar Container Approach

This diagram shows how a CINC Auditor sidecar container could be implemented for scanning.

```mermaid
flowchart TD
    A[Start] --> B[Deploy Pod with Sidecar]
    
    subgraph "Target Pod"
    C1[Target Container]
    C2[CINC Auditor Sidecar]
    end
    
    B --> D[Mount Shared Volume]
    D --> E[Share Process Namespace]
    E --> F[Run CINC Auditor in Sidecar]
    F --> G[Access Target Filesystem via /proc]
    G --> H[Execute Compliance Controls]
    H --> I[Write Results to Shared Volume]
    I --> J[Container or Scheduler Retrieves Results]
    J --> K[Generate Reports]
    K --> L[Validate Against Thresholds]
    L --> M[End]

    C1 --- C2

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style C1 fill:#fbb,stroke:#333,stroke-width:2px
    style C2 fill:#bbf,stroke:#333,stroke-width:2px
    style F fill:#bbf,stroke:#333,stroke-width:2px
    style L fill:#bfb,stroke:#333,stroke-width:2px
    style M fill:#f9f,stroke:#333,stroke-width:2px
```

## GitHub Actions Workflow

This diagram shows a detailed GitHub Actions workflow for container scanning.

```mermaid
flowchart TD
    A[Start GitHub Action] --> B[Check Out Code]
    
    B --> C[Setup Minikube Cluster]
    C --> D[Deploy RBAC Resources]
    D --> E[Build and Deploy Test Containers]
    
    E --> F{Container Type Decision}
    F -->|Standard| G1[Run Standard Scan Job]
    F -->|Distroless| G2[Run Distroless Scan Job]
    
    subgraph "Standard Scan Job"
    H1[Generate Scanner Kubeconfig]
    H1 --> I1[Execute CINC Auditor]
    I1 --> J1[Process Results]
    end
    
    subgraph "Distroless Scan Job"
    H2[Generate Scanner Kubeconfig]
    H2 --> I2[Deploy Debug Container]
    I2 --> J2[Execute CINC in Debug Container]
    J2 --> K2[Process Results]
    end
    
    G1 --> H1
    G2 --> H2
    
    J1 --> L[Validate Results Against Threshold]
    K2 --> L
    
    L --> M{Threshold Met?}
    M -->|Yes| N1[Mark Step as Successful]
    M -->|No| N2[Mark Step as Failed]
    
    N1 --> O[Clean Up Resources]
    N2 --> O
    O --> P[Upload Results as Artifacts]
    P --> Q[End GitHub Action]

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style F fill:#fbb,stroke:#333,stroke-width:2px
    style M fill:#fbb,stroke:#333,stroke-width:2px
    style N1 fill:#bfb,stroke:#333,stroke-width:2px
    style N2 fill:#fbb,stroke:#333,stroke-width:2px
    style Q fill:#f9f,stroke:#333,stroke-width:2px
```

## GitLab CI Integration with Services

This diagram shows how GitLab CI Services could be integrated into our scanning workflow.

```mermaid
flowchart TD
    A[Start GitLab CI Pipeline] --> B[Deploy Target Container]
    
    subgraph "GitLab CI Services"
    S1[CINC Auditor Service]
    S2[SAF CLI Service]
    end
    
    B --> C[Create Minimal RBAC]
    C --> D[Generate Short-lived Token]
    D --> E[Create Scanner Kubeconfig]
    E --> F[Run Scan Job]
    
    S1 --> F
    S2 --> F
    
    F --> G[Generate Reports]
    G --> H[Validate Against Thresholds]
    H --> I{Threshold Met?}
    I -->|Yes| J[Mark as Passed]
    I -->|No| K[Mark as Failed]
    J --> L[Cleanup Resources]
    K --> L
    L --> M[End Pipeline]

    style A fill:#f9f,stroke:#333,stroke-width:2px
    style S1 fill:#bbf,stroke:#333,stroke-width:2px
    style S2 fill:#bbf,stroke:#333,stroke-width:2px
    style I fill:#fbb,stroke:#333,stroke-width:2px
    style J fill:#bfb,stroke:#333,stroke-width:2px
    style K fill:#fbb,stroke:#333,stroke-width:2px
    style M fill:#f9f,stroke:#333,stroke-width:2px
```