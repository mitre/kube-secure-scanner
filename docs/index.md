# Kube Secure Scanner

<div style="padding: 1em; margin-bottom: 1em; background-color: rgba(0, 100, 200, 0.1); border-left: 4px solid #0066cc; border-radius: 4px;">
<h2 style="margin-top: 0; color: #0066cc;">Release Preview v0.90</h2>
<p>This is an ongoing joint community research effort and is currently at <strong>Release Preview (v0.90)</strong>. Some examples, automation, pipelines, and scripts are still in the process of being fully tested and validated. We'll be releasing updates in v0.9.x versions as we work toward a stable v1.0.0 release.</p>

<a href="https://github.com/mitre/kube-secure-scanner" class="md-button md-button--primary" target="_blank">View Project on GitHub ↗</a>
</div>

## Overview

A flexible, security-focused framework for scanning containers in Kubernetes environments with multiple scanning engines. Initially built with CINC Auditor (open source InSpec), the platform provides secure RBAC configurations, multiple scanning approaches, and comprehensive CI/CD integration.

<div class="grid" markdown>
<div markdown>
**Key Features:**
- Multiple scanner engine support (extensible framework)
- Three container scanning approaches for all Kubernetes environments
- Specialized security controls with least-privilege design
- Comprehensive documentation and integration examples
- CI/CD pipeline integration for GitHub Actions and GitLab
</div>
<div markdown>
**Quick Links:**
[Quick Start Guide](quickstart-guide.md){: .md-button .md-button--primary }
[Approach Comparison](approaches/comparison.md){: .md-button }
[GitHub Actions Integration](integration/platforms/github-actions.md){: .md-button }
[GitLab CI Integration](integration/platforms/gitlab-ci.md){: .md-button }
</div>
</div>

*[CINC]: CINC Is Not Chef
*[SAF]: Security Automation Framework
*[RBAC]: Role-Based Access Control
*[K8s]: Kubernetes
*[API]: Application Programming Interface

## Choose Your Path

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

This project offers three distinct approaches for container scanning, designed to accommodate various container types and Kubernetes environments:

=== "Kubernetes API Approach (Recommended)"

    Direct API-based scanning approach. Most scalable solution with seamless integration.
    
    - Works with standard containers now
    - Universal solution once distroless support is complete
    - No configuration changes to existing pods
    - Flexible scanner engine support (roadmap)
    
    [Learn More](approaches/kubernetes-api/index.md){: .md-button }

=== "Debug Container Approach"

    Uses ephemeral debug containers with chroot-based scanning for distroless containers.
    
    - Requires Kubernetes 1.16+ with ephemeral containers
    - Works with existing deployed containers
    - Good for testing environments
    - Compatible with multiple scanner engines
    
    [Learn More](approaches/debug-container/index.md){: .md-button }

=== "Sidecar Container Approach"

    Scanner sidecar container with shared process namespace for any container type.
    
    - Works with any Kubernetes cluster
    - Universal compatibility
    - Must be deployed alongside target container
    - Supports pluggable scanner engines
    
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

The fastest way to get started is with our Quick Start guide, which walks you through:
- Setting up a testing environment
- Deploying the scanning infrastructure
- Running container scans
- Validating compliance results

<div class="grid" markdown>
<div markdown>
[Quick Start Guide](quickstart-guide.md){: .md-button .md-button--primary }
[Site Index](site-index.md){: .md-button }
</div>
<div markdown>
[Security Overview](security/index.md){: .md-button }
[Documentation Map](site-index.md){: .md-button }
</div>
</div>

## Project Roadmap

Our active roadmap includes the following key initiatives for the path to v1.0:

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
    
    - Complete API-based direct scanning approach
    - Improve scan performance for specialized containers
    - Add universal distroless container support

- :material-tools:{ .lg .middle } **Multi-Scanner Engine Architecture**

    ---

    Implement framework for integrating multiple scanning engines:
    
    - Scanner engine plugin interface
    - Results normalization layer
    - Support for vulnerability scanners and SBOM generators
    - Scanner configuration standardization

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
