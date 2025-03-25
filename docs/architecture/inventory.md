# Architecture & Workflows Documentation Inventory

This directory contains documentation about the architecture, components, workflows, diagrams, deployment options, and integrations for the Secure CINC Auditor Kubernetes Container Scanning solution.

## Contents

### Components
- [Components Overview](components/index.md) - Core architectural components
- [Components Inventory](components/inventory.md) - Components documentation inventory
- [Core Components](components/core-components.md) - Details of main system components
- [Security Components](components/security-components.md) - Security-focused components
- [Communication Patterns](components/communication.md) - Component communication patterns

### Workflows
- [Workflows Overview](workflows/index.md) - End-to-end workflow processes
- [Workflows Inventory](workflows/inventory.md) - Workflows documentation inventory
- [Standard Container Workflow](workflows/standard-container.md) - Workflow for standard containers
- [Distroless Container Workflow](workflows/distroless-container.md) - Workflow for distroless containers
- [Sidecar Container Workflow](workflows/sidecar-container.md) - Workflow using sidecar approach
- [Security Workflows](workflows/security-workflows.md) - Security-focused workflows

### Diagrams
- [Diagrams Overview](diagrams/index.md) - WCAG-compliant architecture diagrams
- [Diagrams Inventory](diagrams/inventory.md) - Diagrams documentation inventory
- [Component Diagrams](diagrams/component-diagrams.md) - Component visualization diagrams
- [Workflow Diagrams](diagrams/workflow-diagrams.md) - Workflow visualization diagrams
- [Deployment Diagrams](diagrams/deployment-diagrams.md) - Deployment visualization diagrams

### Deployment
- [Deployment Overview](deployment/index.md) - Deployment architecture options
- [Deployment Inventory](deployment/inventory.md) - Deployment documentation inventory
- [Script Deployment](deployment/script-deployment.md) - Script-based deployment architecture
- [Helm Deployment](deployment/helm-deployment.md) - Helm chart deployment architecture
- [CI/CD Deployment](deployment/ci-cd-deployment.md) - CI/CD integration deployment architecture

### Integrations
- [Integrations Overview](integrations/index.md) - CI/CD integration architecture
- [Integrations Inventory](integrations/inventory.md) - Integrations documentation inventory
- [GitHub Actions Integration](integrations/github-actions.md) - GitHub Actions integration architecture
- [GitLab CI Integration](integrations/gitlab-ci.md) - GitLab CI integration architecture
- [GitLab Services Integration](integrations/gitlab-services.md) - GitLab Services integration architecture
- [Custom Integrations](integrations/custom-integrations.md) - Custom integration architecture

## Overview

The architecture documentation provides a comprehensive understanding of how the scanning system is designed, how the components interact, and the various workflows supported by the system. This information is valuable for both users seeking to understand how the system operates and for developers looking to extend or modify the system.

The documentation uses Mermaid diagrams extensively to visualize complex architectures, workflows, and system interactions, making it easier to understand the relationships between different components.