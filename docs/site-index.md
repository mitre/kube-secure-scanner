# Site Index

*A comprehensive index of all documentation in the Kube CINC Secure Scanner project.*

## Getting Started

<div class="grid cards" markdown>

- :material-book-open-outline:{ .lg .middle } **Introduction**

    ---

    - [Executive Summary](overview/executive-summary.md) - Brief overview for decision makers
    - [Quick Start Guide](quickstart-guide.md) - The fastest way to get up and running
    - [Technical Overview](overview/index.md) - High-level technical introduction

- :material-layers-outline:{ .lg .middle } **Core Concepts**

    ---

    - [Approach Comparison](approaches/comparison.md) - Side-by-side comparison of scanning methods
    - [Decision Matrix](approaches/decision-matrix.md) - Choose the right approach for your environment
    - [Security Principles](security/principles/index.md) - Core security design principles

</div>

## Approaches

=== "Kubernetes API Approach"

    !!! abstract "Standard Container Scanning"
        The Kubernetes API approach uses the train-k8s-container plugin to perform direct API-based scanning of containers.

    - [Overview](approaches/kubernetes-api/index.md) - Introduction to direct API scanning
    - [Implementation](approaches/kubernetes-api/implementation.md) - How to implement API-based scanning
    - [Limitations](approaches/kubernetes-api/limitations.md) - Current limitations
    - [RBAC Configuration](approaches/kubernetes-api/rbac.md) - Role-based access control setup

=== "Debug Container Approach"

    !!! abstract "Distroless Container Scanning"
        The Debug Container approach uses ephemeral debug containers to scan distroless containers.

    - [Overview](approaches/debug-container/index.md) - Introduction to debug container scanning
    - [Distroless Basics](approaches/debug-container/distroless-basics.md) - Understanding distroless containers
    - [Implementation](approaches/debug-container/implementation.md) - How to implement debug container scanning

=== "Sidecar Container Approach"

    !!! abstract "Universal Container Scanning"
        The Sidecar Container approach uses a shared process namespace to scan any container type.

    - [Overview](approaches/sidecar-container/index.md) - Introduction to sidecar container scanning
    - [Implementation](approaches/sidecar-container/implementation.md) - How to implement sidecar container scanning
    - [Pod Configuration](approaches/sidecar-container/pod-configuration.md) - Configure pods for sidecar scanning
    - [Retrieving Results](approaches/sidecar-container/retrieving-results.md) - Get scan results from sidecar containers

=== "Helper Scripts"

    !!! abstract "Scripted Automation"
        Helper scripts provide automated workflows to simplify scanner operations.

    - [Overview](approaches/helper-scripts/index.md) - Introduction to helper scripts
    - [Available Scripts](approaches/helper-scripts/available-scripts.md) - List of available scripts
    - [Scripts vs. Commands](approaches/helper-scripts/scripts-vs-commands.md) - When to use scripts vs. direct commands

## Architecture

### Components

- [Core Components](architecture/components/core-components.md) - Essential system components
- [Security Components](architecture/components/security-components.md) - Security-specific components
- [Communication](architecture/components/communication.md) - Component communication patterns

### Diagrams

- [Component Diagrams](architecture/diagrams/component-diagrams.md) - Visual component representations
- [Deployment Diagrams](architecture/diagrams/deployment-diagrams.md) - Deployment architecture
- [Workflow Diagrams](architecture/diagrams/workflow-diagrams.md) - Workflow visualizations

### Workflows

- [Standard Container](architecture/workflows/standard-container.md) - Standard container scanning workflow
- [Distroless Container](architecture/workflows/distroless-container.md) - Distroless container scanning workflow
- [Sidecar Container](architecture/workflows/sidecar-container.md) - Sidecar container scanning workflow
- [Security Workflows](architecture/workflows/security-workflows.md) - Security-focused workflows

### Deployment

- [Script Deployment](architecture/deployment/script-deployment.md) - Script-based deployment
- [Helm Deployment](architecture/deployment/helm-deployment.md) - Helm chart deployment
- [CI/CD Deployment](architecture/deployment/ci-cd-deployment.md) - CI/CD pipeline deployment

### Integrations

- [GitLab CI](architecture/integrations/gitlab-ci.md) - GitLab CI/CD integration
- [GitHub Actions](architecture/integrations/github-actions.md) - GitHub Actions integration
- [GitLab Services](architecture/integrations/gitlab-services.md) - GitLab Services integration
- [Custom Integrations](architecture/integrations/custom-integrations.md) - Building custom integrations

## Security

### Principles

- [Least Privilege](security/principles/least-privilege.md) - Implementing least privilege access
- [Ephemeral Credentials](security/principles/ephemeral-creds.md) - Using short-lived credentials
- [Resource Isolation](security/principles/resource-isolation.md) - Isolating security resources
- [Secure Transport](security/principles/secure-transport.md) - Secure data transfer

### Risk Analysis

- [Risk Model](security/risk/model.md) - Security risk model overview
- [Kubernetes API Risks](security/risk/kubernetes-api.md) - Kubernetes API approach risks
- [Debug Container Risks](security/risk/debug-container.md) - Debug container approach risks
- [Sidecar Container Risks](security/risk/sidecar-container.md) - Sidecar container approach risks
- [Mitigations](security/risk/mitigations.md) - Risk mitigation strategies

### Threat Model

- [Attack Vectors](security/threat-model/attack-vectors.md) - Potential attack vectors
- [Lateral Movement](security/threat-model/lateral-movement.md) - Preventing lateral movement
- [Token Exposure](security/threat-model/token-exposure.md) - Preventing token exposure
- [Threat Mitigations](security/threat-model/threat-mitigations.md) - Threat mitigation strategies

### Compliance

- [Approach Comparison](security/compliance/approach-comparison.md) - Security approach comparison
- [Risk Documentation](security/compliance/risk-documentation.md) - Documentation for compliance
- [CIS Benchmarks](security/compliance/cis-benchmarks.md) - CIS benchmark compliance
- [Kubernetes STIG](security/compliance/kubernetes-stig.md) - Kubernetes STIG compliance
- [DISA SRG](security/compliance/disa-srg.md) - DISA SRG compliance
- [DoD 8500.01](security/compliance/dod-8500-01.md) - DoD 8500.01 compliance

## Configuration

### Kubeconfig

- [Generation](configuration/kubeconfig/generation.md) - Generate kubeconfig files
- [Management](configuration/kubeconfig/management.md) - Manage kubeconfig files
- [Security](configuration/kubeconfig/security.md) - Secure kubeconfig files
- [Dynamic Configuration](configuration/kubeconfig/dynamic.md) - Dynamic kubeconfig generation

### Thresholds

- [Basic Configuration](configuration/thresholds/basic.md) - Basic threshold configuration
- [Advanced Configuration](configuration/thresholds/advanced.md) - Advanced threshold configuration
- [Example Configurations](configuration/thresholds/examples.md) - Threshold configuration examples
- [CI/CD Thresholds](configuration/thresholds/cicd.md) - CI/CD-specific thresholds

### Plugins

- [Distroless Support](configuration/plugins/distroless.md) - Distroless container support
- [Implementation](configuration/plugins/implementation.md) - Plugin implementation guide
- [Testing](configuration/plugins/testing.md) - Plugin testing guide

### Security Configuration

- [Hardening](configuration/security/hardening.md) - System hardening guide
- [Credentials](configuration/security/credentials.md) - Credential management
- [RBAC](configuration/security/rbac.md) - RBAC configuration guide

## Helm Charts

### Overview

- [Architecture](helm-charts/overview/architecture.md) - Helm chart architecture

### Scanner Types

- [Common Scanner](helm-charts/scanner-types/common-scanner.md) - Common scanner chart
- [Standard Scanner](helm-charts/scanner-types/standard-scanner.md) - Standard scanner chart
- [Distroless Scanner](helm-charts/scanner-types/distroless-scanner.md) - Distroless scanner chart
- [Sidecar Scanner](helm-charts/scanner-types/sidecar-scanner.md) - Sidecar scanner chart

### Infrastructure

- [RBAC](helm-charts/infrastructure/rbac.md) - RBAC configuration
- [Service Accounts](helm-charts/infrastructure/service-accounts.md) - Service account setup
- [Namespaces](helm-charts/infrastructure/namespaces.md) - Namespace management

### Usage

- [Configuration](helm-charts/usage/configuration.md) - Chart configuration
- [Customization](helm-charts/usage/customization.md) - Chart customization
- [Values](helm-charts/usage/values.md) - Values file reference

### Security

- [Best Practices](helm-charts/security/best-practices.md) - Helm chart security best practices
- [RBAC Hardening](helm-charts/security/rbac-hardening.md) - RBAC hardening for charts
- [Risk Assessment](helm-charts/security/risk-assessment.md) - Chart security risk assessment

### Operations

- [Troubleshooting](helm-charts/operations/troubleshooting.md) - Chart troubleshooting
- [Performance](helm-charts/operations/performance.md) - Performance optimization
- [Maintenance](helm-charts/operations/maintenance.md) - Chart maintenance

## Integration

### Platforms

- [GitHub Actions](integration/platforms/github-actions.md) - GitHub Actions integration
- [GitLab CI](integration/platforms/gitlab-ci.md) - GitLab CI integration
- [GitLab Services](integration/platforms/gitlab-services.md) - GitLab Services integration

### Workflows

- [Standard Container](integration/workflows/standard-container.md) - Standard container CI/CD workflows
- [Distroless Container](integration/workflows/distroless-container.md) - Distroless container CI/CD workflows
- [Sidecar Container](integration/workflows/sidecar-container.md) - Sidecar container CI/CD workflows
- [Security Workflows](integration/workflows/security-workflows.md) - Security-focused CI/CD workflows

### Examples

- [GitHub Examples](integration/examples/github-examples.md) - GitHub integration examples
- [GitLab Examples](integration/examples/gitlab-examples.md) - GitLab integration examples

### Configuration

- [Environment Variables](integration/configuration/environment-variables.md) - Environment variable configuration
- [Secrets Management](integration/configuration/secrets-management.md) - Secrets management in CI/CD
- [Thresholds Integration](integration/configuration/thresholds-integration.md) - Threshold integration in CI/CD
- [Reporting](integration/configuration/reporting.md) - CI/CD reporting configuration

## Tasks

<div class="grid cards" markdown>

- :material-docker:{ .lg .middle } **Container Scanning**

    ---

    Learn how to scan different types of containers:

    - [Standard Container Scan](tasks/standard-container-scan.md) - Scan standard containers
    - [Distroless Container Scan](tasks/distroless-container-scan.md) - Scan distroless containers
    - [Sidecar Container Scan](tasks/sidecar-container-scan.md) - Scan using sidecar containers

- :material-git:{ .lg .middle } **CI/CD Integration**

    ---

    Integrate scanning with your CI/CD pipelines:

    - [GitHub Integration](tasks/github-integration.md) - Integrate with GitHub Actions
    - [GitLab Integration](tasks/gitlab-integration.md) - Integrate with GitLab CI

- :material-kubernetes:{ .lg .middle } **Kubernetes Setup**

    ---

    Configure your Kubernetes environment:

    - [Kubernetes Setup](tasks/kubernetes-setup.md) - Set up Kubernetes environment
    - [RBAC Setup](tasks/rbac-setup.md) - Configure RBAC permissions

- :material-package-variant-closed:{ .lg .middle } **Deployment**

    ---

    Deploy the scanner infrastructure:

    - [Helm Deployment](tasks/helm-deployment.md) - Deploy using Helm charts
    - [Script Deployment](tasks/script-deployment.md) - Deploy using scripts

- :material-shield-lock:{ .lg .middle } **Security Configuration**

    ---

    Secure your scanner deployment:

    - [Token Management](tasks/token-management.md) - Manage access tokens
    - [Thresholds Configuration](tasks/thresholds-configuration.md) - Configure security thresholds

</div>

## Learning Paths

<div class="grid cards" markdown>

- :fontawesome-solid-user:{ .lg .middle } **For New Users**

    ---

    Start here if you're new to the project:

    [New Users Guide](learning-paths/new-users.md){ .md-button }

- :fontawesome-solid-shield-alt:{ .lg .middle } **Security-First Approach**

    ---

    Focus on security best practices:

    [Security-First Guide](learning-paths/security-first.md){ .md-button }

- :material-tools:{ .lg .middle } **Implementation Guide**

    ---

    Step-by-step implementation instructions:

    [Implementation Guide](learning-paths/implementation.md){ .md-button }

- :fontawesome-solid-book:{ .lg .middle } **Core Concepts**

    ---

    Understand the fundamental concepts:

    [Core Concepts Guide](learning-paths/core-concepts.md){ .md-button }

- :material-star:{ .lg .middle } **Advanced Features**

    ---

    Explore advanced capabilities:

    [Advanced Features Guide](learning-paths/advanced-features.md){ .md-button }

</div>

## Utilities and Tools

### Documentation Utilities

- [ASCII to Mermaid](utilities/ascii-to-mermaid.md) - Convert ASCII diagrams to Mermaid
- [MkDocs Link Fixer](utilities/mkdocs-link-fixer-proposal.md) - Fix MkDocs links

## Contributing

### Documentation

- [Documentation Tools](contributing/documentation-tools.md) - Documentation tooling
- [Code Snippets](contributing/code-snippets.md) - Code snippet guidance
- [Diagram Color Guide](contributing/diagram-color-guide.md) - Diagram color guidelines
- [STIG API Tools](contributing/stig-api-tools.md) - STIG API tooling

## Reference

### Examples

- [GitHub Workflow Examples](github-workflow-examples/index.md) - GitHub workflow examples
- [GitLab Pipeline Examples](gitlab-pipeline-examples/index.md) - GitLab pipeline examples
- [GitLab Services Examples](gitlab-services-examples/index.md) - GitLab services examples

### Project Information

- [Changelog](project/changelog.md) - Project changelog
- [Roadmap](project/roadmap.md) - Project roadmap
