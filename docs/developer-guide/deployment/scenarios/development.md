# Development Environment

This guide provides a detailed approach for deploying the Secure CINC Auditor Kubernetes Container Scanning solution in a development environment.

## Use Case

Development teams needing quick setup for testing and developing applications with security scanning.

## Recommended Approach

**Script-based Deployment** is the recommended approach for development environments due to its simplicity and flexibility.

## Key Requirements

- Quick setup
- Minimal configuration
- Local development focus
- Rapid iteration

## Deployment Steps

### 1. Set Up Local Environment

First, use the setup script to configure a local development environment:

```bash
# Set up development environment with minikube
./kubernetes-scripts/setup-minikube.sh --dev-mode
```

This script:

- Creates a Minikube cluster if one doesn't exist
- Configures necessary RBAC permissions
- Sets up the scanner service account
- Configures the environment for scanning

### 2. Run On-Demand Scans

During development, run scans on demand to validate container security:

```bash
# Scan containers during development
./kubernetes-scripts/scan-container.sh default app-pod app-container profiles/dev-baseline

# Scan with custom profile path
./kubernetes-scripts/scan-container.sh default app-pod app-container ~/my-custom-profiles/baseline
```

### 3. Create Team Wrapper Scripts

To simplify usage for development teams, create custom wrapper scripts:

```bash
# Create a team-specific wrapper script
cat > scan-dev.sh << EOF
#!/bin/bash
# Team Development Scanner
NAMESPACE=\${1:-default}
POD=\${2:-app-pod}
CONTAINER=\${3:-app-container}
PROFILE=\${4:-profiles/dev-baseline}

./kubernetes-scripts/scan-container.sh \$NAMESPACE \$POD \$CONTAINER \$PROFILE
EOF

chmod +x scan-dev.sh
```

## Development-Specific Considerations

### Local Profile Development

For developing and testing custom security profiles:

```bash
# Create a new profile directory
mkdir -p my-profiles/custom-baseline

# Initialize a new profile
cinc-auditor init profile --platform k8s-container my-profiles/custom-baseline

# Edit the profile
code my-profiles/custom-baseline

# Test the profile
./kubernetes-scripts/scan-container.sh default app-pod app-container my-profiles/custom-baseline
```

### Quick Feedback Loop

Set up aliases for faster development workflow:

```bash
# Add to your .bashrc or .zshrc
alias k-scan='./kubernetes-scripts/scan-container.sh'
alias k-scan-distroless='./kubernetes-scripts/scan-distroless-container.sh'
alias k-scan-sidecar='./kubernetes-scripts/scan-with-sidecar.sh'
```

### Development Team Setup

For multiple developers working on the same project:

```bash
# Create a development config script
cat > dev-config.sh << EOF
#!/bin/bash
# Development Environment Setup
export KUBECONFIG=\$(pwd)/.kube/config
export SCANNER_NAMESPACE=dev-scanner
export INSPEC_PROFILE_PATH=\$(pwd)/profiles
export DEFAULT_THRESHOLD=\$(pwd)/thresholds/dev-thresholds.yml

# Create local scanner namespace
kubectl create namespace \$SCANNER_NAMESPACE 2>/dev/null || true

# Set up local profiles
mkdir -p \$INSPEC_PROFILE_PATH

echo "Development environment configured"
EOF

chmod +x dev-config.sh
```

## Validation and Testing

Verify your development setup with these tests:

1. Verify Minikube is running:

   ```bash
   minikube status
   ```

2. Test a basic scan:

   ```bash
   ./kubernetes-scripts/scan-container.sh default nginx nginx profiles/container-baseline
   ```

3. Check scan results:

   ```bash
   # View the latest results
   cat results.json | jq
   
   # Generate a report
   saf report -i results.json -o dev-report.html
   ```

4. Test profile modifications:

   ```bash
   # Edit a profile control
   nano profiles/container-baseline/controls/01_file_checks.rb
   
   # Run scan with modified profile
   ./kubernetes-scripts/scan-container.sh default nginx nginx profiles/container-baseline
   ```

## Troubleshooting Development Setups

Common issues in development environments:

1. **Minikube Issues**:

   ```bash
   # Restart Minikube if needed
   minikube stop
   minikube start
   
   # Check Minikube logs
   minikube logs
   ```

2. **Scanner Access Issues**:

   ```bash
   # Verify RBAC permissions
   kubectl auth can-i get pods --as system:serviceaccount:default:scanner-sa
   ```

3. **Profile Errors**:

   ```bash
   # Validate profile syntax
   cinc-auditor check profiles/container-baseline
   ```

## Related Topics

- [Script Deployment](../script-deployment.md)
- [Custom Profile Development](../advanced-topics/custom-development.md#custom-profile-development)
- [Local Testing](../../testing/index.md)
- [CI/CD Environment](cicd.md)
