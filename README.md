# Secure CINC Auditor Kubernetes Container Scanning

This project provides a comprehensive platform for securely scanning Kubernetes containers through multiple methodologies, leveraging CINC Auditor (open source InSpec) with security-focused RBAC configurations. It enables secure container compliance scanning across both standard and distroless containers in any Kubernetes environment.

## Project Overview

Our solution offers three distinct technical approaches for container scanning:

1. **Kubernetes API Approach** (Recommended): Direct API-based scanning through the Kubernetes API using the train-k8s-container plugin. This is our recommended enterprise solution with future distroless support in development, offering the most scalable and seamless integration. Once distroless support is implemented, this will be a universal solution for all container types.
2. **Debug Container Approach**: Ephemeral debug container with chroot-based scanning for distroless containers, ideal for environments with ephemeral container support.
3. **Sidecar Container Approach**: CINC Auditor sidecar container with shared process namespace for any container type, offering universal compatibility across Kubernetes versions.

These approaches can be deployed via:
- Self-contained shell scripts for direct management and testing
- Modular Helm charts for declarative, enterprise deployment
- CI/CD integration with GitHub Actions and GitLab CI for both minikube-based and existing Kubernetes clusters

The platform works in both local minikube environments and existing production Kubernetes clusters, with specialized security controls that address the fundamental challenges of privileged container scanning:

1. **Least Privilege Access** - Restrict scanning to specific containers only
2. **Dynamic Access Control** - Create temporary, targeted access for scanning
3. **CI/CD Integration** - Ready-to-use scripts and templates for pipeline integration
4. **Threshold Validation** - Integration with MITRE SAF CLI for compliance validation
5. **Distroless Support** - Specialized approach for scanning distroless containers
6. **Modular Deployment** - Supporting both script-based and Helm-based approaches

## Current Status (March 2025)

The project currently offers two complete deployment methods:

1. **Shell Script Approach** - Simple, self-contained scripts for setup and scanning
2. **Helm Chart Approach** - Modular Helm charts for more complex deployments

Both approaches support:
- Standard container scanning
- Threshold validation with MITRE SAF CLI
- CI/CD pipeline integration
- Dynamic RBAC with least privilege
- Token-based authentication

### Distroless Container Support Status

We now provide three distinct approaches for scanning distroless containers:

1. **Kubernetes API Approach** (Enterprise Recommended) - Enhanced train-k8s-container plugin for direct, API-based scanning:
   - **Implementation**: Currently being developed as our strategic enterprise solution
   - **Advantage**: No additional containers required, most efficient and scalable approach
   - **Advantage**: Seamless integration with existing CINC Auditor/InSpec workflows
   - **Advantage**: Transparent to users - same commands for both standard and distroless containers
   - **Key Advantage**: Will become a universal solution for all container types once distroless support is implemented
   - **Status**: In active development with high priority for enterprise environments

2. **Debug Container Approach** - Uses `kubectl debug` to attach a debug container and scan via chroot:
   - **Implementation**: The `scan-distroless-container.sh` script demonstrates this approach
   - **Limitation**: Requires Kubernetes clusters with ephemeral container support enabled
   - **Use Case**: Best for testing and development environments with ephemeral container support

3. **Sidecar Container Approach** - Deploys a scanner sidecar in the same pod with shared process namespace:
   - **Implementation**: Fully implemented in `scan-with-sidecar.sh` and integrated with CI/CD examples
   - **Advantage**: Works with any Kubernetes cluster, requires no special features
   - **Advantage**: Can scan any container type, including distroless containers
   - **Limitation**: Must be deployed alongside the target container (can't scan existing containers)
   - **Use Case**: Ideal for environments without ephemeral container support or for universal compatibility

## Directory Structure

```
.
├── docs/                    # Comprehensive documentation
│   ├── approaches/          # Scanning approach documentation
│   │   ├── comparison.md    # Comparison of scanning approaches
│   │   ├── decision-matrix.md # Decision matrix for approach selection
│   │   ├── kubernetes-api.md # Kubernetes API approach documentation
│   │   ├── debug-container.md # Debug container approach documentation
│   │   ├── sidecar-container.md # Sidecar container approach documentation
│   │   └── direct-commands.md # Direct command usage documentation
│   ├── architecture/        # Architecture documentation
│   │   ├── diagrams.md      # Workflow diagrams for all approaches
│   │   └── workflows.md     # Workflow process documentation
│   ├── configuration/       # Configuration documentation
│   │   ├── README.md        # Kubeconfig generation
│   │   └── advanced/        # Advanced configuration
│   │       ├── thresholds.md # Threshold configuration guide
│   │       └── saf-cli-integration.md # SAF CLI integration guide
│   ├── developer-guide/     # Development and testing documentation
│   │   ├── testing/         # Testing documentation
│   │   └── deployment/      # Deployment scenarios
│   ├── helm-charts/         # Helm chart documentation
│   │   ├── overview.md      # Helm charts overview
│   │   ├── architecture.md  # Helm chart architecture
│   │   └── scanner-infrastructure/ # Scanner infrastructure documentation
│   ├── integration/         # CI/CD integration guides
│   │   ├── overview.md      # Integration overview
│   │   ├── approach-mapping.md # Mapping approaches to CI/CD
│   │   ├── gitlab.md        # Standard GitLab CI integration
│   │   ├── gitlab-services.md # GitLab CI with services integration
│   │   └── github-actions.md # GitHub Actions integration
│   ├── kubernetes-setup/    # Kubernetes setup documentation
│   │   └── README.md        # Kubernetes setup overview
│   ├── project/             # Project documentation
│   │   ├── changelog.md     # Detailed changelog
│   │   ├── roadmap.md       # Project roadmap and timeline
│   │   ├── tasks.md         # Task tracking
│   │   └── documentation-gaps.md # Documentation gaps analysis
│   ├── rbac/                # RBAC configuration guides
│   ├── security/            # Security documentation
│   │   ├── analysis.md      # Security analysis
│   │   ├── compliance.md    # Compliance documentation
│   │   ├── overview.md      # Security overview
│   │   └── risk-analysis.md # Risk analysis
│   ├── service-accounts/    # Service account setup
│   └── tokens/              # Token management
├── scripts/                 # Automation scripts
│   ├── generate-kubeconfig.sh  # Generate restricted kubeconfig
│   ├── scan-container.sh    # End-to-end container scanning
│   ├── scan-distroless-container.sh # Scanning distroless containers
│   ├── scan-with-sidecar.sh # Scanning with sidecar container approach
│   └── setup-minikube.sh    # Multi-node minikube setup script
├── kubernetes/              # Kubernetes manifests
│   └── templates/           # Template YAML files
├── helm-charts/             # Modular Helm charts for deployment
│   ├── scanner-infrastructure/ # Core RBAC, service accounts
│   ├── common-scanner/      # Common scanning components 
│   ├── standard-scanner/    # Standard container scanning
│   ├── distroless-scanner/  # Distroless container scanning
│   └── sidecar-scanner/     # Sidecar approach for container scanning
├── github-workflow-examples/ # GitHub Actions workflow examples
│   ├── setup-and-scan.yml   # Basic setup and scan workflow
│   ├── dynamic-rbac-scanning.yml # Dynamic pod scanning with RBAC
│   ├── ci-cd-pipeline.yml   # Complete CI/CD pipeline with scanning
│   └── sidecar-scanner.yml  # Sidecar container scanning workflow
├── gitlab-pipeline-examples/ # GitLab CI examples
│   ├── gitlab-ci.yml        # Standard GitLab CI configuration
│   ├── gitlab-ci-with-services.yml # GitLab CI with services
│   ├── gitlab-ci-sidecar.yml # GitLab CI with sidecar approach
│   └── gitlab-ci-sidecar-with-services.yml # GitLab CI sidecar with services
└── examples/                # Example resources
    ├── cinc-profiles/       # Example CINC Auditor profiles
    ├── cinc-auditor-scanner/ # Dockerfile for scanner sidecar container
    └── sidecar-scanner-pod.yaml # Example sidecar container pod
```

## Quick Start

### Option 1: Automated Minikube Setup (Shell Script Approach)

The quickest way to set up a test environment is using our automated setup script:

```bash
# Set up a 3-node minikube cluster with standard containers
./scripts/setup-minikube.sh

# For distroless container scanning support (experimental)
./scripts/setup-minikube.sh --with-distroless

# For a customized setup
./scripts/setup-minikube.sh --nodes=2 --driver=virtualbox --install-deps
```

The script will:
1. Check and optionally install dependencies
2. Create a multi-node minikube cluster
3. Deploy the necessary RBAC and service accounts using kubectl directly (not Helm)
4. Set up test pods
5. Generate a kubeconfig file
6. Provide instructions for running scans

### Option 2: Manual Deployment

1. Set up the Kubernetes resources:

```bash
kubectl apply -f kubernetes/templates/namespace.yaml
kubectl apply -f kubernetes/templates/service-account.yaml
kubectl apply -f kubernetes/templates/rbac.yaml
kubectl apply -f kubernetes/templates/test-pod.yaml
```

2. Generate a kubeconfig file:

```bash
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml
```

3. Run a CINC Auditor scan:

```bash
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
  -t k8s-container://inspec-test/inspec-target/busybox
```

4. Process results with SAF CLI (optional):

```bash
# Generate a summary report
saf summary --input inspec-results.json --output-md summary.md

# Validate against threshold requirements
saf threshold -i inspec-results.json -t threshold.yml
```

### Option 3: Modular Helm Charts (Helm Approach)

We provide specialized Helm charts as an alternative deployment method:

#### Standard Container Scanning

```bash
# Install the standard-scanner chart
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true

# Generate a kubeconfig and run a scan
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
  -t k8s-container://inspec-test/inspec-target/busybox
```

#### Distroless Container Scanning

We provide three approaches for scanning distroless containers:

##### Approach 1: Ephemeral Debug Container (Requires Kubernetes 1.18+)

```bash
# Install the distroless-scanner chart
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true

# Generate a kubeconfig and run a specialized scan
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml
./scripts/scan-distroless-container.sh inspec-test distroless-target distroless ./examples/cinc-profiles/container-baseline
```

##### Approach 2: Sidecar Container (Recommended, works with any Kubernetes cluster)

```bash
# Deploy a pod with sidecar container for scanning
kubectl apply -f examples/sidecar-scanner-pod.yaml

# Wait for the pod to be ready
kubectl wait --for=condition=ready pod/app-scanner -n inspec-test --timeout=300s

# Check scan results directly from the sidecar
kubectl exec -it app-scanner -n inspec-test -c scanner -- cat /results/scan-summary.md
```

##### Approach 3: Sidecar Container with CI/CD Integration

We provide ready-to-use CI/CD examples for the sidecar approach:

- GitLab CI: `gitlab-examples/gitlab-ci-sidecar.yml`
- GitLab CI with Services: `gitlab-examples/gitlab-ci-sidecar-with-services.yml`
- GitHub Actions: `github-workflows/sidecar-scanner.yml`

These examples automatically deploy, scan, and retrieve results from a scanner sidecar container.

See the [Distroless Container Documentation](docs/distroless-containers.md) and [Sidecar Container Approach](docs/sidecar-container-approach.md) for more details.

### Option 4: CI/CD Pipeline Integration

#### GitHub Actions

1. Copy the workflow files to your repository's `.github/workflows` directory:

```bash
mkdir -p .github/workflows
cp github-workflows/* .github/workflows/
```

2. Commit and push the changes
3. Run the workflows from the GitHub Actions tab in your repository

#### GitLab CI

1. Copy the `.gitlab-ci.yml` file to your repository root:

```bash
cp gitlab-examples/gitlab-ci.yml .gitlab-ci.yml
```

2. Customize the file for your environment
3. Commit and push the changes

## CI/CD Integration

For CI/CD pipelines, this project provides:

1. GitLab CI/CD example configurations in `gitlab-examples/`
2. GitHub Actions workflows in `github-workflows/`
3. Dynamic access creation scripts
4. Cleanup procedures to avoid resource leaks
5. SAF CLI integration for threshold validation

## Key Features

### Security-Focused Design

- No permanent elevated privileges
- No shared access between scans
- Time-limited token generation (default: 15 minutes)
- Fine-grained RBAC controls
- Namespace isolation

### Flexibility

- Support for label-based scanning
- Support for named resource restrictions
- Multiple deployment methods (scripts or Helm)
- Configurable threshold validation
- Modular Helm chart structure

### Ease of Use

- Comprehensive documentation
- Ready-to-use scripts
- Helm chart deployment
- Example profiles and configurations
- GitHub Actions and GitLab CI integration

## SAF CLI Integration

The project integrates with [MITRE Security Automation Framework (SAF) CLI](https://saf-cli.mitre.org/) for:

1. Results processing and summary generation
2. Threshold validation for compliance requirements
3. JSON, Markdown, and HTML report generation

Example threshold configuration:

```yaml
# threshold.yml
compliance:
  min: 80  # Minimum 80% compliance required
failed:
  critical:
    max: 0  # No critical failures allowed
  high:
    max: 2  # Maximum 2 high failures allowed
```

## Documentation

### Online Documentation

Visit our comprehensive documentation at:

- https://mitre.github.io/kube-cinc-secure-scanner/

### Documentation Management

We provide a comprehensive documentation system with tools for previewing, validating, and improving documentation quality:

```bash
# Use the documentation tools script from the project root
./docs-tools.sh preview     # Preview documentation (background server)
./docs-tools.sh status      # Check server status
./docs-tools.sh restart     # Restart server
./docs-tools.sh stop        # Stop server
./docs-tools.sh setup       # Install all documentation dependencies
./docs-tools.sh lint        # Check Markdown style
./docs-tools.sh fix         # Fix common Markdown issues
./docs-tools.sh check-all   # Run comprehensive quality checks
./docs-tools.sh help        # See all available commands
```

#### Documentation Tools and CI/CD Scripts

This project provides two main scripts for documentation management:

1. **`docs-tools.sh`** - Interactive documentation management tool for developers:
   - Located at: Available both in project root (symlinked) and in `docs/docs-tools.sh` (original)
   - Purpose: Day-to-day documentation development and testing
   - Features: Preview server, linting, spell checking, link validation, and more
   - Usage: Run from either location with `./docs-tools.sh [command]`
   - Note: The script automatically adapts to being run from either location

2. **`docs-ci.sh`** - Automated documentation validation for CI/CD pipelines:
   - Located at: Project root
   - Purpose: Verify documentation quality in automated builds
   - Features: Non-interactive validation for continuous integration
   - Usage: Used by CI/CD pipelines or run with `./docs-ci.sh [--help]` to validate locally
   - Supports: `--help` flag for usage information and `--verbose` flag for detailed output

The documentation system includes:
- MkDocs with Material theme for beautiful documentation
- Markdown style checking with markdownlint
- Spell checking with pyspelling
- Link validation with linkchecker
- Comprehensive quality validation tools

For more details, see [Documentation Management](docs/README.md)

### Documentation Structure

Our documentation covers the following areas:

#### Core Documentation
- [Project Overview](docs/overview/README.md)
- [Quick Start Guide](docs/overview/quickstart.md)
- [Security Considerations](docs/overview/security.md)
- [Executive Summary](docs/overview/executive-summary.md)
- [Security Risk Analysis](docs/security/risk-analysis.md)
- [Security Analysis](docs/security/analysis.md)
- [Compliance Documentation](docs/security/compliance.md)

#### Approach-Specific Documentation
- [Approach Comparison](docs/approaches/comparison.md)
- [Decision Matrix](docs/approaches/decision-matrix.md)
- [Kubernetes API Approach](docs/approaches/kubernetes-api.md)
- [Debug Container Approach](docs/approaches/debug-container.md)
- [Sidecar Container Approach](docs/approaches/sidecar-container.md)
- [Direct Commands](docs/approaches/direct-commands.md)

#### Visual Documentation
- [Workflow Diagrams](docs/architecture/diagrams.md) - Mermaid diagrams for visual environments
- [ASCII Text Diagrams](docs/project/archive/ascii-diagrams.md) - Terminal-friendly diagrams

#### Technical Implementation
- [RBAC Configuration](docs/rbac/README.md)
- [Label-based RBAC](docs/rbac/label-based.md)
- [Service Account Management](docs/service-accounts/README.md)
- [Token Management](docs/tokens/README.md)
- [Kubeconfig Generation](docs/configuration/README.md)
- [Scanner Configuration](docs/configuration/advanced/README.md)
- [SAF CLI Integration](docs/configuration/advanced/saf-cli-integration.md)
- [Threshold Configuration](docs/configuration/advanced/thresholds.md)

#### CI/CD Integration
- [Integration Overview](docs/integration/overview.md)
- [Approach Mapping](docs/integration/approach-mapping.md)
- [GitLab CI/CD Integration](docs/integration/gitlab.md)
- [GitLab CI with Services](docs/integration/gitlab-services.md)
- [GitLab Services Analysis](docs/integration/gitlab-services-analysis.md)
- [GitHub Actions Integration](docs/integration/github-actions.md)

#### Helm Charts Documentation
- [Helm Charts Overview](docs/helm-charts/overview.md)
- [Helm Chart Architecture](docs/helm-charts/architecture.md)
- [Scanner Infrastructure](docs/helm-charts/scanner-infrastructure.md)
- [Common Scanner](docs/helm-charts/common-scanner.md)
- [Kubernetes API Scanner](docs/helm-charts/standard-scanner.md)
- [Debug Container Scanner](docs/helm-charts/distroless-scanner.md)
- [Sidecar Container Scanner](docs/helm-charts/sidecar-scanner.md)

#### Development and Testing
- [Testing Guide](docs/developer-guide/testing/README.md)
- [Deployment Scenarios](docs/developer-guide/deployment/README.md)
- [Documentation Tools](docs/contributing/documentation-tools.md)

## Requirements

- Kubernetes 1.24+ (for token creation API)
- kubectl
- CINC Auditor with train-k8s-container plugin
- MITRE SAF CLI (for threshold validation)
- Helm 3.2.0+ (for Helm deployment)

## Current Status and Future Work

### Project Status (March 2025)
- **Overall Project Completion**: ~90%
- **Documentation Completion**: 95%
- **Core Functionality**: 100%
- **Testing Coverage**: 70%
- **Next Major Milestone**: Complete Approach 1 implementation and v1.0.0 release
- **Target Release Date**: May 2025

### Implementation Status

1. **Distroless Container Scanning**: 
   - ✅ Implemented three distinct approaches:
     - ✅ Ephemeral debug container (requires special cluster feature)
     - ✅ Sidecar container with shared process namespace (works universally)
     - 🔄 Modified transport plugin (20% complete, in progress)
   - ✅ Integrated all approaches with CI/CD examples
   - ✅ Created comprehensive documentation for all approaches
   - ✅ Completed approach comparison and decision matrix
   - 🔄 Future work will focus on completing the transport plugin approach

2. **Documentation and Resources**: 
   - ✅ Implemented comprehensive MkDocs documentation system
   - ✅ Created workflow diagrams for all scanning approaches
   - ✅ Developed security analysis and risk documentation
   - ✅ Added enterprise integration analysis documentation
   - ✅ Reorganized documentation into logical structure
   - ✅ Identified documentation gaps for contribution
   - ✅ Implemented dark/light mode support for diagrams
   - 🔄 Addressing high-priority documentation gaps before v1.0.0 release

3. **CI/CD Integration**:
   - ✅ GitLab CI standard pipeline
   - ✅ GitLab CI with services
   - ✅ GitLab CI for sidecar approach
   - ✅ GitLab CI with services for sidecar approach
   - ✅ GitHub Actions for standard approach
   - ✅ GitHub Actions for sidecar approach
   - ✅ Comprehensive integration documentation
   - 🔄 Future work will include examples for other CI/CD platforms

4. **Performance and Container Images**:
   - ✅ Implemented services-based approach for GitLab CI
   - ✅ Created optimized sidecar container implementations
   - 🔄 Future work will include building and publishing dedicated CINC Auditor scanner containers
   - 🔄 Creating specialized debug container with CINC Auditor pre-installed
   - 🔄 Creating sidecar container images with optimized configurations
   - 🔄 Performance optimization with large-scale scanning

### Development Roadmap

For a detailed view of our roadmap and project status, see:
- [Project Roadmap](docs/project/roadmap.md) - Detailed roadmap with phase completion percentages
- [Task Tracker](docs/project/tasks.md) - Comprehensive task list with completion status
- [Changelog](docs/project/changelog.md) - Detailed record of recent changes and improvements
- [Documentation Gaps](docs/project/documentation-gaps.md) - Analysis of remaining documentation needs

---

🤖 Generated with [Claude Code](https://claude.ai/code)  
Co-Authored-By: Claude <noreply@anthropic.com>