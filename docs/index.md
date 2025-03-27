# Secure CINC Auditor Kubernetes Container Scanning

A comprehensive platform for securely scanning Kubernetes containers, including distroless containers, using CINC Auditor with least-privilege security controls.

*[CINC]: CINC Is Not Chef
*[SAF]: Security Automation Framework
*[RBAC]: Role-Based Access Control
*[K8s]: Kubernetes
*[API]: Application Programming Interface

## I am a

<div class="grid cards" markdown>

- :shield:{ .lg .middle } **Security Leader / Decision Maker**

    ---

    Resources for security leaders making technology decisions:

    - [Executive Summary](overview/executive-summary.md)
    - [Security Analysis](security/risk/index.md)
    - [Compliance Documentation](security/compliance/index.md)
    - [Enterprise Integration Analysis](overview/enterprise-integration-analysis.md)

- :material-shield-account:{ .lg .middle } **Security Professional / Compliance Officer**

    ---

    Detailed security guidance and compliance information:

    - [Security Overview](security/index.md)
    - [Security Principles](security/principles/index.md)
    - [Approach Security Comparison](security/compliance/approach-comparison.md)
    - [Compliance Frameworks](security/compliance/index.md)

- :octicons-terminal-24:{ .lg .middle } **DevOps Engineer / Implementer**

    ---

    Implementation guidance and CI/CD integration examples:

    - [Quick Start Guide](quickstart-guide.md)
    - [Approach Comparison](approaches/comparison.md)
    - [GitHub Actions Integration](integration/platforms/github-actions.md)
    - [GitLab CI Integration](integration/platforms/gitlab-ci.md)

- :material-strategy:{ .lg .middle } **Solution Architect**

    ---

    Technical architecture and design documentation:

    - [Technical Overview](overview/index.md)
    - [Architecture Diagrams](architecture/diagrams/index.md)
    - [Workflow Processes](architecture/workflows/index.md)
    - [Approach Decision Matrix](approaches/decision-matrix.md)

</div>

## Scanning Approaches

This project offers three distinct approaches for container scanning:

=== "Kubernetes API Approach (Recommended)"

    Direct API-based scanning using the train-k8s-container plugin. Most scalable solution with seamless integration.
    
    - Works with standard containers now
    - Universal solution once distroless support is complete
    - No configuration changes to existing pods
    
    [Learn More](approaches/kubernetes-api/index.md){: .md-button }

=== "Debug Container Approach"

    Uses ephemeral debug containers with chroot-based scanning for distroless containers.
    
    - Requires Kubernetes 1.16+ with ephemeral containers
    - Works with existing deployed containers
    - Good for testing environments
    
    [Learn More](approaches/debug-container/index.md){: .md-button }

=== "Sidecar Container Approach"

    CINC Auditor sidecar container with shared process namespace for any container type.
    
    - Works with any Kubernetes cluster
    - Universal compatibility
    - Must be deployed alongside target container
    
    [Learn More](approaches/sidecar-container/index.md){: .md-button }

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
[Site Index](site-index.md){: .md-button }

## Project Roadmap

Our active roadmap includes the following key initiatives:

<div class="grid cards" markdown>

- :material-table-lock:{ .lg .middle } **NSA/CISA Kubernetes Hardening Guide**

    ---

    Incorporate analysis and recommendations from the NSA/CISA Kubernetes Hardening Guide.
    
    - Analyze [official guidance](https://media.defense.gov/2022/Aug/29/2003066362/-1/-1/0/CTR_KUBERNETES_HARDENING_GUIDANCE_1.2_20220829.PDF)
    - Reference KubeArmor implementation examples
    - Map hardening requirements to our implementation

- :material-container-outline:{ .lg .middle } **Enhanced Container Support**

    ---

    Expand scanning capabilities to new container types.
    
    - Extend train-k8s-container plugin for distroless support
    - Improve scan performance for specialized containers

- :material-tools:{ .lg .middle } **Additional Security Tool Integration**

    ---

    Expand beyond CINC to integrate additional security scanning tools.
    
    - Anchore Grype integration for vulnerability scanning
    - Anchore Syft integration for SBOM generation
    - Evaluate additional security tools for inclusion

## Core Documentation

<div class="grid cards" markdown>

- :material-compare:{ .lg .middle } **Approach Comparison**

    ---

    Compare the three scanning approaches side-by-side

    [:octicons-arrow-right-24: View comparison](approaches/comparison.md)

- :material-chart-timeline-variant:{ .lg .middle } **Workflow Diagrams**

    ---

    Visual workflows for all scanning approaches

    [:octicons-arrow-right-24: View diagrams](architecture/diagrams/index.md)

- :material-shield-check:{ .lg .middle } **Security Analysis**

    ---

    Comprehensive security analysis with risk mitigation

    [:octicons-arrow-right-24: View analysis](security/risk/index.md)

- :material-matrix:{ .lg .middle } **Decision Matrix**

    ---

    Selection guide for the right approach

    [:octicons-arrow-right-24: View matrix](approaches/decision-matrix.md)

</div>
