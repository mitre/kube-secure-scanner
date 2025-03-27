# Code Display Demo

This page demonstrates the enhanced code display capabilities in our documentation.

## GitHub Actions Integration Examples

Below is an example of a GitHub Actions workflow for setting up and scanning containers:

```yaml
--8<-- "github-workflow-examples/setup-and-scan.yml"
```

### Highlighting Important Sections

Let's highlight the key parts of the configuration:

```yaml hl_lines="3-6 12-15"
--8<-- "github-workflow-examples/setup-and-scan.yml"
```

### Adding Annotations

Here's the same code with annotations explaining key components:

```yaml
--8<-- "github-workflow-examples/setup-and-scan.yml"
```

1. This is the workflow name that appears in the GitHub Actions tab
2. This workflow runs when code is pushed to the main branch
3. This section defines the environment variables used throughout the workflow
4. This job sets up the Kubernetes environment for scanning
5. This step uses the official GitHub Action for Kubernetes
6. The scanning job runs after the setup job completes successfully

## GitLab CI Integration

Let's compare with a GitLab CI configuration:

=== "GitLab CI Basic"
    ```yaml
    --8<-- "gitlab-pipeline-examples/gitlab-ci.yml"
    ```

=== "GitLab CI with Services"
    ```yaml
    --8<-- "gitlab-pipeline-examples/gitlab-ci-with-services.yml"
    ```

## Sidecar Scanner Configuration

This is a configuration for the sidecar container approach:

```yaml
--8<-- "github-workflow-examples/sidecar-scanner.yml"
```

### Key Configuration Elements

Let's break down the important configuration elements:

1. **Service Account**: The scanner requires appropriate RBAC permissions
2. **Container Configuration**: The scanner is deployed alongside the application container
3. **Volume Mounts**: Configuration is provided through ConfigMaps
4. **Environment Variables**: Control the scanner's behavior

## Comparing Different Approaches

Here's a comparison of different scanning approaches:

=== "Sidecar Approach"
    ```yaml
    --8<-- "github-workflow-examples/sidecar-scanner.yml"
    ```

=== "RBAC Scanning"
    ```yaml
    --8<-- "github-workflow-examples/dynamic-rbac-scanning.yml"
    ```

=== "Existing Cluster"
    ```yaml
    --8<-- "github-workflow-examples/existing-cluster-scanning.yml"
    ```

## Conclusion

The code display capabilities demonstrated on this page help make our documentation more:

- **Clear**: Code is syntax highlighted and properly formatted
- **Interactive**: Copy buttons and line highlighting improve usability
- **Annotated**: Comments help explain complex configurations
- **Consistent**: Using the same example files throughout documentation
