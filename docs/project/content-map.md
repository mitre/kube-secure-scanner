# Documentation Structure and Content Map

This document provides a comprehensive overview of the documentation structure for the Kube CINC Secure Scanner project. It serves as a reference for the expected organization of our documentation.

## Top-Level Sections

Our documentation is organized into the following top-level sections:

1. **Getting Started** - Introduction and quickstart materials
2. **Core Concepts** - Architecture, approaches, and security principles
3. **Deployment & Configuration** - Setup, RBAC, config, and Helm charts
4. **CI/CD Integration** - Integrating with CI/CD systems
5. **Development** - Developer guide and contributing information
6. **Project Information** - Project management and meta-documentation

## Documentation Directory Structure

Below is the expected structure of our documentation with key files:

```
docs/
├── index.md                     # Main landing page
├── quickstart-guide.md          # Quick start guide
├── approaches/                  # Scanning approaches
│   ├── index.md                 # Approaches overview
│   ├── inventory.md             # Directory listing
│   ├── comparison.md            # Comparison of approaches
│   ├── decision-matrix.md       # Decision matrix for choosing approaches
│   ├── kubernetes-api/          # Kubernetes API approach
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── implementation.md    # Implementation details
│   │   ├── rbac.md              # RBAC configuration
│   │   └── limitations.md       # Limitations
│   ├── debug-container/         # Debug container approach
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── distroless-basics.md # Distroless container basics
│   │   └── implementation.md    # Implementation details
│   ├── sidecar-container/       # Sidecar container approach
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   └── implementation.md    # Implementation details
│   └── helper-scripts/          # Helper scripts approach
│       ├── index.md             # Overview
│       ├── inventory.md         # Directory listing
│       └── scripts-vs-commands.md # Scripts vs. Commands
├── architecture/                # Architecture documentation
│   ├── index.md                 # Architecture overview
│   ├── inventory.md             # Directory listing
│   ├── components/              # System components
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── core-components.md   # Core components
│   │   ├── communication.md     # Communication patterns
│   │   └── security-components.md # Security components
│   ├── diagrams/                # Architecture diagrams
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── component-diagrams.md # Component diagrams
│   │   ├── deployment-diagrams.md # Deployment diagrams
│   │   └── workflow-diagrams.md # Workflow diagrams
│   ├── workflows/               # Workflow documentation
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── standard-container.md # Standard container workflow
│   │   ├── distroless-container.md # Distroless container workflow
│   │   └── sidecar-container.md # Sidecar container workflow
│   ├── deployment/              # Deployment architecture
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── script-deployment.md # Script deployment
│   │   ├── helm-deployment.md   # Helm deployment
│   │   └── ci-cd-deployment.md  # CI/CD deployment
│   └── integrations/            # External integrations
│       ├── index.md             # Overview
│       ├── inventory.md         # Directory listing
│       ├── gitlab-ci.md         # GitLab CI integration
│       ├── github-actions.md    # GitHub Actions integration
│       ├── gitlab-services.md   # GitLab Services integration
│       └── custom-integrations.md # Custom integrations
├── configuration/               # Configuration documentation
│   ├── index.md                 # Configuration overview
│   ├── inventory.md             # Directory listing
│   ├── kubeconfig/              # Kubeconfig management
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── generation.md        # Generation of kubeconfig
│   │   ├── management.md        # Management of kubeconfig
│   │   ├── security.md          # Security considerations
│   │   └── dynamic.md           # Dynamic configuration
│   ├── thresholds/              # Threshold configuration
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── basic.md             # Basic configuration
│   │   ├── advanced.md          # Advanced configuration
│   │   ├── examples.md          # Example configurations
│   │   └── cicd.md              # CI/CD thresholds
│   ├── plugins/                 # Plugin configuration
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── distroless.md        # Distroless support
│   │   ├── implementation.md    # Implementation guide
│   │   └── testing.md           # Testing guide
│   ├── integration/             # Integration configuration
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── saf-cli.md           # SAF CLI integration
│   │   ├── github.md            # GitHub Actions config
│   │   └── gitlab.md            # GitLab CI config
│   └── security/                # Security configuration
│       ├── index.md             # Overview
│       ├── inventory.md         # Directory listing
│       ├── hardening.md         # Hardening guide
│       ├── credentials.md       # Credential management
│       └── rbac.md              # RBAC configuration
├── security/                    # Security documentation
│   ├── index.md                 # Security overview
│   ├── inventory.md             # Directory listing
│   ├── principles/              # Security principles
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── least-privilege.md   # Least privilege
│   │   ├── ephemeral-creds.md   # Ephemeral credentials
│   │   ├── resource-isolation.md # Resource isolation
│   │   └── secure-transport.md  # Secure transport
│   ├── risk/                    # Risk analysis
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── model.md             # Risk model
│   │   ├── kubernetes-api.md    # K8s API approach risks
│   │   ├── debug-container.md   # Debug container risks
│   │   ├── sidecar-container.md # Sidecar container risks
│   │   └── mitigations.md       # Risk mitigations
│   ├── threat-model/            # Threat model
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── attack-vectors.md    # Attack vectors
│   │   ├── lateral-movement.md  # Lateral movement
│   │   ├── token-exposure.md    # Token exposure
│   │   └── threat-mitigations.md # Threat mitigations
│   ├── compliance/              # Compliance documentation
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── approach-comparison.md # Approach comparison
│   │   └── risk-documentation.md # Risk documentation
│   └── recommendations/         # Security recommendations
│       ├── index.md             # Overview
│       └── inventory.md         # Directory listing
├── helm-charts/                 # Helm chart documentation
│   ├── index.md                 # Helm charts overview
│   ├── inventory.md             # Directory listing
│   ├── overview/                # Overview documentation
│   │   ├── index.md             # General overview
│   │   ├── inventory.md         # Directory listing
│   │   └── architecture.md      # Architecture
│   ├── scanner-types/           # Scanner types
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── common-scanner.md    # Common scanner
│   │   ├── standard-scanner.md  # Standard scanner
│   │   ├── distroless-scanner.md # Distroless scanner
│   │   └── sidecar-scanner.md   # Sidecar scanner
│   ├── infrastructure/          # Infrastructure
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── rbac.md              # RBAC configuration
│   │   ├── service-accounts.md  # Service accounts
│   │   └── namespaces.md        # Namespaces
│   ├── usage/                   # Usage documentation
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── customization.md     # Customization guide
│   │   ├── configuration.md     # Configuration reference
│   │   └── values.md            # Values files
│   ├── security/                # Security documentation
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── best-practices.md    # Best practices
│   │   ├── rbac-hardening.md    # RBAC hardening
│   │   └── risk-assessment.md   # Risk assessment
│   └── operations/              # Operations documentation
│       ├── index.md             # Overview
│       ├── inventory.md         # Directory listing
│       ├── troubleshooting.md   # Troubleshooting
│       ├── performance.md       # Performance
│       └── maintenance.md       # Maintenance
├── integration/                 # CI/CD integration
│   ├── index.md                 # Integration overview
│   ├── inventory.md             # Directory listing
│   ├── overview.md              # Integration overview
│   ├── approach-mapping.md      # Approach mapping
│   ├── gitlab-services-analysis.md # GitLab services analysis
│   ├── platforms/               # CI/CD platforms
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── github-actions.md    # GitHub Actions
│   │   ├── gitlab-ci.md         # GitLab CI
│   │   └── gitlab-services.md   # GitLab Services
│   ├── workflows/               # Integration workflows
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── standard-container.md # Standard container
│   │   ├── distroless-container.md # Distroless container
│   │   ├── sidecar-container.md # Sidecar container
│   │   └── security-workflows.md # Security workflows
│   ├── examples/                # Integration examples
│   │   ├── index.md             # Overview
│   │   ├── inventory.md         # Directory listing
│   │   ├── github-examples.md   # GitHub examples
│   │   └── gitlab-examples.md   # GitLab examples
│   └── configuration/           # Integration configuration
│       ├── index.md             # Overview
│       ├── inventory.md         # Directory listing
│       ├── environment-variables.md # Environment variables
│       ├── secrets-management.md # Secrets management
│       ├── thresholds-integration.md # Thresholds
│       └── reporting.md         # Reporting
├── developer-guide/             # Developer documentation
│   ├── index.md                 # Developer guide overview
│   ├── inventory.md             # Directory listing
│   ├── testing/                 # Testing documentation
│   │   ├── index.md             # Overview
│   │   └── inventory.md         # Directory listing
│   └── deployment/              # Deployment guide
│       ├── index.md             # Overview
│       ├── inventory.md         # Directory listing
│       ├── script-deployment.md # Script deployment
│       ├── helm-deployment.md   # Helm deployment
│       ├── cicd-deployment.md   # CI/CD deployment
│       ├── scenarios/           # Deployment scenarios
│       │   ├── index.md         # Overview
│       │   ├── enterprise.md    # Enterprise environment
│       │   ├── development.md   # Development environment
│       │   ├── cicd.md          # CI/CD environment
│       │   ├── multi-tenant.md  # Multi-tenant environment
│       │   └── air-gapped.md    # Air-gapped environment
│       └── advanced-topics/     # Advanced deployment
│           ├── index.md         # Overview
│           ├── inventory.md     # Directory listing
│           ├── scaling.md       # Scaling and performance
│           ├── security.md      # Security enhancements
│           ├── monitoring.md    # Monitoring and maintenance
│           ├── specialized-environments.md # Specialized environments
│           ├── verification.md  # Deployment verification
│           └── custom-development.md # Custom development
├── project/                     # Project information
│   ├── index.md                 # Project overview
│   ├── inventory.md             # Directory listing
│   ├── changelog.md             # Changelog
│   ├── roadmap.md               # Roadmap
│   ├── tasks.md                 # Tasks and issues
│   ├── documentation-gaps.md    # Documentation gaps
│   ├── content-map.md           # This file
│   ├── documentation-entry-refactoring.md # Refactoring plan
│   ├── documentation-review-plan.md # Review plan
│   ├── documentation-structure-progress.md # Structure progress
│   ├── terminology.md           # Terminology reference
│   └── archive/                 # Archived documentation
│       ├── index.md             # Archive overview
│       ├── inventory.md         # Directory listing
│       └── ascii-diagrams.md    # ASCII diagrams
└── contributing/                # Contributing documentation
    ├── index.md                 # Contributing overview
    ├── inventory.md             # Directory listing
    ├── documentation-tools.md   # Documentation tools
    ├── code-snippets.md         # Code snippets
    ├── diagram-color-guide.md   # Diagram color guide
    └── testing/                 # Documentation testing
        ├── index.md             # Testing overview
        ├── inventory.md         # Directory listing
        └── dark-light-mode-test.md # Theme testing
```

## Documentation Standards

All directories should follow these standards:

1. Each directory must have an `index.md` file serving as the entry point and overview
2. Each directory should have an `inventory.md` file listing all files with descriptions
3. Content should be organized in a logical, hierarchical manner
4. Cross-references should use relative paths to other markdown files
5. All files should use a consistent markdown style and formatting

## Redirects and Backup

Original files from the older structure have been moved to the backup directory:

```
docs-backup/
├── approaches/            # Original approach files
├── architecture/          # Original architecture files
├── configuration/         # Original configuration files
├── helm-charts/           # Original helm-charts files
├── integration/           # Original integration files
├── security/              # Original security files
└── developer-guide/       # Original developer-guide files
```

## Navigation Structure

The navigation is organized in the `mkdocs.yml` file following this high-level structure:

1. **Getting Started**
   - Introduction
   - Executive Summary
   - Quickstart Guide
   - Technical Overview

2. **Core Concepts**
   - Architecture
   - Scanning Approaches
   - Security

3. **Deployment & Configuration**
   - Kubernetes Setup
   - RBAC Configuration
   - Configuration
   - Authentication
   - Helm Charts

4. **CI/CD Integration**
   - Overview
   - CI/CD Platforms
   - Integration Workflows
   - Integration Examples
   - Example Resources

5. **Development & Contributing**
   - Developer Guide
   - Testing
   - Deployment
   - Contributing

6. **Project Information**
   - Project Overview
   - Documentation
   - Tools & Utilities
   - Archive

## Maintenance and Updates

When updating documentation:

1. Add new files to the appropriate directory
2. Update the corresponding `inventory.md` file
3. Update cross-references if needed
4. Update this content map if there are structural changes
5. Add the new files to the navigation in `mkdocs.yml` if appropriate

## Cross-Reference Mappings

These mappings help the cross-reference fixer script update links across the documentation. Each line shows an old file path and where its content has been moved in the new structure.

### Approach-Specific Files to Global Sections

```
# Approaches to Security mappings
approaches/kubernetes-api/security.md -> security/risk/kubernetes-api.md
approaches/debug-container/security.md -> security/risk/debug-container.md
approaches/sidecar-container/security.md -> security/risk/sidecar-container.md
approaches/helper-scripts/security.md -> security/risk/model.md

# Approaches to Integration mappings
approaches/kubernetes-api/integration.md -> integration/workflows/standard-container.md
approaches/debug-container/integration.md -> integration/workflows/distroless-container.md
approaches/sidecar-container/integration.md -> integration/workflows/sidecar-container.md
approaches/helper-scripts/integration.md -> integration/workflows/index.md

# Approaches to Project mappings
approaches/kubernetes-api/future-work.md -> project/roadmap.md
approaches/debug-container/future-work.md -> project/roadmap.md
approaches/sidecar-container/future-work.md -> project/roadmap.md
approaches/helper-scripts/future-work.md -> project/roadmap.md

# Approaches to RBAC mappings
approaches/kubernetes-api/rbac.md -> rbac/index.md
approaches/debug-container/rbac.md -> rbac/index.md
approaches/sidecar-container/rbac.md -> rbac/index.md
approaches/helper-scripts/rbac.md -> rbac/index.md

# Approaches to Configuration mappings
approaches/kubernetes-api/limitations.md -> approaches/kubernetes-api/limitations.md
approaches/debug-container/limitations.md -> approaches/debug-container/implementation.md
approaches/sidecar-container/limitations.md -> approaches/sidecar-container/implementation.md
approaches/helper-scripts/limitations.md -> approaches/helper-scripts/scripts-vs-commands.md
```

### Top-Level Section Reorganizations

```
# Security section reorganization
security/overview.md -> security/index.md
security/analysis.md -> security/threat-model/index.md
security/risk-analysis.md -> security/risk/index.md
security/compliance.md -> security/compliance/index.md

# Integration section reorganization
integration/overview.md -> integration/index.md
integration/github-actions.md -> integration/platforms/github-actions.md
integration/gitlab.md -> integration/platforms/gitlab-ci.md
integration/gitlab-services.md -> integration/platforms/gitlab-services.md

# Architecture section reorganization
architecture/workflows.md -> architecture/workflows/index.md
architecture/diagrams.md -> architecture/diagrams/index.md

# Configuration section reorganization
configuration/thresholds.md -> configuration/thresholds/index.md
configuration/plugins.md -> configuration/plugins/index.md
configuration/advanced/plugin-modifications.md -> configuration/plugins/implementation.md
configuration/advanced/saf-cli-integration.md -> configuration/integration/saf-cli.md
configuration/advanced/thresholds.md -> configuration/thresholds/advanced.md

# Helm Charts reorganization
helm-charts/overview.md -> helm-charts/overview/index.md
helm-charts/architecture.md -> helm-charts/overview/architecture.md
helm-charts/common-scanner.md -> helm-charts/scanner-types/common-scanner.md
helm-charts/distroless-scanner.md -> helm-charts/scanner-types/distroless-scanner.md
helm-charts/sidecar-scanner.md -> helm-charts/scanner-types/sidecar-scanner.md
helm-charts/standard-scanner.md -> helm-charts/scanner-types/standard-scanner.md
helm-charts/scanner-infrastructure.md -> helm-charts/infrastructure/index.md
helm-charts/security.md -> helm-charts/security/index.md
helm-charts/troubleshooting.md -> helm-charts/operations/troubleshooting.md
helm-charts/customization.md -> helm-charts/usage/customization.md

# Developer Guide reorganization
developer-guide/deployment/scenarios.md -> developer-guide/deployment/scenarios/index.md
developer-guide/deployment/advanced-topics.md -> developer-guide/deployment/advanced-topics/index.md
```

### Sidecar-Specific File Reorganization

```
# Sidecar container specific files
approaches/sidecar-container/pod-configuration.md -> approaches/sidecar-container/implementation.md
approaches/sidecar-container/retrieving-results.md -> approaches/sidecar-container/implementation.md
```
