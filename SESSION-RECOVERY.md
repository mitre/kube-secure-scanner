# Session Recovery Document

This document helps maintain context between sessions when working on the secure container scanning project.

## Current Project State

We've created a comprehensive project structure for secure Kubernetes container scanning using CINC Auditor (open-source InSpec) with the train-k8s-container transport. The project demonstrates how to implement least-privilege RBAC to minimize security risk.

### Completed Components

1. **Documentation**
   - Comprehensive guides organized by topic (RBAC, service accounts, tokens, etc.)
   - Detailed integration guides for CI/CD pipelines
   - SAF CLI integration documentation
   - Threshold configuration guide

2. **Kubernetes Resources**
   - YAML templates for namespace, service accounts, RBAC
   - Label-based and name-based RBAC examples

3. **Automation Scripts**
   - kubeconfig generation script
   - Container scanning wrapper script with SAF CLI integration
   - Proper threshold file handling

4. **Helm Chart**
   - Templates for all required resources
   - Configurable values.yaml with SAF CLI settings
   - Helper scripts deployed as configmaps
   - Threshold configuration support

5. **GitHub Workflows**
   - Basic setup and scan workflow
   - Dynamic RBAC scanning workflow
   - CI/CD pipeline workflow
   - All properly integrated with MITRE SAF-CLI threshold validation

6. **CINC Profiles**
   - Example container baseline profile

7. **GitLab Integration**
   - Dedicated gitlab-examples directory
   - Complete GitLab CI pipeline example

### Latest Updates

We most recently:
1. Moved GitLab CI configuration to dedicated gitlab-examples directory
2. Updated Helm chart with proper SAF CLI threshold configuration in values.yaml
3. Updated scan-container.sh to use YAML-based threshold files
4. Fixed all GitHub workflow files to use proper threshold configuration
5. Created comprehensive documentation on SAF CLI and thresholds
6. Added example threshold.yml files
7. Updated ConfigMap scripts in Helm chart to properly use thresholds

## Latest Progress

### Completed Work

1. **Minikube Testing Environment Setup**
   - Created a comprehensive `setup-minikube.sh` script to automate the setup of a multi-node cluster
   - Added support for distroless container testing with the `--with-distroless` flag
   - Implemented dependency checking and optional installation
   - Added detailed help and usage information
   - Created comprehensive output with colorful indicators and next steps

2. **Modular Helm Chart Structure**
   - Created a new layered, modular Helm chart structure:
     - `scanner-infrastructure`: Core RBAC, service accounts, tokens
     - `common-scanner`: Common scanning components and utilities 
     - `standard-scanner`: Standard container scanning (regular containers)
     - `distroless-scanner`: Distroless container scanning (ephemeral containers)
   - Set up proper chart dependencies with chart inheritance
   - Configured each chart with appropriate values.yaml and templates
   - Added README.md with usage instructions

3. **Documentation Updates**
   - Updated main README.md to clearly explain both approaches
   - Added documentation for scanning distroless containers
   - Clarified the differences between shell script and Helm approaches

4. **Completed Helm Chart Implementation**
   - Added comprehensive README.md files for each chart
   - Created detailed NOTES.txt templates with usage instructions
   - Enhanced test pod templates with security context and resource limits
   - Added threshold configuration with SAF CLI integration
   - Created example values files for different environments and use cases
   - Added install-all.sh helper script for easy deployment
   - Implemented chart labels and annotations for better resource organization
   - Added configmaps for shared scripts and threshold configurations

5. **Documentation and Integration Completion**
   - Created direct-commands.md showing how to use with/without helper scripts
   - Developed comprehensive ROADMAP.md showing completed and planned work
   - Completed SAF CLI integration documentation
   - Ensured threshold configuration is properly integrated in all components
   - Added examples for different environments and use cases
   - Verified CI/CD pipeline examples for GitHub Actions and GitLab CI
   - Created additional CI/CD examples:
     - Dynamic RBAC scanning in GitLab CI
     - Scanning with existing Kubernetes clusters in GitHub Actions
     - Scanning with existing Kubernetes clusters in GitLab CI

6. **Current Project Status (March 19, 2025)**
   - Implemented a complete working solution for standard container scanning
   - Created proof-of-concept for distroless containers using ephemeral debug containers
   - Completed all helper scripts for setup, scanning, and configuration
   - Finished modular Helm chart structure with proper dependencies
   - Created comprehensive documentation for all components
   - Implemented SAF CLI integration for threshold validation
   - Built CI/CD examples for GitHub Actions and GitLab CI with dynamic RBAC
   - Created GitHub repository at github.com/mitre/kube-cinc-secure-scanner
   
7. **Work Completed This Session**
   - Updated main README.md to reflect dual approach strategy
   - Updated distroless-container.sh script with improved error handling and documentation
   - Updated TASKS.md and ROADMAP.md to reflect dual demonstration approach
   - Created and pushed initial codebase to MITRE GitHub repository
   - Added architectural documentation requirements to roadmap
   - Planned for both distroless container scanning approaches
   
8. **Next Development Phase**
   - Implement dual demonstration of distroless container scanning approaches:
     1. Modified train-k8s-container plugin (Enterprise Solution)
     2. CINC Auditor in debug container with chroot (Working Prototype)
   - Create architecture and security documentation with flow diagrams
   - Implement specialized debug container with CINC Auditor pre-installed
   - Performance comparison and optimization for both approaches
   - Security risk analysis and recommendations document

### Next Steps

1. **Dual Distroless Container Scanning Implementation**
   - **Approach 1 - Modified Plugin (Enterprise Solution):**
     - Fork and modify the train-k8s-container plugin to support distroless containers
     - Implement ephemeral container detection and integration directly in the plugin
     - Add automatic fallback to ephemeral containers when shell access fails
     - Create examples and documentation for this approach
     - References to explore:
       - https://github.com/inspec/train-k8s-container/blob/main/lib/train/k8s/container/kubectl_exec_client.rb (modify exec approach)
       - https://github.com/inspec/train-k8s-container/blob/main/lib/train/k8s/container/connection.rb (add ephemeral detection)
       - https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/
   
   - **Approach 2 - CINC Auditor Debug Container (Working Prototype):**
     - Create specialized debug container with CINC Auditor pre-installed
     - Implement chroot-based filesystem access to target container
     - Develop mechanism to bridge results back to host system
     - Document the approach's tradeoffs and use cases
     - Create working examples with common distroless images

   - **CI/CD Integration for Both Approaches:**
     - GitHub Actions workflow for both approaches
     - GitLab CI pipeline for both approaches 
     - Comparative demonstration pipelines

2. **Integration and Testing**
   - Complete the Helm chart templates for all components
   - Test both approaches (shell scripts and Helm charts) in CI/CD
   - Validate automated minikube setup with different configurations
   - Test with various distroless container types (Go, Java, Python, etc.)
   - Ensure proper compatibility with SAF CLI threshold checks

3. **Architecture and Documentation**
   - Create architecture and flow diagrams showing container interactions
   - Develop security risk analysis for both approaches
   - Create decision matrix comparing approaches
   - Document both helper scripts AND direct kubectl/inspec commands
   - Develop recommendation document for stakeholders
     - Show how to use helper scripts (scan-container.sh, scan-distroless-container.sh)
     - Show the equivalent direct kubectl and inspec commands for users who prefer that approach
     - Ensure users understand what's happening "under the hood"
   - Create tutorials for scanning different types of containers
   - Add more InSpec profile examples optimized for distroless containers
   - Update CI/CD examples for both approaches

## Key Decisions

1. **CINC vs InSpec**: Using CINC Auditor (open-source InSpec) to avoid licensing issues
2. **MITRE SAF-CLI**: Added for results processing and threshold capabilities
3. **RBAC Strategies**: Supporting both label-based and name-based approaches
4. **Token Management**: Using short-lived tokens (default 15 minutes) for security
5. **CI/CD Integration**: Providing examples for both GitHub Actions and GitLab CI
6. **Thresholds**: Using YAML-based threshold files for compliance validation

## Project Structure

```
minikube/
├── docs/                    # Documentation
│   ├── overview/            # Project overview
│   ├── rbac/                # RBAC configuration
│   ├── service-accounts/    # Service account setup
│   ├── configuration/       # Kubeconfig
│   ├── tokens/              # Token management
│   ├── integration/         # CI/CD integration
│   ├── saf-cli-integration.md # SAF CLI integration
│   └── thresholds.md        # Threshold configuration
├── scripts/                 # Automation scripts
├── kubernetes/              # Kubernetes manifests
│   └── templates/           # Template YAML files
├── helm-chart/              # Helm chart for deployment
│   └── examples/            # Example threshold files
├── github-workflows/        # GitHub Actions workflows
├── gitlab-examples/         # GitLab CI examples
└── examples/                # Example resources
    ├── cinc-profiles/       # CINC Auditor profiles
    └── generate-threshold.md # Threshold generation guide
```

## Important Notes for Future Sessions

### Distroless Container Scanning Approaches: User Experience Considerations

When analyzing our two approaches for distroless container scanning, we need to consider the end-user experience, especially since our solution needs to scale to many teams conducting frequent scans:

**Approach 1: Modified train-k8s-container Plugin**
- **User Experience Benefits:**
  - Most transparent to end users - they use the exact same commands as with regular containers
  - No additional knowledge required by teams
  - Scales easily across many teams
  - Teams don't need to understand the underlying mechanics
  - Consistent experience regardless of container type
- **Adoption Considerations:**
  - Easier organizational adoption due to consistent workflow
  - Lower training burden
  - Better for multi-team environments

**Approach 2: Direct chroot Approach**
- **User Experience Challenges:**
  - Requires specialized debug containers
  - May require different commands or workflows for distroless vs. regular containers
  - More complexity visible to end users
  - Potentially more friction for wide adoption
  - Teams need to understand more about the underlying mechanism

From a user experience and scalability perspective, Approach 1 (plugin modification) offers superior transparency and consistency, which is critical for wide adoption across multiple teams.

### Technical Correction for Chroot Approach
We've identified an important correction for the direct chroot approach to scanning distroless containers:

1. CINC Auditor/InSpec is not a simple binary but requires a full Ruby environment with dependencies
2. The debug container would need to have Ruby, required gems, and all CINC Auditor dependencies
3. A proper implementation would likely be based on a custom Docker image similar to:
   - https://gitlab.com/cinc-project/docker-images/-/blob/master/docker-auditor/Dockerfile
   - https://gitlab.com/cinc-project/docker-images/-/blob/master/docker-auditor/Gemfile

When we update the documentation, we'll need to revise the chroot approach to either:
- Use a pre-built CINC Auditor container as the debug container
- Include instructions for building a proper debug container with all Ruby dependencies
- Explore alternative methods that account for InSpec's Ruby environment requirements

## References

- MITRE SAF-CLI: https://saf-cli.mitre.org/
- MITRE SAF Thresholds: https://github.com/mitre/saf/wiki/Validation-with-Thresholds/
- CINC Project: https://cinc.sh/
- train-k8s-container transport: https://github.com/inspec/train-k8s-container
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Kubernetes Ephemeral Containers: https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/
- CINC Auditor Docker: https://gitlab.com/cinc-project/docker-images/-/tree/master/docker-auditor