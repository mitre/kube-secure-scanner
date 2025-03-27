# GitHub Actions Integration

## Overview

!!! security-focus "Security Emphasis"
    GitHub Actions workflows have access to your Kubernetes clusters, containers, and can potentially access sensitive information. This task implements security best practices including least-privilege RBAC, ephemeral credentials, and secure token management to minimize risk.

This task guides you through integrating Kube CINC Secure Scanner with GitHub Actions. Completing this task will enable you to automate container security scanning within your CI/CD pipeline while maintaining a strong security posture. The integration supports both standalone scanning of existing containers and fully automated end-to-end CI/CD pipelines with dynamic container building, deployment, and scanning.

**Time to complete:** 30-45 minutes

**Security risk:** 🟡 Medium - Requires GitHub Actions with Kubernetes cluster access

**Security approach:** Implements secure CI/CD integration with ephemeral credentials, dynamic RBAC generation, and proper permission boundaries between GitHub and Kubernetes resources

## Security Architecture

???+ abstract "Understanding Permission Layers"
    Integrating GitHub Actions with Kubernetes scanning requires managing multiple permission layers:

    **1. GitHub Runner/Pipeline Permissions**
    * **Control:** Access to GitHub repository resources, ability to run workflows, upload artifacts
    * **Risk area:** Could expose repository secrets or allow unauthorized workflow execution
    * **Mitigation:** Grant GitHub Actions only the necessary permissions to perform its tasks
    
    **2. User/CI System Kubernetes Permissions**
    * **Control:** Initial access to create and manage Kubernetes resources, including RBAC setup
    * **Risk area:** Overly permissive access could allow broader cluster access than needed
    * **Mitigation:** Use a service account with limited namespace access for CI/CD operations
    
    **3. Container Scanner RBAC Permissions**
    * **Control:** What the scanner itself can access within Kubernetes during scan operations
    * **Risk area:** Scanning permissions that are too broad could allow access to unintended resources
    * **Mitigation:** Generate short-lived, minimal-scope tokens scoped only to target containers
    
    The workflows in this guide demonstrate proper separation of these permission layers with dynamically generated RBAC permissions that are valid only for the specific scan operation and automatically cleaned up afterward.

## Security Prerequisites

- [ ] A GitHub repository where you have permissions to create workflows
- [ ] A Kubernetes cluster that meets the [requirements for existing clusters](../kubernetes-setup/existing-cluster-requirements.md)
- [ ] Understanding of [Kubernetes RBAC](../rbac/index.md) for creating secure service accounts
- [ ] An authenticated environment where you can run `kubectl` commands
- [ ] A [Kubernetes setup](../kubernetes-setup/index.md) with appropriate permissions

## Step-by-Step Instructions

In this guide, we'll cover two main integration approaches:

1. Basic container scanning workflow for existing containers
2. End-to-end CI/CD pipeline that builds, deploys, and scans containers dynamically

### Approach 1: Basic Container Scanning Workflow

!!! security-note "Security Consideration"
    We'll start with the most secure approach (standard container scanning) with proper RBAC controls. This workflow only accesses what it needs through temporary credentials.

1. Create a `.github/workflows` directory in your repository if it doesn't already exist:

```bash
mkdir -p .github/workflows
```

2. Create a new workflow file called `container-scan.yml` in the `.github/workflows` directory:

```bash
touch .github/workflows/container-scan.yml
```

3. Copy the following secure workflow content to the file:

```yaml
name: Kubernetes Container Security Scan

on:
  workflow_dispatch:
    inputs:
      namespace:
        description: 'Kubernetes namespace to scan'
        required: true
        default: 'default'
      pod_name:
        description: 'Pod name to scan'
        required: true
      container_name:
        description: 'Container name to scan'
        required: true
      cinc_profile:
        description: 'CINC Auditor profile to run'
        required: true
        default: 'dev-sec/linux-baseline'
      threshold:
        description: 'Minimum passing score (0-100)'
        required: true
        default: '70'

jobs:
  scan-container:
    name: Scan Kubernetes Container
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up CINC Auditor environment
        run: |
          # Install CINC Auditor
          curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor
          
          # Install train-k8s-container plugin
          cinc-auditor plugin install train-k8s-container
          
          # Install SAF-CLI for result processing
          npm install -g @mitre/saf
          
          # Verify installation
          cinc-auditor --version
          cinc-auditor plugin list
          saf --version
      
      - name: Set up RBAC configuration
        env:
          NAMESPACE: ${{ github.event.inputs.namespace }}
          POD_NAME: ${{ github.event.inputs.pod_name }}
        run: |
          # Create service account
          kubectl create serviceaccount inspec-scanner -n ${NAMESPACE}
          
          # Create role with minimal permissions for the specific pod
          cat <<EOF | kubectl apply -f -
          apiVersion: rbac.authorization.k8s.io/v1
          kind: Role
          metadata:
            name: inspec-container-role
            namespace: ${NAMESPACE}
          rules:
          - apiGroups: [""]
            resources: ["pods"]
            verbs: ["get", "list"]
          - apiGroups: [""]
            resources: ["pods/exec"]
            verbs: ["create"]
            resourceNames: ["${POD_NAME}"]
          - apiGroups: [""]
            resources: ["pods/log"]
            verbs: ["get"]
            resourceNames: ["${POD_NAME}"]
          EOF
          
          # Create role binding
          cat <<EOF | kubectl apply -f -
          apiVersion: rbac.authorization.k8s.io/v1
          kind: RoleBinding
          metadata:
            name: inspec-container-rolebinding
            namespace: ${NAMESPACE}
          subjects:
          - kind: ServiceAccount
            name: inspec-scanner
            namespace: ${NAMESPACE}
          roleRef:
            kind: Role
            name: inspec-container-role
            apiGroup: rbac.authorization.k8s.io
          EOF
          
          # Verify RBAC setup
          kubectl get serviceaccount,role,rolebinding -n ${NAMESPACE}
      
      - name: Generate restricted kubeconfig
        env:
          NAMESPACE: ${{ github.event.inputs.namespace }}
        run: |
          # Get token (15 minute duration for security)
          TOKEN=$(kubectl create token inspec-scanner -n ${NAMESPACE} --duration=15m)
          
          # Get cluster information
          SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
          CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')
          
          # Create kubeconfig with minimal permissions
          cat > restricted-kubeconfig.yaml << EOF
          apiVersion: v1
          kind: Config
          preferences: {}
          clusters:
          - cluster:
              server: ${SERVER}
              certificate-authority-data: ${CA_DATA}
            name: scanner-cluster
          contexts:
          - context:
              cluster: scanner-cluster
              namespace: ${NAMESPACE}
              user: scanner-user
            name: scanner-context
          current-context: scanner-context
          users:
          - name: scanner-user
            user:
              token: ${TOKEN}
          EOF
          
          # Set secure permissions
          chmod 600 restricted-kubeconfig.yaml
          
          # Test the kubeconfig
          KUBECONFIG=restricted-kubeconfig.yaml kubectl get pods -n ${NAMESPACE}
      
      - name: Run CINC Auditor scan with restricted access
        env:
          NAMESPACE: ${{ github.event.inputs.namespace }}
          POD_NAME: ${{ github.event.inputs.pod_name }}
          CONTAINER_NAME: ${{ github.event.inputs.container_name }}
          CINC_PROFILE: ${{ github.event.inputs.cinc_profile }}
        run: |
          # Run CINC Auditor with the train-k8s-container transport
          KUBECONFIG=restricted-kubeconfig.yaml cinc-auditor exec ${CINC_PROFILE} \
            -t k8s-container://${NAMESPACE}/${POD_NAME}/${CONTAINER_NAME} \
            --reporter cli json:cinc-results.json
          
          # Store the exit code
          CINC_EXIT_CODE=$?
          echo "CINC Auditor scan completed with exit code: ${CINC_EXIT_CODE}"
      
      - name: Process results with SAF-CLI
        env:
          THRESHOLD: ${{ github.event.inputs.threshold }}
        run: |
          # Generate summary report with SAF-CLI
          echo "Generating scan summary with SAF-CLI:"
          saf summary --input cinc-results.json --output-md scan-summary.md
          
          # Display the summary in the logs
          cat scan-summary.md
          
          # Add to GitHub step summary
          echo "## CINC Auditor Scan Results" > $GITHUB_STEP_SUMMARY
          cat scan-summary.md >> $GITHUB_STEP_SUMMARY
          
          # Create a proper threshold file
          cat > threshold.yml << EOF
          compliance:
            min: ${THRESHOLD}
          failed:
            critical:
              max: 0  # No critical failures allowed
          EOF
          
          # Apply threshold check
          echo "Checking against threshold with min compliance of ${THRESHOLD}%:"
          saf threshold -i cinc-results.json -t threshold.yml
          THRESHOLD_EXIT_CODE=$?
          
          if [ $THRESHOLD_EXIT_CODE -eq 0 ]; then
            echo "✅ Security scan passed threshold requirements" | tee -a $GITHUB_STEP_SUMMARY
          else
            echo "❌ Security scan failed to meet threshold requirements" | tee -a $GITHUB_STEP_SUMMARY
            # Uncomment to enforce the threshold as a quality gate
            # exit $THRESHOLD_EXIT_CODE
          fi
      
      - name: Upload CINC Auditor results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: cinc-results
          path: |
            cinc-results.json
            scan-summary.md
      
      - name: Cleanup RBAC resources
        if: always()
        env:
          NAMESPACE: ${{ github.event.inputs.namespace }}
        run: |
          # Cleanup role and rolebinding
          kubectl delete rolebinding inspec-container-rolebinding -n ${NAMESPACE}
          kubectl delete role inspec-container-role -n ${NAMESPACE}
          kubectl delete serviceaccount inspec-scanner -n ${NAMESPACE}
```

### Step 2: Set Up GitHub Repository Permissions

!!! security-note "Security Consideration"
    GitHub Actions need proper permissions to upload artifacts and write step summaries. This is safe as it only affects GitHub Actions operations, not your Kubernetes cluster.

1. In your GitHub repository, go to **Settings** > **Actions** > **General**
2. Under "Workflow permissions", select "Read and write permissions"
3. Save your changes

### Step 3: Connect to Your Kubernetes Cluster

!!! security-note "Security Consideration"
    For production systems, you should store your Kubernetes credentials securely in GitHub Secrets. Never check kubeconfig files into your repository.

1. If your workflow will run against an existing Kubernetes cluster, create a GitHub Secret for your kubeconfig:

```bash
# First export your kubeconfig to a base64-encoded string
KUBECONFIG_B64=$(cat ~/.kube/config | base64 -w 0)
```

2. In GitHub, go to **Settings** > **Secrets and variables** > **Actions**
3. Create a new repository secret named `KUBE_CONFIG` with the value from the previous step

4. Modify the workflow to use this secret by adding this step before the RBAC setup:

```yaml
- name: Set up kubeconfig
  run: |
    mkdir -p ~/.kube
    echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > ~/.kube/config
    chmod 600 ~/.kube/config
    kubectl get nodes
```

### Approach 2: End-to-End CI/CD Pipeline with Dynamic RBAC

This approach demonstrates a complete end-to-end workflow that:

1. Builds a container using a simple Docker build process
2. Deploys it to Kubernetes with specific labels
3. Creates dynamic RBAC permissions specifically for that deployment
4. Scans the container using those permissions

Create a new workflow file called `ci-cd-pipeline.yml`:

```bash
touch .github/workflows/ci-cd-pipeline.yml
```

Add the following content:

```yaml
name: CI/CD Pipeline with Container Scanning

on:
  workflow_dispatch:
    inputs:
      image_tag:
        description: 'Tag for the container image'
        required: true
        default: 'scan-target'
      scan_namespace:
        description: 'Kubernetes namespace for scanning'
        required: true
        default: 'app-scan'
      threshold:
        description: 'Minimum passing score (0-100)'
        required: true
        default: '70'

jobs:
  build-deploy-scan:
    name: Build, Deploy and Scan Container
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Create application files for build
        run: |
          # Create a mock application directory
          mkdir -p ./app
          
          # Create a simple Dockerfile
          cat > ./app/Dockerfile << 'EOF'
          FROM alpine:latest
          
          # Add some packages for testing
          RUN apk add --no-cache bash curl nginx
          
          # Create a sample configuration file
          RUN mkdir -p /etc/app
          COPY app.conf /etc/app/app.conf
          
          # Set execution mode
          CMD ["nginx", "-g", "daemon off;"]
          EOF
          
          # Create a sample config file
          cat > ./app/app.conf << 'EOF'
          # Sample application configuration
          app_name=test-application
          log_level=info
          max_connections=100
          EOF
      
      - name: Set up Minikube
        uses: medyagh/setup-minikube@master
        with:
          driver: docker
          start-args: --nodes=2
      
      - name: Build and tag container image
        run: |
          # Use minikube's Docker daemon
          eval $(minikube docker-env)
          
          # Build the image with dynamic tag
          cd ./app
          docker build -t app-image:${{ github.event.inputs.image_tag }} .
          
          # List images to confirm build
          docker images | grep app-image
      
      - name: Deploy to Kubernetes
        run: |
          # Create namespace
          kubectl create namespace ${{ github.event.inputs.scan_namespace }}
          
          # Create deployment
          cat <<EOF | kubectl apply -f -
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: test-app
            namespace: ${{ github.event.inputs.scan_namespace }}
          spec:
            replicas: 1
            selector:
              matchLabels:
                app: test-app
            template:
              metadata:
                labels:
                  app: test-app
                  scan-target: "true"
              spec:
                containers:
                - name: app
                  image: app-image:${{ github.event.inputs.image_tag }}
                  imagePullPolicy: Never
                  ports:
                  - containerPort: 80
          EOF
          
          # Wait for deployment to be ready
          kubectl -n ${{ github.event.inputs.scan_namespace }} rollout status deployment/test-app --timeout=120s
          
          # Show running pods with labels
          kubectl get pods -n ${{ github.event.inputs.scan_namespace }} --show-labels
      
      - name: Install CINC Auditor and SAF-CLI
        run: |
          # Install CINC Auditor
          curl -L https://omnitruck.cinc.sh/install.sh | sudo bash -s -- -P cinc-auditor
          
          # Install train-k8s-container plugin
          cinc-auditor plugin install train-k8s-container
          
          # Install SAF-CLI
          npm install -g @mitre/saf
          
          # Verify installation
          cinc-auditor --version
          cinc-auditor plugin list
          saf --version
      
      - name: Create dynamic RBAC for scanning
        run: |
          # Generate a unique ID for this workflow run
          SCAN_ID=$(date +%s)
          echo "SCAN_ID=${SCAN_ID}" >> $GITHUB_ENV
          
          # Create service account
          kubectl create serviceaccount scanner-${SCAN_ID} -n ${{ github.event.inputs.scan_namespace }}
          
          # Create role with label selector permissions
          cat <<EOF | kubectl apply -f -
          apiVersion: rbac.authorization.k8s.io/v1
          kind: Role
          metadata:
            name: scanner-role-${SCAN_ID}
            namespace: ${{ github.event.inputs.scan_namespace }}
          rules:
          - apiGroups: [""]
            resources: ["pods"]
            verbs: ["get", "list"]
          - apiGroups: [""]
            resources: ["pods/exec"]
            verbs: ["create"]
          - apiGroups: [""]
            resources: ["pods/log"]
            verbs: ["get"]
          EOF
          
          # Create role binding
          kubectl create rolebinding scanner-binding-${SCAN_ID} \
            --role=scanner-role-${SCAN_ID} \
            --serviceaccount=${{ github.event.inputs.scan_namespace }}:scanner-${SCAN_ID} \
            -n ${{ github.event.inputs.scan_namespace }}
          
          # Generate short-lived token (15 minutes)
          TOKEN=$(kubectl create token scanner-${SCAN_ID} \
            -n ${{ github.event.inputs.scan_namespace }} \
            --duration=15m)
          
          # Get cluster information
          SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
          CA_DATA=$(kubectl config view --raw --minify --flatten \
            -o jsonpath='{.clusters[].cluster.certificate-authority-data}')
          
          # Create restricted kubeconfig
          cat > scanner-kubeconfig.yaml << EOF
          apiVersion: v1
          kind: Config
          preferences: {}
          clusters:
          - cluster:
              server: ${SERVER}
              certificate-authority-data: ${CA_DATA}
            name: scanner-cluster
          contexts:
          - context:
              cluster: scanner-cluster
              namespace: ${{ github.event.inputs.scan_namespace }}
              user: scanner-user
            name: scanner-context
          current-context: scanner-context
          users:
          - name: scanner-user
            user:
              token: ${TOKEN}
          EOF
          
          # Secure permissions
          chmod 600 scanner-kubeconfig.yaml
      
      - name: Run container scan with label selection
        run: |
          # Run CINC Auditor with label selection
          KUBECONFIG=scanner-kubeconfig.yaml cinc-auditor exec dev-sec/linux-baseline \
            -t k8s-container://${{ github.event.inputs.scan_namespace }}?pod_label=scan-target=true/app \
            --reporter cli json:scan-results.json
          
          # Check exit code
          SCAN_EXIT_CODE=$?
          echo "Scan completed with exit code: ${SCAN_EXIT_CODE}"
      
      - name: Process results with SAF-CLI
        run: |
          # Generate report summary
          saf summary --input scan-results.json --output-md scan-summary.md
          
          # Display summary in logs
          cat scan-summary.md
          
          # Add to GitHub step summary
          echo "## Container Security Scan Results" > $GITHUB_STEP_SUMMARY
          cat scan-summary.md >> $GITHUB_STEP_SUMMARY
          
          # Check compliance threshold
          echo "Checking against threshold of ${{ github.event.inputs.threshold }}%"
          saf threshold -i scan-results.json -t ${{ github.event.inputs.threshold }}
          THRESHOLD_EXIT_CODE=$?
          
          if [ $THRESHOLD_EXIT_CODE -eq 0 ]; then
            echo "✅ Security scan passed threshold requirements" | tee -a $GITHUB_STEP_SUMMARY
          else
            echo "❌ Security scan failed to meet threshold requirements" | tee -a $GITHUB_STEP_SUMMARY
            # Uncommenting the next line would fail the workflow when thresholds are not met
            # exit $THRESHOLD_EXIT_CODE
          fi
      
      - name: Upload scan results
        uses: actions/upload-artifact@v4
        with:
          name: security-scan-results
          path: |
            scan-results.json
            scan-summary.md
      
      - name: Cleanup resources
        if: always()
        run: |
          # Clean up Kubernetes resources
          kubectl delete rolebinding scanner-binding-${SCAN_ID} -n ${{ github.event.inputs.scan_namespace }} || true
          kubectl delete role scanner-role-${SCAN_ID} -n ${{ github.event.inputs.scan_namespace }} || true
          kubectl delete serviceaccount scanner-${SCAN_ID} -n ${{ github.event.inputs.scan_namespace }} || true
          kubectl delete namespace ${{ github.event.inputs.scan_namespace }} || true
```

### Step 4: Run the Workflows

#### For Basic Container Scanning

1. In your GitHub repository, go to the **Actions** tab
2. Select the "Kubernetes Container Security Scan" workflow
3. Click **Run workflow**
4. Fill in the required parameters:
   - **Namespace**: The Kubernetes namespace containing your target pod
   - **Pod name**: The name of the pod to scan
   - **Container name**: The specific container within the pod to scan
   - **CINC profile**: The profile to run (e.g., `dev-sec/linux-baseline`)
   - **Threshold**: The minimum passing score (0-100)
5. Click **Run workflow**

#### For End-to-End CI/CD Pipeline

1. In your GitHub repository, go to the **Actions** tab
2. Select the "CI/CD Pipeline with Container Scanning" workflow
3. Click **Run workflow**
4. Fill in the required parameters:
   - **Image tag**: A unique tag for your container image (default: scan-target)
   - **Scan namespace**: The namespace where the container will be deployed (default: app-scan)
   - **Threshold**: The minimum passing score (0-100) (default: 70)
5. Click **Run workflow**

### Step 5: Review Scan Results

!!! security-note "Security Consideration"
    Scan results may contain sensitive information about your container. GitHub Actions artifacts are only accessible to users with repository access.

1. After the workflow completes, go to the workflow run in the **Actions** tab
2. Scroll down to see the detailed logs
3. Review the workflow summary which shows the scan results overview
4. Download the artifacts to access the detailed JSON and Markdown reports

## Security Best Practices

- Use time-limited tokens (default: 15 minutes) to minimize the access window
- Configure RBAC to limit access to only the specific resources needed
- Enforce threshold requirements as quality gates in production pipelines
- Store sensitive information (like kubeconfig files) in GitHub Secrets
- Implement cleanup steps to remove temporary RBAC resources
- Verify that tokens have the minimal required permissions for scanning
- Run scans against immutable containers to ensure consistency

## Verification Steps

1. Confirm the workflow completed successfully

   ```bash
   # Check the Actions tab in GitHub or run
   gh run list --limit 1
   ```

2. Verify that the RBAC resources were properly created and then cleaned up

   ```bash
   # Should return "No resources found"
   kubectl get role inspec-container-role -n <namespace>
   kubectl get rolebinding inspec-container-rolebinding -n <namespace>
   kubectl get serviceaccount inspec-scanner -n <namespace>
   ```

3. Review the scan results and compliance score in the workflow summary

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Workflow fails with authentication errors** | Verify that the kubeconfig secret is correctly set up or that your GitHub Actions runner has proper access to the cluster |
| **RBAC permissions errors** | Check that the workflow is creating the correct RBAC resources with proper names and permissions |
| **Scan fails with access denied** | Verify that the generated token has the necessary permissions and that the pod/container exists |
| **Token expires during scan** | Increase the token duration (--duration=30m) for larger scans, but keep it as short as practically possible |
| **Threshold check fails** | Review the detailed scan results to identify failing controls, or adjust the threshold if appropriate |

## Next Steps

After completing this task, consider:

- [Configure threshold values](thresholds-configuration.md) for pass/fail criteria
- [Set up RBAC with label-based targeting](rbac-setup.md) for flexible container selection
- [Integrate with distroless containers](distroless-container-scan.md) if you need to scan distroless images
- [Implement sidecar container scanning](sidecar-container-scan.md) for specialized container types

## Related Security Considerations

- [Kubernetes RBAC Configuration](../rbac/index.md)
- [Ephemeral Security Credentials](../security/principles/ephemeral-creds.md)
- [Least Privilege Principle](../security/principles/least-privilege.md)
- [Token Management](../tokens/index.md)
- [Kubernetes Setup Best Practices](../kubernetes-setup/best-practices.md)
