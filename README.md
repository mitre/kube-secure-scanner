# Secure CINC Auditor Kubernetes Container Scanning

This project provides a comprehensive solution for securely scanning Kubernetes containers using CINC Auditor (open source InSpec) with the train-k8s-container transport.

## Project Overview

This solution addresses the security concerns around container scanning by implementing:

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

Distroless container scanning is currently implemented using ephemeral debug containers (via `kubectl debug`). This approach has some limitations:

- **Current Implementation**: The `scan-distroless-container.sh` script demonstrates this approach but contains placeholder code that needs custom implementation to work with your specific distroless containers.
- **Future Work**: We plan to modify the train-k8s-container plugin to natively support distroless containers without requiring container-specific customization.

## Directory Structure

```
.
├── docs/                    # Comprehensive documentation
│   ├── overview/            # Project overview and architecture
│   ├── rbac/                # RBAC configuration guides
│   ├── service-accounts/    # Service account setup
│   ├── configuration/       # Kubeconfig generation
│   ├── tokens/              # Token management
│   ├── integration/         # CI/CD integration guides
│   ├── saf-cli-integration.md # SAF CLI integration guide
│   ├── thresholds.md        # Threshold configuration guide
│   └── distroless-containers.md # Guide for scanning distroless containers
├── scripts/                 # Automation scripts
│   ├── generate-kubeconfig.sh  # Generate restricted kubeconfig
│   ├── scan-container.sh    # End-to-end container scanning
│   ├── scan-distroless-container.sh # Scanning distroless containers
│   └── setup-minikube.sh    # Multi-node minikube setup script
├── kubernetes/              # Kubernetes manifests
│   └── templates/           # Template YAML files
├── helm-chart/              # Legacy Helm chart for deployment
│   ├── templates/           # Helm templates
│   └── values.yaml          # Configuration values
├── helm-charts/             # Modular Helm charts
│   ├── scanner-infrastructure/ # Core RBAC, service accounts
│   ├── common-scanner/      # Common scanning components
│   ├── standard-scanner/    # Standard container scanning
│   └── distroless-scanner/  # Distroless container scanning
├── github-workflows/        # GitHub Actions workflow examples
│   ├── setup-and-scan.yml   # Basic setup and scan workflow
│   ├── dynamic-rbac-scanning.yml # Dynamic pod scanning with RBAC
│   └── ci-cd-pipeline.yml   # Complete CI/CD pipeline with scanning
├── gitlab-examples/         # GitLab CI examples
│   └── gitlab-ci.yml        # GitLab CI configuration
└── examples/                # Example resources
    └── cinc-profiles/       # Example CINC Auditor profiles
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

#### Distroless Container Scanning (Experimental)

```bash
# Install the distroless-scanner chart
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=inspec-test \
  --set testPod.deploy=true

# Generate a kubeconfig and run a specialized scan
./scripts/generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml
./scripts/scan-distroless-container.sh inspec-test distroless-target distroless ./examples/cinc-profiles/container-baseline
```

> **Note on Distroless Scanning**: The current distroless scanning implementation is experimental and demonstrates the approach using ephemeral debug containers. The `scan-distroless-container.sh` script contains placeholder code that will need customization for your specific distroless containers. See the [Distroless Container Documentation](docs/distroless-containers.md) for more details.

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

For detailed documentation, see the following guides:

- [Project Overview](docs/overview/README.md)
- [Quick Start Guide](docs/overview/quickstart.md)
- [Security Considerations](docs/overview/security.md)
- [RBAC Configuration](docs/rbac/README.md)
- [Service Account Management](docs/service-accounts/README.md)
- [Token Management](docs/tokens/README.md)
- [Kubeconfig Generation](docs/configuration/README.md)
- [SAF CLI Integration](docs/saf-cli-integration.md)
- [Threshold Configuration](docs/thresholds.md)
- [GitLab CI/CD Integration](docs/integration/gitlab.md)
- [GitHub Actions Integration](docs/integration/github-actions.md)
- [Distroless Container Scanning](docs/distroless-containers.md)

## Requirements

- Kubernetes 1.24+ (for token creation API)
- kubectl
- CINC Auditor with train-k8s-container plugin
- MITRE SAF CLI (for threshold validation)
- Helm 3.2.0+ (for Helm deployment)

## Current Limitations and Future Work

1. **Distroless Container Scanning**: The current implementation is experimental and requires customization for your specific distroless containers. Future work will focus on modifying the train-k8s-container plugin for native distroless support.

2. **Performance Optimization**: The current implementation focuses on functionality and security. Future work will optimize for performance with large-scale scanning.

3. **Additional CI/CD Examples**: We plan to add examples for other CI/CD platforms and more complex scanning scenarios.