# Project Tasks Tracker

## Core Development Tasks

- [x] Implement three distroless container scanning approaches
  - [ ] **HIGHEST PRIORITY**: Approach 1 (Kubernetes API Approach): Modify the train-k8s-container plugin (Enterprise Recommended)
    - [ ] Add ephemeral container detection and fallback
    - [ ] Implement direct filesystem access through debug container
    - [ ] Modify connection and exec client classes
  - [x] Approach 2 (Debug Container Approach): CINC Auditor in debug container with chroot (Interim solution)
    - [x] Create specialized debug container with CINC Auditor pre-installed
    - [x] Implement chroot-based filesystem access to target container
    - [x] Bridge results back to host system
  - [x] Approach 3 (Sidecar Container Approach): Sidecar container with shared process namespace (Interim solution)
    - [x] Create script for sidecar deployment and scanning
    - [x] Implement process detection and filesystem access
    - [x] Integration with CI/CD pipelines

- [x] Complete Helm chart templates
  - [x] Finish configmap templates for remaining components
  - [x] Create helpers and utilities
  - [x] Ensure proper chart dependencies
  - [x] Create Helm chart for sidecar container approach

- [ ] Testing with container types
  - [ ] Test with Google's distroless images
  - [ ] Test with custom minimalist containers
  - [ ] Test with different language runtimes (Go, Java, Python)

## Documentation Tasks

- [x] Create detailed documentation showing script/command equivalence
  - [x] Document what `setup-minikube.sh` does vs. direct minikube/kubectl commands
  - [x] Document what `scan-container.sh` does vs. direct kubectl/inspec commands
  - [x] Document what `scan-distroless-container.sh` does vs. direct ephemeral container commands
  - [x] Create a `/docs/direct-commands.md` file with examples

- [x] Update main README.md
  - [x] Clarify the two approaches (shell scripts vs. Helm)
  - [x] Add installation requirements
  - [x] Improve usage examples

- [x] Create comprehensive documentation
  - [x] Design architecture and flow diagrams showing container interactions
  - [x] Create ASCII text-based versions of all diagrams for terminal viewing
  - [x] Develop Executive Summary for stakeholders and decision makers
  - [x] Create detailed security risk analysis for all three approaches
  - [x] Document risk mitigation strategies and security considerations
  - [x] Create Enterprise Integration Analysis (scalability, maintenance, UX)
  - [x] Develop comprehensive decision matrix for approach selection

## CI/CD Integration

- [x] Create CI/CD pipeline examples
  - [x] GitHub Actions workflows for container scanning
    - [x] Dynamic RBAC scanning workflow
    - [x] Existing cluster scanning workflow
  - [x] GitLab CI pipelines for container scanning
    - [x] Dynamic RBAC scanning pipeline
    - [x] Existing cluster scanning pipeline
  - [ ] Jenkins pipeline example (optional)

- [x] Create CI/CD examples for all distroless approaches
  - [ ] **HIGHEST PRIORITY**: GitHub Actions workflow for Approach 1 (Kubernetes API Approach)
  - [x] GitHub Actions workflow for Approach 2 (Debug Container Approach) - interim solution
  - [x] GitHub Actions workflow for Approach 3 (Sidecar Container Approach) - interim solution
  - [ ] **HIGHEST PRIORITY**: GitLab CI configuration for Approach 1 (Kubernetes API Approach)
  - [x] GitLab CI configuration for Approach 2 (Debug Container Approach) - interim solution
  - [x] GitLab CI configuration for Approach 3 (Sidecar Container Approach) - interim solution
  - [x] GitLab CI with Services for Approach 3 (Sidecar Container Approach) - interim solution

- [ ] Additional Security Scanning Integration Examples
  - [ ] OWASP ZAP integration for web application security scanning
    - [ ] Create GitHub Actions example for ZAP scanning integration
    - [ ] Create GitLab CI pipeline examples for ZAP integration
    - [ ] Create GitLab Services configuration for ZAP scanning
    - [ ] Document integration points between container and application scanning
  - [ ] Create examples showing combined container/application security reporting

## SAF CLI Integration

- [x] Implement threshold configuration files
  - [x] Create sample threshold YAML files
  - [x] Document threshold configuration options
  - [x] Add examples for pass/fail criteria

- [x] Add SAF CLI integration examples
  - [x] Show how to process scan results with SAF CLI
  - [x] Demonstrate compliance reporting
  - [x] Document threshold checks

## Validation and Refinement

- [ ] Security review
  - [ ] Audit RBAC permissions for least privilege
  - [ ] Review token generation and management
  - [ ] Assess network security model
  - [ ] Compare security implications of both distroless approaches

- [ ] Performance optimization
  - [ ] Measure and optimize scan times for both approaches
  - [ ] Reduce resource usage during scans
  - [ ] Improve startup time
  - [ ] Benchmark and compare performance between approaches

- [x] Comparative analysis
  - [x] Document pros and cons of each distroless approach
  - [x] Create decision matrix for approach selection
  - [x] Provide usage recommendations based on different scenarios

## Documentation System

- [x] Implement MkDocs with Material theme
  - [x] Create mkdocs.yml configuration
  - [x] Set up GitHub Actions for documentation deployment
  - [x] Create enhanced navigation hierarchy
  - [x] Add requirements.txt for Python dependencies
  - [x] Update README.md with documentation usage instructions
  - [x] Update terminology for consistent naming of approaches

- [x] Documentation Refinement
  - [x] Standardize approach naming across all documents
  - [x] Create Helm Chart documentation section
  - [x] Integrate ASCII diagram approach comparison into main documentation
  - [x] Fix approach-mapping.md links to workflow YAML files 
  - [x] Ensure consistent messaging about the Kubernetes API Approach as enterprise-recommended solution
  - [x] Add clear strategic priority statements across all key documentation
  - [ ] Add development and testing documentation section
  - [x] Conduct comprehensive documentation review for coherence and flow
  - [x] Reorganize documentation into logical directory structure
  - [ ] Fix broken internal links after reorganization
    - [ ] Fix paths in approaches/ directory files
    - [ ] Fix paths in security/ directory files 
    - [ ] Fix paths in architecture/ directory files
    - [ ] Fix paths in integration/ directory files
    - [ ] Fix paths in helm-charts/ directory files
    - [ ] Fix paths in developer-guide/ directory files
    - [ ] Fix paths in overview/ directory files
  - [ ] Create script to automate link path fixes for common patterns

## Administrative

- [ ] Project release preparation
  - [ ] Version tagging (v1.0.0)
  - [ ] Release notes with key features and capabilities
  - [x] Comprehensive documentation website with MkDocs
  - [ ] Final review of all example code and scripts
  - [ ] Create project logo and branding assets
  - [ ] Prepare demonstration of all three scanning approaches