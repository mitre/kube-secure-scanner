# ASCII to Mermaid Diagram Conversion

This document demonstrates the conversion of ASCII diagrams to Mermaid diagrams for better visualization in the documentation.

## Example 1: Basic Workflow

### Original ASCII Diagram

```
+--------+     +---------------+     +----------------+
| Start  |---->| Create RBAC   |---->| Generate Token |
+--------+     +---------------+     +----------------+
                                           |
                                           v
+--------+     +---------------+     +----------------+
|  End   |<----| Run Results   |<----| Execute Scan   |
+--------+     +---------------+     +----------------+
```

### Converted Mermaid Diagram

```mermaid
flowchart LR
    A[Start] --> B[Create RBAC]
    B --> C[Generate Token]
    C --> D[Execute Scan]
    D --> E[Run Results]
    E --> F[End]
    
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style D fill:#bbf,stroke:#333,stroke-width:2px
    style F fill:#f9f,stroke:#333,stroke-width:2px
```

## Example 2: Container Relationships

### Original ASCII Diagram

```
+------------------------------------------+
| Pod                                      |
|  +-------------+     +---------------+   |
|  | Application |<--->| Sidecar       |   |
|  | Container   |     | Scanner       |   |
|  +-------------+     +---------------+   |
|         |                  |             |
|         v                  v             |
|  +-----------------------------------+   |
|  | Shared Process Namespace          |   |
|  +-----------------------------------+   |
+------------------------------------------+
```

### Converted Mermaid Diagram

```mermaid
flowchart TD
    subgraph Pod
        A[Application Container] <--> B[Sidecar Scanner]
        A --> C[Shared Process Namespace]
        B --> C
    end
    
    style A fill:#bbf,stroke:#333,stroke-width:2px
    style B fill:#bfb,stroke:#333,stroke-width:2px
    style C fill:#fbb,stroke:#333,stroke-width:2px
```

## Example 3: Approach Decision Tree

### Original ASCII Diagram

```
                 +------------------+
                 | Container Type?  |
                 +------------------+
                         |
          +--------------+---------------+
          |                              |
          v                              v
+------------------+            +------------------+
| Standard         |            | Distroless       |
+------------------+            +------------------+
          |                              |
          v                              v
+------------------+            +------------------+
| Kubernetes API   |            | Debug Available? |
| Approach         |            +------------------+
+------------------+                     |
                             +-----------+----------+
                             |                      |
                             v                      v
                    +------------------+   +------------------+
                    | Debug Container  |   | Sidecar         |
                    | Approach         |   | Approach        |
                    +------------------+   +------------------+
```

### Converted Mermaid Diagram

```mermaid
flowchart TD
    A{Container Type?} -->|Standard| B[Kubernetes API Approach]
    A -->|Distroless| C{Debug Available?}
    C -->|Yes| D[Debug Container Approach]
    C -->|No| E[Sidecar Approach]
    
    style A fill:#fbb,stroke:#333,stroke-width:2px
    style B fill:#bfb,stroke:#333,stroke-width:2px
    style C fill:#fbb,stroke:#333,stroke-width:2px
    style D fill:#bbf,stroke:#333,stroke-width:2px
    style E fill:#bbf,stroke:#333,stroke-width:2px
```

## Conversion Benefits

Converting ASCII diagrams to Mermaid offers several advantages:

1. **Improved readability** - Mermaid diagrams are more visually appealing and easier to read
2. **Theme compatibility** - Mermaid diagrams adapt to light/dark themes automatically
3. **Maintainability** - Mermaid syntax is more structured and easier to modify
4. **Interactive features** - Diagrams can be made interactive with clickable elements
5. **Consistency** - Unified diagram style across the documentation

## Conversion Process

When converting ASCII to Mermaid:

1. Identify the core elements and relationships in the ASCII diagram
2. Choose the appropriate Mermaid diagram type (flowchart, sequence, etc.)
3. Map each ASCII element to its Mermaid counterpart
4. Add styling to improve visual clarity
5. Test the diagram in both light and dark modes

## Example Syntax Comparison

### ASCII Syntax (difficult to maintain)

```
+--------+     +---------------+
| Start  |---->| Middle Step   |
+--------+     +---------------+
                      |
                      v
               +---------------+
               | End Step      |
               +---------------+
```

### Mermaid Syntax (structured and maintainable)

```
flowchart TD
    A[Start] --> B[Middle Step]
    B --> C[End Step]
    
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style C fill:#f9f,stroke:#333,stroke-width:2px
```

Which renders as:

```mermaid
flowchart TD
    A[Start] --> B[Middle Step]
    B --> C[End Step]
    
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style C fill:#f9f,stroke:#333,stroke-width:2px
```