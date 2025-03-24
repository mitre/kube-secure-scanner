# Secure CINC Auditor Kubernetes Container Scanning

A comprehensive platform for securely scanning Kubernetes containers, including distroless containers, using CINC Auditor with least-privilege security controls.

*[CINC]: CINC Is Not Chef
*[SAF]: Security Automation Framework
*[RBAC]: Role-Based Access Control
*[K8s]: Kubernetes
*[API]: Application Programming Interface

## I am a...

<div class="grid cards" markdown>

-   :shield:{ .lg .middle } **Security Leader / Decision Maker**

    ---

    Resources for security leaders making technology decisions:
    
    - [Executive Summary](overview/executive-summary.md)
    - [Security Analysis](security/analysis.md)
    - [Compliance Documentation](security/compliance.md)
    - [Enterprise Integration Analysis](overview/enterprise-integration-analysis.md)

-   :octicons-terminal-24:{ .lg .middle } **DevOps Engineer / Implementer**

    ---
    
    Implementation guidance and CI/CD integration examples:
    
    - [Quick Start Guide](quickstart-guide.md)
    - [Approach Comparison](approaches/comparison.md)
    - [GitHub Actions Integration](integration/github-actions.md)
    - [GitLab CI Integration](integration/gitlab.md)

-   :material-strategy:{ .lg .middle } **Solution Architect**

    ---
    
    Technical architecture and design documentation:
    
    - [Technical Overview](overview/index.md)
    - [Architecture Diagrams](architecture/diagrams.md)
    - [Workflow Processes](architecture/workflows.md)
    - [Approach Decision Matrix](approaches/decision-matrix.md)

</div>

## Scanning Approaches

This project offers three distinct approaches for container scanning:

=== "Kubernetes API Approach (Recommended)"

    Direct API-based scanning using the train-k8s-container plugin. Most scalable solution with seamless integration.
    
    - Works with standard containers now
    - Universal solution once distroless support is complete
    - No configuration changes to existing pods
    
    [Learn More](approaches/kubernetes-api.md){: .md-button }

=== "Debug Container Approach"

    Uses ephemeral debug containers with chroot-based scanning for distroless containers.
    
    - Requires Kubernetes 1.16+ with ephemeral containers
    - Works with existing deployed containers
    - Good for testing environments
    
    [Learn More](approaches/debug-container.md){: .md-button }

=== "Sidecar Container Approach"

    CINC Auditor sidecar container with shared process namespace for any container type.
    
    - Works with any Kubernetes cluster
    - Universal compatibility
    - Must be deployed alongside target container
    
    [Learn More](approaches/sidecar-container.md){: .md-button }

## Key Security Benefits

<div class="grid" markdown>

- :material-shield-lock:{ .lg .middle } **Least Privilege Access**  
  Restrict scanning to specific containers only

- :material-transit-connection-variant:{ .lg .middle } **Dynamic Access Control**  
  Create temporary, targeted access for scanning

- :material-timer-sand:{ .lg .middle } **Time-limited Tokens**  
  Default 15-minute lifetime for security

- :material-wall:{ .lg .middle } **Namespace Isolation**  
  Contain permissions within specific namespaces

- :material-check-circle-outline:{ .lg .middle } **SAF CLI Integration**  
  Validate scan results against compliance thresholds

</div>

## Getting Started

The fastest way to get started is with our Quick Start guide:

[Quick Start Guide](quickstart-guide.md){: .md-button .md-button--primary }

## Core Documentation

<div class="grid cards" markdown>

-   :material-compare:{ .lg .middle } **Approach Comparison**

    ---
    
    Compare the three scanning approaches side-by-side
    
    [:octicons-arrow-right-24: View comparison](approaches/comparison.md)

-   :material-chart-timeline-variant:{ .lg .middle } **Workflow Diagrams**

    ---
    
    Visual workflows for all scanning approaches
    
    [:octicons-arrow-right-24: View diagrams](architecture/diagrams.md)

-   :material-shield-check:{ .lg .middle } **Security Analysis**

    ---
    
    Comprehensive security analysis with risk mitigation
    
    [:octicons-arrow-right-24: View analysis](security/analysis.md)

-   :material-matrix:{ .lg .middle } **Decision Matrix**

    ---
    
    Selection guide for the right approach
    
    [:octicons-arrow-right-24: View matrix](approaches/decision-matrix.md)

</div>