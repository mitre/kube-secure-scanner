# Project Tasks Tracker

## Core Development Tasks

- [ ] Implement dual distroless container scanning approaches
  - [ ] Approach 1: Modify the train-k8s-container plugin (Official solution)
    - [ ] Add ephemeral container detection and fallback
    - [ ] Implement direct filesystem access through debug container
    - [ ] Modify connection and exec client classes
  - [ ] Approach 2: CINC Auditor in debug container with chroot (Working prototype)
    - [ ] Create specialized debug container with CINC Auditor pre-installed
    - [ ] Implement chroot-based filesystem access to target container
    - [ ] Bridge results back to host system

- [x] Complete Helm chart templates
  - [x] Finish configmap templates for remaining components
  - [x] Create helpers and utilities
  - [x] Ensure proper chart dependencies

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

- [ ] Create architecture and security documentation
  - [ ] Design architecture and flow diagrams showing container interactions
  - [ ] Create security risk analysis for both distroless approaches
  - [ ] Document risk management and security considerations
  - [ ] Develop recommendation document for decision makers

## CI/CD Integration

- [x] Create CI/CD pipeline examples
  - [x] GitHub Actions workflows for container scanning
    - [x] Dynamic RBAC scanning workflow
    - [x] Existing cluster scanning workflow
  - [x] GitLab CI pipelines for container scanning
    - [x] Dynamic RBAC scanning pipeline
    - [x] Existing cluster scanning pipeline
  - [ ] Jenkins pipeline example (optional)

- [ ] Create CI/CD examples for both distroless approaches
  - [ ] GitHub Actions workflow for Approach 1 (modified plugin)
  - [ ] GitHub Actions workflow for Approach 2 (chroot method)
  - [ ] GitLab CI configuration for both approaches

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

- [ ] Comparative analysis
  - [ ] Document pros and cons of each distroless approach
  - [ ] Create decision matrix for approach selection
  - [ ] Provide usage recommendations based on different scenarios

## Administrative

- [ ] Project release preparation
  - [ ] Version tagging
  - [ ] Release notes
  - [ ] Comprehensive usage documentation
  - [ ] Prepare demonstration of both approaches