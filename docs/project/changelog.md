# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Performance

- Improved documentation build performance with optimized MkDocs configuration
- Enhanced diagram rendering efficiency with optimized Mermaid settings
- Added caching configuration for faster documentation site performance
- Optimized image assets for faster loading times
- Reduced CSS size with optimization techniques

### Added

- 2025-03-20: Documentation infrastructure
    - Added comprehensive MkDocs with Material theme configuration
    - Implemented automated documentation validation tools
    - Created docs-tools.sh script for documentation maintenance
    - Added spell checking and markdown linting
    - Created README files for all major documentation sections
    - Added custom CSS for improved documentation styling
    - Implemented mermaid-config.js for consistent diagram styling
    - Created documentation link validation tools

- 2025-03-19: CI/CD Integration
    - Added GitLab CI pipeline examples for all scanning approaches
    - Created GitHub Actions workflows for container scanning
    - Added examples for dynamic RBAC configuration in pipelines
    - Created examples for existing cluster integration
    - Implemented GitLab CI with services configuration
    - Added documentation on CI/CD integration patterns

- 2025-03-18: Security and compliance documentation
    - Created detailed security risk analysis for all approaches
    - Added compliance documentation aligned with DoD 8500.01
    - Created service account and token management documentation
    - Added RBAC configuration guides with examples
    - Created threshold validation documentation

- 2025-03-17: Helm charts and deployment
    - Created modular Helm chart architecture
    - Implemented scanner infrastructure chart
    - Added specialized charts for each scanning approach
    - Created common components chart
    - Added values files with examples
    - Created comprehensive deployment documentation

- 2025-03-15: Initial project structure and core functionality
    - Three container scanning approaches:
        - Kubernetes API Approach (train-k8s-container plugin)
        - Debug Container Approach (ephemeral containers)
        - Sidecar Container Approach (shared process namespace)
    - Basic shell scripts for each scanning approach
    - Example profiles and configurations
    - Core documentation framework

### Changed

- 2025-03-20: Documentation reorganization and structure improvement
    - Complete reorganization of documentation into logical directory structure
    - Created dedicated directories for approaches, architecture, security
    - Reorganized navigation structure in mkdocs.yml
    - Moved Helm Chart Architecture to Helm Charts section
    - Created new "Kubernetes Setup" section for infrastructure-related docs
    - Renamed "Configuration" to "Scanner Configuration" for clarity
    - Added README files for all major documentation sections
    - Fixed all internal links after reorganization
    - Created automation script (fix-links.sh) for link maintenance
    - Improved cross-references between related documentation
    - Fixed Mermaid diagram display issues with proper containment
    - Separated configuration documentation into kubeconfig and service accounts sections
    - Improved RELEASE-NOTES.md with comprehensive feature list
    - Enhanced GitHub workflow examples with clearer section organization
    - Restructured GitLab pipeline examples for better discoverability
    - Improved session recovery documentation with better headings and structure

- 2025-03-19: Documentation consistency enhancement
    - Added consistent strategic priority statements about Kubernetes API Approach in key files
    - Standardized terminology from "InSpec" to "CINC Auditor" across all documents
    - Fixed broken relative links to use absolute paths (e.g., `/docs/overview/workflows.md`)
    - Updated path references to reflect current directory structure
    - Added clear labeling of interim approaches vs enterprise-recommended solutions
    - Standardized approach naming (Kubernetes API Approach, Debug Container Approach, Sidecar Container Approach)
    - Added explicit strategic priority statements for train-k8s-container plugin enhancement
    - Updated integration documentation to consistently recommend Kubernetes API Approach
    - Fixed cross-references between GitHub Actions and GitLab CI documentation
    - Corrected examples' directory paths and workflow references
    - Updated TASKS.md to highlight highest priority implementation items
    - Added consistent "Strategic Priority" banners to key technical documents
    - Enhanced integration guides with consistent approach recommendations
    - Fixed repository name references in quickstart documentation
    - Updated index files for GitHub and GitLab examples with consistent messaging
    - Added strategic implementation path to plugin-modifications.md

- 2025-03-18: System architecture and workflow documentation
    - Added comprehensive Helm chart architecture documentation
    - Created workflow diagrams for all scanning approaches
    - Added sequence diagrams for CI/CD integration workflows
    - Improved documentation of component relationships
    - Added GitLab CI integration with services documentation
    - Enhanced diagram documentation with color guidelines
    - Added ASCII to Mermaid conversion utilities

### Fixed

- 2025-03-20: Documentation structure and links
    - Fixed broken internal links after directory reorganization
    - Resolved MkDocs build warnings
    - Fixed Mermaid diagram containment issues
    - Corrected cross-references between documentation sections
    - Fixed README references to moved files
    - Corrected include paths for code examples
    - Resolved dark/light mode issues with Mermaid diagrams
    - Fixed inconsistent heading structure across documentation
    - Corrected file and directory paths in example code
    - Fixed navigation structure inconsistencies
    - Resolved path issues after moving GitHub workflow examples
    - Fixed GitLab pipeline examples directory references

- 2025-03-19: Consistency and naming
    - Fixed inconsistent terminology across documentation
    - Resolved approach naming inconsistencies
    - Fixed directory structure inconsistencies
    - Corrected relative vs. absolute path issues
    - Fixed navigation structure in mkdocs.yml
    - Addressed MkDocs build warnings with proper exclude_docs configuration

- 2025-03-18: Technical documentation
    - Fixed workflow diagrams with proper styling
    - Corrected security analysis documentation
    - Fixed threshold examples in threshold.md
    - Corrected Helm chart value examples
    - Fixed GitLab CI pipeline configuration examples

### Security

- Enhanced documentation of security compliance considerations
- Clarified risk documentation requirements for alternative approaches
- Added detailed RBAC configuration guidelines with security best practices
- Improved token management documentation with enhanced security considerations
- Added service account configuration security recommendations
- Created dedicated security section for each scanning approach
- Enhanced security risk analysis documentation for enterprise environments
- Added DoD 8500.01 compliance considerations to security documentation
- Improved guidance for least privilege configuration in all scanning scenarios
