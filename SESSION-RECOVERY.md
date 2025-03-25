# Session Recovery Document

This document helps maintain context between sessions when working on the secure container scanning project.

## Documentation Reorganization Progress Summary (Updated March 25, 2025)

We've been implementing a comprehensive documentation reorganization to improve usability and maintainability following a consistent pattern:
- Breaking large documents into focused subdirectories with dedicated content files
- Creating standardized index.md and inventory.md files for each subdirectory
- Updating navigation to reflect the new structure
- Maintaining cross-references between related topics

### Completed Reorganization:
- ✅ Approaches section - Restructured into subdirectories by approach type with focused content files
- ✅ Security section - Restructured into principles/, risk/, compliance/, threat-model/, and recommendations/
- ✅ Deployment scenarios - Already reorganized with subdirectories
- ✅ Advanced topics - Already reorganized with subdirectories
- ✅ Helm Charts - Reorganized into overview/, scanner-types/, infrastructure/, usage/, security/, and operations/
- ✅ Configuration - Reorganized into kubeconfig/, thresholds/, plugins/, integration/, and security/

### Planned for Reorganization:
- 📅 Architecture - Medium priority
- 📅 Integration - Medium priority

### Next Steps:
1. Begin the Architecture section reorganization
2. Continue Phase 4 (review and refinement) of documentation refactoring
3. Address remaining documentation gaps
4. Implement documentation validation tools

## Current Project State (Updated March 24, 2025)

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

### Documentation Structure and Content Enhancement (Previous Session - March 24, 2025)
1. **Documentation System Improvements**
   - ✅ Enhanced docs-tools.sh script with comprehensive logging functionality
   - ✅ Added ability to specify custom log file paths with `--log path/to/file.log`
   - ✅ Implemented intelligent log viewing with flexible options (`--all`, `--lines=N`, `-n N`)
   - ✅ Added server status monitoring and process management
   - ✅ Updated CLAUDE.md with documentation management commands
   - ✅ Fixed navigation issues in mkdocs.yml for README.md files

2. **Documentation Reorganization Implementation**
   - ✅ Updated mkdocs.yml to include all project documentation files
   - ✅ Included README.md files in navigation structure
   - ✅ Added project documentation files (content-map.md, documentation-entry-refactoring.md, terminology.md)
   - ✅ Resolved exclusion list issues in mkdocs.yml
   - ✅ Addressed 404 errors for overview/README.md and other paths
   - ✅ Fixed "includes/abbreviations.md" navigation issue
   - ✅ Created documentation for terminology standardization
   
3. **Content Organization and Restructuring**
   - ✅ Reorganized documentation navigation with logical grouping in mkdocs.yml
   - ✅ Broke down large documentation pages into smaller, focused subtopic pages:
     - ✅ Broke down `deployment/scenarios.md` into individual scenario pages in a dedicated directory
     - ✅ Broke down `deployment/advanced-topics.md` into specialized subtopic pages
     - ✅ Broke down `approaches` section into subdirectories for each approach:
       - ✅ Created kubernetes-api/ directory with focused pages
       - ✅ Created debug-container/ directory with focused pages
       - ✅ Created sidecar-container/ directory with focused pages
       - ✅ Created helper-scripts/ directory with focused pages
     - ✅ Reorganized `security` section:
       - ✅ Created principles/ directory for security principles
         - ✅ Created least-privilege.md
         - ✅ Created ephemeral-creds.md
         - ✅ Created resource-isolation.md
         - ✅ Created secure-transport.md
         - ✅ Created index.md and inventory.md
       - ✅ Created risk/ directory for risk analysis
         - ✅ Created kubernetes-api.md
         - ✅ Created debug-container.md
         - ✅ Created sidecar-container.md
         - ✅ Created mitigations.md
         - ✅ Created model.md
         - ✅ Created index.md and inventory.md
       - ✅ Created compliance/ directory for compliance frameworks
         - ✅ Created approach-comparison.md
         - ✅ Created risk-documentation.md
         - ✅ Created index.md and inventory.md
       - ✅ Created threat-model/ directory for threat modeling
         - ✅ Created attack-vectors.md
         - ✅ Created lateral-movement.md
         - ✅ Created token-exposure.md
         - ✅ Created threat-mitigations.md
         - ✅ Created index.md and inventory.md
       - ✅ Created recommendations/ directory for security best practices
         - ✅ Created inventory.md
       - ✅ Updated security index.md and inventory.md to reflect new structure
     - ✅ Created proper navigation structure for these subsections
   - ✅ Created content-organization-approach.md documenting our approach to content organization
   - ✅ Enhanced inventory files to include all new content files
   - ✅ Improved cross-references between related topics
   - ✅ Created dedicated index.md files for each subsection to serve as topic overviews

3. **Documentation Entry Point Refactoring Progress**
   - ✅ Completed Phase 1: Analysis and Standardization:
     - ✅ Created standardized terminology document (project/terminology.md)
     - ✅ Defined clear document purposes (project/content-map.md)
     - ✅ Mapped cross-reference relationships between documents
     - ✅ Prepared content templates for each entry point
   - ✅ Completed Phase 2: Primary Document Refactoring:
     - ✅ Updated index.md with streamlined introduction
     - ✅ Refactored quickstart.md for technical implementers
     - ✅ Enhanced executive-summary.md for decision makers
     - ✅ Updated overview/README.md for technical architecture
   - ✅ Completed Phase 3: Visual and Navigation Enhancements:
     - ✅ Developed and implemented visual aids
     - ✅ Enhanced cross-document navigation
   - 🔄 Phase 4: Review and Refinement (Current Focus)
     - ✅ Analyzed documentation for inconsistencies and issues
     - ✅ Created documentation-review-plan.md with detailed implementation plan
     - ✅ Identified README.md vs index.md inconsistency as root cause of many navigation issues
     - ✅ Normalized documentation structure:
       - ✅ Created index.md files for key sections that were using README.md in navigation
       - ✅ Created index.md files for overview, approaches, architecture, security, rbac, service-accounts, tokens
       - ✅ Updated the navigation in mkdocs.yml to use index.md files consistently
       - ✅ Preserved README.md files as GitHub browsing friendly overviews
       - 🔄 Fixing broken links that point to old README.md files
     - 🔄 Validating user journey paths
     - 🔄 Checking for terminology consistency
     - 🔄 Addressing content redundancies

4. **Documentation Structure Normalization (Significant Progress Made)**
   - ✅ Identified the cause of 404 errors: inconsistent use of README.md vs index.md
   - ✅ Established pattern: index.md for documentation content, README.md for GitHub browsing
   - ✅ Created index.md files for core documentation sections:
     - ✅ overview/index.md
     - ✅ approaches/index.md 
     - ✅ architecture/index.md
     - ✅ security/index.md
     - ✅ rbac/index.md
     - ✅ service-accounts/index.md
     - ✅ tokens/index.md
     - ✅ kubernetes-setup/index.md
   - ✅ Updated mkdocs.yml navigation to point to index.md files
   - ✅ Fixed the critical content mismatch in kubernetes-api.md:
     - ✅ Created proper kubernetes-api.md file with correct content about the Kubernetes API approach
     - ✅ Updated debug-container.md to incorporate scanning aspects
     - ✅ Maintained the content in approaches/index.md as landing page
   - ✅ Started fixing cross-references between documents:
     - ✅ Updated links in overview/quickstart.md
     - ✅ Updated links in security/overview.md 
     - ✅ Created and updated links in kubernetes-setup/ directory
   - 🔄 Continuing to fix remaining link warnings in other files
   - 🔄 Updating remaining cross-references between documents

4. **Documentation Tool Development**
   - ✅ Enhanced documentation preview system with better logging
   - ✅ Added `--log` flag to enable logging with flexible options:
     - Default logging to .mkdocs-server.log
     - Custom log file path with `--log path/to/file.log`
   - ✅ Implemented smart log viewing functionality with multiple options:
     - View last 25 lines by default
     - View specific number of lines with `--lines=N` or `-n N`
     - View entire log with `--all` option
   - ✅ Added process management for documentation server

### Next Steps

1. **Continue Documentation Structure Enhancement (Current Priority - March 25, 2025)**
   - 🔄 Continue applying the content organization pattern to large documentation sections:
     - ✅ Completed security section reorganization:
       - ✅ Created directory structure (principles/, risk/, compliance/, threat-model/, recommendations/)
       - ✅ Created index and inventory files for all subdirectories
       - ✅ Created comprehensive content files in all subdirectories
       - ✅ Extracted content from original files to focused files
       - ✅ Updated cross-references
       - ✅ Updated main security/index.md and inventory.md
     - ✅ Completed Helm Charts section reorganization:
       - ✅ Analyzed current content structure
       - ✅ Created logical subdirectory organization:
         - ✅ Created overview/ directory for high-level overview and architecture
         - ✅ Created scanner-types/ directory for scanner-specific documentation
         - ✅ Created infrastructure/ directory for RBAC, service accounts, and namespaces
         - ✅ Created usage/ directory for customization and configuration
         - ✅ Created security/ directory for security-related documentation
         - ✅ Created operations/ directory for troubleshooting and maintenance
       - ✅ Created index.md and inventory.md files for all subdirectories
       - ✅ Extracted content from original files to focused files in each subdirectory
       - ✅ Updated main helm-charts/index.md as a redirect
       - ✅ Updated helm-charts/inventory.md with new structure
       - ✅ Updated navigation in mkdocs.yml for Helm Charts section
     - ✅ Completed Configuration section reorganization:
       - ✅ Analyzed current content structure
       - ✅ Created logical subdirectory organization:
         - ✅ Created kubeconfig/ directory for kubeconfig configuration
         - ✅ Created thresholds/ directory for threshold configuration
         - ✅ Created plugins/ directory for plugin customization
         - ✅ Created integration/ directory for integration configuration
         - ✅ Created security/ directory for security configuration
       - ✅ Created index.md and inventory.md files for all subdirectories
       - ✅ Extracted content from original files to focused files in each subdirectory
       - ✅ Updated main configuration/index.md as an overview
       - ✅ Updated configuration/inventory.md with new structure
       - ✅ Updated navigation in mkdocs.yml for Configuration section
       - ✅ Added redirects from legacy files to new structure
     - 📅 Plan Architecture section reorganization
     - 📅 Plan Integration section reorganization
   - 🔄 Address high-priority documentation gaps before v1.0.0 release
   - 🔄 Complete Phase 4 of documentation entry point refactoring:
     - 🔄 Conducting comprehensive documentation review
     - 🔄 Validating user journey paths
     - 🔄 Testing documentation flow from different perspectives
   - 🔄 Continue refining documentation tools and processes:
     - ✅ Enhanced docs-tools.sh script with comprehensive logging functionality
     - ✅ Added flexible log viewing options with intelligent defaults
     - ✅ Implemented process management for documentation server
     - ✅ Added custom log file path support
     - 📅 Implement documentation validation tools
     - 📅 Add automation for structure verification

2. **Complete Container Scanning Approaches Implementation**
   - **Approach 1 - Modified Plugin (Enterprise Solution):**
     - 🔄 Fork and modify the train-k8s-container plugin to support distroless containers
     - 🔄 Implement ephemeral container detection and integration directly in the plugin
     - 🔄 Add automatic fallback to ephemeral containers when shell access fails
     - 🔄 Create examples and documentation for this approach
     
   - **CI/CD Integration for All Approaches:**
     - ✅ GitHub Actions workflow for debug container approach
     - ✅ GitHub Actions workflow for sidecar container approach
     - 🔄 GitHub Actions workflow for modified plugin approach
     - ✅ GitLab CI pipeline for debug container approach 
     - ✅ GitLab CI pipeline for sidecar container approach
     - 🔄 GitLab CI pipeline for modified plugin approach
     - ✅ GitLab CI with Services for sidecar container approach
     - 🔄 Comparative demonstration pipelines

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

5. **Latest Status (March 25, 2025)**:
   - ✅ Three scanning approaches implemented (standard, debug container, sidecar container)
   - ✅ CI/CD integration for all approaches (GitLab CI, GitHub Actions)
   - ✅ Comprehensive documentation with workflow diagrams
   - ✅ Security-focused design with least privilege RBAC
   - 🔄 Modified transport plugin approach in progress
   - ✅ Complete documentation reorganization and structure implementation
   - ✅ Enhanced MkDocs implementation with optimized navigation
   - ✅ Standardized terminology and content structure across documentation
   - ✅ Implemented documentation entry point refactoring plan through Phase 3
   - ✅ Enhanced documentation tools with comprehensive features
   - ✅ Added advanced logging functionality to documentation system
   - ✅ Created audience-specific documentation paths
   - ✅ Fixed navigation issues and addressed 404 errors
   - 🔄 Working on Phase 4 (Review and Refinement) of documentation refactoring
   - ✅ Reorganized approaches section into focused subdirectories with dedicated content files
   - ✅ Reorganized security section into principles, risk, compliance, threat-model, and recommendations subdirectories with comprehensive content

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

## References

- MITRE SAF-CLI: https://saf-cli.mitre.org/
- MITRE SAF Thresholds: https://github.com/mitre/saf/wiki/Validation-with-Thresholds/
- CINC Project: https://cinc.sh/
- train-k8s-container transport: https://github.com/inspec/train-k8s-container
- Kubernetes RBAC: https://kubernetes.io/docs/reference/access-authn-authz/rbac/
- Kubernetes Ephemeral Containers: https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/
- CINC Auditor Docker: https://gitlab.com/cinc-project/docker-images/-/tree/master/docker-auditor