# Release Notes - v1.0.0

## Secure CINC Auditor Kubernetes Container Scanning v1.0.0

We're excited to announce the first stable release of our Secure CINC Auditor Kubernetes Container Scanning platform. This release marks the culmination of extensive development to create a comprehensive, secure, and flexible solution for container compliance scanning in Kubernetes environments.

### Key Features

- **Three Container Scanning Approaches:**
  - Standard container scanning with train-k8s-container transport
  - Distroless container scanning via ephemeral debug containers
  - Sidecar container scanning with shared process namespace

- **Security-Focused Design:**
  - Least privilege RBAC configurations
  - Dynamic, time-limited access tokens
  - Fine-grained label-based access controls
  - Namespace isolation

- **Flexible Deployment Options:**
  - Self-contained shell scripts for direct usage
  - Modular Helm charts for enterprise deployment
  - CI/CD integration with GitHub Actions and GitLab CI

- **Comprehensive Documentation:**
  - MkDocs-based documentation site with enhanced navigation
  - Executive summary for stakeholders
  - Security risk analysis and mitigations
  - Approach decision matrix for informed selection
  - Enterprise integration analysis
  - Visual workflow diagrams and ASCII text diagrams

- **Integration Capabilities:**
  - MITRE SAF CLI for threshold validation
  - GitLab CI integration with services
  - GitHub Actions workflows
  - Comprehensive examples for all approaches

### What's Included

1. **Shell Scripts:**
   - `setup-minikube.sh` - Set up a test environment with multi-node minikube
   - `scan-container.sh` - Scan standard containers with CINC Auditor
   - `scan-distroless-container.sh` - Scan distroless containers with debug approach
   - `scan-with-sidecar.sh` - Scan containers using the sidecar approach
   - `generate-kubeconfig.sh` - Generate restricted kubeconfig files

2. **Helm Charts:**
   - `scanner-infrastructure` - Core RBAC, service accounts, tokens
   - `common-scanner` - Common scanning components and utilities
   - `standard-scanner` - Standard container scanning
   - `distroless-scanner` - Distroless container scanning
   - `sidecar-scanner` - Sidecar container scanning

3. **CI/CD Examples:**
   - GitHub Actions workflows for all scanning approaches
   - GitLab CI pipelines for all scanning approaches
   - GitLab CI with Services for optimized pipeline performance

4. **Documentation:**
   - Comprehensive MkDocs site with enhanced navigation
   - Full markdown documentation for all components
   - Visual workflow diagrams with Mermaid
   - ASCII text diagrams for terminal readability
   - Decision matrices and comparison guides

### Requirements

- Kubernetes 1.24+ (for token creation API)
- kubectl
- CINC Auditor with train-k8s-container plugin
- MITRE SAF CLI (for threshold validation)
- Helm 3.2.0+ (for Helm deployment)

For local documentation preview:
- Python 3.x
- MkDocs with Material theme (`pip install -r requirements.txt`)

### Future Development

- Complete the modified train-k8s-container plugin approach
- Build and publish dedicated CINC Auditor scanner images
- Create Kubernetes mutating webhook for sidecar injection
- Add additional CI/CD platform examples
- Enhance performance for large-scale scanning

### Acknowledgments

This project builds upon the work of:
- CINC Project (open-source InSpec)
- MITRE SAF CLI
- train-k8s-container transport plugin
- Kubernetes ephemeral containers feature