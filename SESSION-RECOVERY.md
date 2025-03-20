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

### MkDocs Documentation Enhancement (Current Session)
1. **Documentation Structure Improvements**
   - ✅ Created `/docs/project/` directory to house project-wide documentation
   - ✅ Moved CHANGELOG.md content to `/docs/project/changelog.md`
   - ✅ Planned organization of TASKS.md to `/docs/project/tasks.md`
   - ✅ Set up navigation structure in mkdocs.yml to include project-wide documentation

2. **MkDocs Theme and Functionality Enhancements**
   - ✅ Implemented dark mode support with proper toggle using Material theme
   - ✅ Added custom CSS for better code block formatting and readability
   - ✅ Created dynamic copyright year generation with custom theme override
   - ✅ Added proper MITRE attribution and branding
   - ✅ Configured Mermaid diagrams to support dark/light mode themes
   - ✅ Added custom JavaScript for theme detection and adaptation

3. **Documentation Content Consistency**
   - ✅ Harmonized terminology throughout documentation (CINC Auditor vs InSpec)
   - ✅ Standardized approach names across all documentation files
   - ✅ Added consistent strategic priority statements in key files
   - ✅ Fixed broken links and file path references
   - ✅ Enhanced recommendation language in integration documentation
   - ✅ Fixed blank scanner-infrastructure documentation
   - ✅ Updated project metadata and navigation structure

4. **Resolved Implementation Challenges**
   - ✅ Addressed YAML files being downloaded instead of displayed
   - ✅ Ensured Mermaid charts are readable in both dark and light modes
   - ✅ Converted selected ASCII diagrams to Mermaid format
   - ✅ Tested full documentation site with dark/light mode toggle
   - ✅ Implemented proper file organization with changelog and tasks
   - ✅ Fixed broken internal links after directory reorganization
   - ✅ Created automation script for link maintenance

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

4. **Completed Helm Charts Implementation**
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

6. **Current Project Status (March 22, 2025)**
   - Implemented a complete working solution for standard container scanning
   - Created proof-of-concept for distroless containers using ephemeral debug containers
   - Completed all helper scripts for setup, scanning, and configuration
   - Finished modular Helm chart structure with proper dependencies
   - Created comprehensive documentation for all components
   - Implemented SAF CLI integration for threshold validation
   - Built CI/CD examples for GitHub Actions and GitLab CI with dynamic RBAC
   - Created GitHub repository at github.com/mitre/kube-cinc-secure-scanner
   - Enhanced MkDocs configuration with dark mode support and MITRE branding
   - Improved documentation organization with project directory structure
   - Added proper Mermaid diagram support with theme-aware configuration
   
7. **Previous Session Work**
   - Updated main README.md to reflect dual approach strategy
   - Updated distroless-container.sh script with improved error handling and documentation
   - Updated TASKS.md and ROADMAP.md to reflect dual demonstration approach
   - Created and pushed initial codebase to MITRE GitHub repository
   - Added architectural documentation requirements to roadmap
   - Planned for both distroless container scanning approaches
   
8. **Current Session Work**
   - Researched GitLab CI Services integration for enhanced container scanning
   - Created comprehensive workflow diagrams for all scanning approaches
   - Developed GitLab CI example with services for both standard and distroless scanning
   - Added detailed documentation for GitLab CI services integration
   - Updated existing documentation to reference workflow diagrams
   - Enhanced distroless containers documentation with workflow references
   - Analyzed benefits and challenges of GitLab CI Services approach
   - Developed a new CINC Auditor sidecar container approach for distroless scanning
   - Created detailed documentation for the sidecar container approach
   - Implemented example YAML, Dockerfile, and script for the sidecar approach
   - Added Minikube setup and CI/CD workflow diagrams
   - Compared the sidecar approach with other distroless scanning methods
   - Created GitLab CI example for the sidecar container approach
   - Started implementing comprehensive CI/CD integration for all scanning approaches
   
9. **Current Development Phase**
   - Implement three distroless container scanning approaches:
     1. ✅ CINC Auditor in debug container with chroot (Completed)
     2. ✅ Sidecar container with shared process namespace (Completed)
     3. 🔄 Modified train-k8s-container plugin (In Progress)
   - ✅ Create architecture and security documentation with flow diagrams
   - ✅ Implement specialized debug container with CINC Auditor pre-installed
   - ✅ Create comprehensive CI/CD integration for all approaches
   - 🔄 Performance comparison and optimization for all approaches
   - 🔄 Security risk analysis and recommendations document

10. **Recently Completed Work**
   - ✅ Created GitLab CI with services example for sidecar approach
   - ✅ Created GitHub Actions workflow for sidecar approach
   - ✅ Implemented scan-with-sidecar.sh script
   - ✅ Updated README.md with sidecar approach documentation
   - ✅ Updated directory structure with new CI/CD examples
   - ✅ Integrated all approaches into the project documentation
   - ✅ Updated TASKS.md to reflect current progress
   - ✅ Created ASCII text-based diagrams for all workflows and architectures
   - ✅ Added ASCII diagrams documentation to complement Mermaid diagrams

11. **Previous Session Work (March 19, 2025)**
   - ✅ Enhanced CI/CD integration documentation:
     - ✅ Created comprehensive CI/CD integration overview
     - ✅ Developed approach mapping document matching CI/CD examples to approaches
     - ✅ Improved cross-references between documentation sections
   - ✅ Created comprehensive documentation for Helm Charts:
     - ✅ Architecture and relationships between charts
     - ✅ Configuration options for each chart
     - ✅ Security considerations for Helm deployments
     - ✅ Troubleshooting guidance
   - ✅ Developed enhanced documentation management system:
     - ✅ Created comprehensive docs-tools.sh script with multiple capabilities
     - ✅ Added background server mode for documentation preview
     - ✅ Implemented documentation quality validation tools
     - ✅ Reorganized documentation utilities to docs directory
     - ✅ Created documentation about the documentation system
   - ✅ Cleaned up project root directory
   - ✅ Implemented process management for documentation preview server

12. **Previous Session Work (March 20, 2025)**
   - ✅ Documentation improvement and fixes:
     - ✅ Fixed approach-mapping.md links to workflow YAML files
     - ✅ Updated links to use repository URLs for workflow files
     - ✅ Tested the documentation preview functionality
     - ✅ Updated TASKS.md with progress on documentation refinement
     - ✅ Set up additional documentation dependencies for quality validation
   - ✅ Documentation quality validation:
     - ✅ Implemented npm/node dependencies for markdownlint
     - ✅ Set up pyspelling for spell checking
     - ✅ Configured MkDocs preview server for testing

13. **Current Session Work (March 21, 2025)**
   - ✅ Created comprehensive documentation:
     - ✅ Created dedicated approach-comparison.md in overview section
     - ✅ Developed detailed testing documentation (testing/README.md)
     - ✅ Created deployment scenarios documentation (deployment/README.md)
     - ✅ Developed security compliance documentation with regulatory analysis
   - ✅ Security compliance documentation:
     - ✅ Analyzed DoD 8500.01 security requirements related to scanning approaches
     - ✅ Reviewed DISA Container Platform SRG for compliance alignment
     - ✅ Incorporated Kubernetes STIG (v2r2) security controls
     - ✅ Added CIS Kubernetes Benchmark requirements
     - ✅ Created comprehensive compliance comparison table for all approaches
     - ✅ Documented risk acceptance requirements for alternative approaches
   - ✅ Documentation organization:
     - ✅ Updated mkdocs.yml navigation to include new documentation
     - ✅ Reorganized security documentation for better flow
     - ✅ Updated SESSION-RECOVERY.md to track progress

### Recent Progress

1. **High-Level Documentation Completed**
   - ✅ Created Executive Summary for stakeholders
   - ✅ Developed detailed Security Risk Analysis document
   - ✅ Created comprehensive Approach Decision Matrix
   - ✅ Added Enterprise Integration Analysis
   - ✅ Updated all files to use the new helm-charts structure

2. **Sidecar Container Approach Implementation**
   - ✅ Created new sidecar-scanner Helm chart
   - ✅ Implemented scan-with-sidecar.sh script
   - ✅ Added CI/CD examples for GitLab and GitHub Actions
   - ✅ Created example Dockerfile and pod definitions

3. **Repository Maintenance**
   - ✅ Completed migration from legacy helm-chart to modular helm-charts structure
   - ✅ Committed and pushed all changes to the origin repository

### Documentation Improvements

#### Completed Work
1. **MkDocs Setup**
   - ✅ Created mkdocs.yml configuration file
   - ✅ Set up GitHub Action for automatic deployment (deploy-docs.yml)
   - ✅ Adjusted documentation structure for optimal navigation

2. **Documentation Enhancements for MkDocs**
   - ✅ Created a comprehensive navigation hierarchy in mkdocs.yml
   - ✅ Added search functionality and proper indexing
   - ✅ Created a landing page with clear navigation paths
   - ✅ Integrated Mermaid diagram support for workflow visualization
   - ✅ Added requirements.txt file for Python dependencies
   - ✅ Updated README.md with MkDocs usage instructions
   - ✅ Updated terminology to consistently use "Kubernetes API Approach" instead of "Standard Scanning"
   - ✅ Enhanced enterprise integration analysis documentation

#### Documentation Tasks Progress

1. **Standardization and Enhancement**
   - ✅ Normalize approach naming across documentation:
     - ✅ Consistently use "Kubernetes API Approach" (not "Modified Plugin" or "Standard Scanning")
     - ✅ Ensure consistent naming for "Debug Container Approach" and "Sidecar Container Approach"
   - ✅ Review documents to ensure terminology consistency
   - ✅ Create comprehensive CI/CD integration overview
   - ✅ Develop approach mapping for CI/CD examples across all platforms and approaches
   - ✅ Add cross-references throughout documentation for better navigation

2. **Helm Chart Documentation**
   - ✅ Create comprehensive documentation for Helm Charts:
     - ✅ Architecture and design with detailed diagrams
     - ✅ Usage instructions for different scenarios
     - ✅ Configuration options with examples
     - ✅ Security considerations specific to Helm deployments
     - ✅ Troubleshooting guidance
   - ✅ Integrate into MkDocs navigation structure

3. **CI/CD Integration Documentation**
   - ✅ Create CI/CD integration overview document
   - ✅ Develop approach mapping document to match CI/CD examples to specific approaches
   - ✅ Add clear guidance on choosing the right CI/CD integration
   - ✅ Enhance GitLab services documentation and analysis
   - ✅ Document all available CI/CD configuration options
   - ✅ Organize documentation by platform and approach

4. **Documentation System Enhancement**
   - ✅ Create comprehensive documentation management system
   - ✅ Reorganize documentation utilities to the docs directory
   - ✅ Add tools for validating documentation quality:
     - ✅ Markdown linting with markdownlint
     - ✅ Spell checking with pyspelling
     - ✅ Link validation with linkchecker
   - ✅ Enhance documentation preview with background server and status monitoring
   - ✅ Create documentation about the documentation system itself
   - ✅ Clean up project root directory

5. **Next Documentation Tasks**
   - ✅ Fix approach-mapping.md links to workflow YAML files
   - 🔄 Add more CI/CD examples for different environments
   - 🔄 Create comprehensive testing documentation section
   - 🔄 Add deployment scenarios documentation
   - 🔄 Review all documents for accessibility and readability

### Next Steps

1. **Complete Documentation Enhancement (Current Priority)**
   - ✅ Created project directory structure
   - ✅ Set up consolidated changelog in /docs/project/
   - ✅ Complete file organization with tasks.md
   - ✅ Test Mermaid dark mode configuration with actual diagrams
   - ✅ Add specialized configuration to display YAML files with syntax highlighting
   - ✅ Create sample ASCII-to-Mermaid conversion as proof of concept
   - ✅ Verify all links are working correctly after updates
   - ✅ Test documentation site with dark/light mode toggle
   - ✅ Add additional configuration for proper code display
   - ✅ Update the changelog with comprehensive entries
   - ✅ Update TASKS.md and ROADMAP.md to reflect current progress
   - ✅ Analyze documentation gaps and create documentation-gaps.md
   - 🔄 Address high-priority documentation gaps before v1.0.0 release

2. **Complete Container Scanning Approaches Implementation**
   - **Approach 1 - Modified Plugin (Enterprise Solution):**
     - 🔄 Fork and modify the train-k8s-container plugin to support distroless containers
     - 🔄 Implement ephemeral container detection and integration directly in the plugin
     - 🔄 Add automatic fallback to ephemeral containers when shell access fails
     - 🔄 Create examples and documentation for this approach
     - References to explore:
       - https://github.com/inspec/train-k8s-container/blob/main/lib/train/k8s/container/kubectl_exec_client.rb (modify exec approach)
       - https://github.com/inspec/train-k8s-container/blob/main/lib/train/k8s/container/connection.rb (add ephemeral detection)
       - https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/
   
   - **Approach 2 - CINC Auditor Debug Container (Working Prototype):**
     - ✅ Create specialized debug container with CINC Auditor pre-installed
     - ✅ Implement chroot-based filesystem access to target container
     - ✅ Develop mechanism to bridge results back to host system
     - ✅ Document the approach's tradeoffs and use cases
     - ✅ Create working examples with common distroless images

   - **Approach 3 - Sidecar Container with Shared Process Namespace:**
     - ✅ Implement process identification and filesystem access via /proc/PID/root
     - ✅ Create example pod YAML for sidecar container deployment
     - ✅ Create script for deploying and managing the sidecar container
     - ✅ Document the sidecar approach's tradeoffs and use cases
     - ✅ Integrate with CI/CD examples

   - **CI/CD Integration for All Approaches:**
     - ✅ GitHub Actions workflow for debug container approach
     - ✅ GitHub Actions workflow for sidecar container approach
     - 🔄 GitHub Actions workflow for modified plugin approach
     - ✅ GitLab CI pipeline for debug container approach 
     - ✅ GitLab CI pipeline for sidecar container approach
     - 🔄 GitLab CI pipeline for modified plugin approach
     - ✅ GitLab CI with Services for sidecar container approach
     - 🔄 Comparative demonstration pipelines

2. **Create Higher-Level Documentation**
   - ✅ Executive Summary for stakeholders and decision makers
   - ✅ Comprehensive overview and detailed analysis of each approach
   - ✅ Security risk analysis and risk mitigation strategies:
     - ✅ Privilege requirements analysis
     - ✅ Attack surface evaluation
     - ✅ Specific mitigation strategies for each approach
   - ✅ Enterprise Integration Analysis:
     - ✅ Scalability considerations
     - ✅ Maintenance and upkeep requirements
     - ✅ CI/CD pipeline integration complexity
     - ✅ User experience analysis for different user personas
   - ✅ Decision matrix for approach selection based on specific requirements

3. **Integration and Testing**
   - ✅ Complete the Helm chart templates for core components
   - ✅ Create Helm charts for the sidecar container approach
   - ✅ Test both approaches (shell scripts and Helm charts) in CI/CD
   - ✅ Validate automated minikube setup with different configurations
   - 🔄 Test with various distroless container types (Go, Java, Python, etc.)
   - ✅ Ensure proper compatibility with SAF CLI threshold checks
   - 🔄 Create Kubernetes mutating webhook example for sidecar injection

3. **Architecture and Documentation**
   - ✅ Create architecture and flow diagrams showing container interactions (Done)
   - Develop security risk analysis for both approaches
   - ✅ Create decision matrix comparing approaches (Done in distroless-containers.md)
   - Document both helper scripts AND direct kubectl/inspec commands
   - Develop recommendation document for stakeholders
     - Show how to use helper scripts (scan-container.sh, scan-distroless-container.sh)
     - Show the equivalent direct kubectl and inspec commands for users who prefer that approach
     - Ensure users understand what's happening "under the hood"
   - Create tutorials for scanning different types of containers
   - Add more InSpec profile examples optimized for distroless containers
   - ✅ Update CI/CD examples for both approaches (Done for GitLab CI with services)

4. **GitLab CI Services Implementation**
   - ✅ Analyze GitLab CI services for enhanced container scanning
   - ✅ Create GitLab CI services example for both standard and distroless scanning
   - ✅ Document GitLab CI services integration with detailed analysis
   - ✅ Create GitLab CI services example for sidecar container approach
   - 🔄 Build and publish scanner service Docker images:
     - Standard scanner image with CINC Auditor pre-installed
     - Distroless scanner image with specialized tooling
   - 🔄 Test the GitLab CI services approach with real-world workloads
   - 🔄 Create GitHub Actions equivalent using service containers
   - 🔄 Document best practices for maintaining scanner service images
   - 🔄 Create examples for different CI/CD environments and use cases

5. **Sidecar Container Approach Integration (Mostly Completed)**
   - ✅ Create CI/CD integration examples for the sidecar container approach:
     - ✅ GitLab CI example for sidecar container scanning
     - ✅ GitLab CI with services example for sidecar container scanning
     - ✅ GitHub Actions example for sidecar container scanning
   - ✅ Create dedicated scan-with-sidecar.sh script
   - ✅ Document the sidecar approach in the main README
   - 🔄 Build and publish a dedicated CINC Auditor sidecar container image
   - 🔄 Update the Helm charts to support the sidecar container approach
   - 🔄 Create a mutating webhook example for automatically injecting scanner sidecars

## Key Decisions and Latest Status

1. **Container Scanning Approaches**:
   - **Standard Containers**: Using train-k8s-container transport plugin (stable)
   - **Distroless Containers**: Three distinct approaches implemented
     - Debug container approach with chroot (requires ephemeral containers feature)
     - Sidecar container approach with shared process namespace (works universally)
     - Modified transport plugin approach (in progress, most transparent to users)

2. **CI/CD Integration**: 
   - Multiple implementation strategies for each approach
   - GitLab CI standard, GitLab CI with services, and GitHub Actions
   - Comprehensive examples for all scanning approaches
   - Shared volume and configuration approach for results collection

3. **Security First**:
   - CINC Auditor (open-source InSpec) to avoid licensing issues
   - MITRE SAF-CLI for results processing and threshold validation
   - Supporting both label-based and name-based RBAC approaches
   - Using short-lived tokens (default 15 minutes) for security
   - Least privilege principle applied throughout all implementations

4. **Deployment and Configuration**:
   - Shell scripts for direct usage and testing
   - Modular Helm charts for production deployment
   - Comprehensive configuration options and examples
   - YAML-based threshold files for compliance validation

5. **Latest Status (March 22, 2025)**:
   - ✅ Three scanning approaches implemented (standard, debug container, sidecar container)
   - ✅ CI/CD integration for all approaches (GitLab CI, GitHub Actions)
   - ✅ Comprehensive documentation with workflow diagrams
   - ✅ Security-focused design with least privilege RBAC
   - 🔄 Modified transport plugin approach in progress
   - ✅ Complete documentation reorganization and structure improvement
   - ✅ Enhanced MkDocs implementation with optimized navigation
   - ✅ Comprehensive changelog documentation with detailed entries
   - ✅ Updated TASKS.md and ROADMAP.md with accurate project status

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
├── helm-charts/             # Modular Helm charts for deployment
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