# GitLab CI Integration with Services

This document explains how to use GitLab CI/CD services with the Kubernetes CINC Secure Scanner for enhanced container scanning workflows.

## Overview

GitLab CI/CD services allow you to run Docker containers alongside your CI/CD jobs. These service containers can provide additional functionality and dependencies without cluttering your main job container. For our scanning workflows, services can provide a consistent, pre-configured environment for running CINC Auditor scans.

## Benefits of Using Services

1. **Pre-installed Dependencies**: Service containers can have CINC Auditor, the train-k8s-container plugin, and the SAF CLI pre-installed.
2. **Isolation**: Scanning tools are isolated from your application code and build tools.
3. **Consistency**: Every scan job uses the exact same scanning environment.
4. **Specialized Containers**: Different service containers can be used for different types of scans (standard vs. distroless).
5. **Reduced Setup Time**: Eliminates the need to install dependencies in each job.

## Implementation

### Creating Scanner Service Images

Create Docker images for your scanning services:

#### Standard Scanner Image

```dockerfile
FROM ruby:3.0-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install CINC Auditor
RUN curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor

# Install train-k8s-container plugin
RUN cinc-auditor plugin install train-k8s-container

# Install SAF CLI
RUN npm install -g @mitre/saf

# Set up a working directory
WORKDIR /opt/scanner

ENTRYPOINT ["sleep", "infinity"]
```

#### Distroless Scanner Image

```dockerfile
FROM ruby:3.0-slim

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    nodejs \
    npm \
    kubectl \
    && rm -rf /var/lib/apt/lists/*

# Install CINC Auditor
RUN curl -L https://omnitruck.cinc.sh/install.sh | bash -s -- -P cinc-auditor

# Install train-k8s-container plugin
RUN cinc-auditor plugin install train-k8s-container

# Install SAF CLI
RUN npm install -g @mitre/saf

# Copy specialized scripts
COPY scripts/scan-distroless.sh /opt/scripts/
RUN chmod +x /opt/scripts/scan-distroless.sh

# Set up a working directory
WORKDIR /opt/scanner

ENTRYPOINT ["sleep", "infinity"]
```

### Using Scanner Services in GitLab CI

See the `gitlab-pipeline-examples/gitlab-ci-with-services.yml` file in the repository for a complete implementation. Here's how to define services in your `.gitlab-ci.yml` file:

```yaml
# Define a global service for all jobs
services:
  - name: registry.example.com/cinc-auditor-scanner:latest
    alias: cinc-scanner
    entrypoint: ["sleep", "infinity"]

# Or define a service for a specific job
run_distroless_scan:
  services:
    - name: registry.example.com/distroless-scanner:latest
      alias: distroless-scanner
      entrypoint: ["sleep", "infinity"]
  script:
    # Job commands that interact with the service
```

## Communication Between Jobs and Services

To interact with service containers:

1. **Docker Commands**: Use `docker cp` and `docker exec` to copy files and run commands in service containers.
2. **File Exchange**: Use temporary files to exchange data between the job and service containers.
3. **Container Networking**: Service containers are accessible via their alias hostnames.

## Considerations

### Advantages

- Clean separation of concerns
- Pre-built, consistent scanning environment
- Reduced pipeline setup time
- Support for both standard and distroless scanning approaches

### Potential Challenges

- **Complexity**: Adds another layer to the CI/CD configuration
- **Docker-in-Docker**: Requires Docker socket access or Docker-in-Docker service
- **Performance**: Additional overhead from running multiple containers
- **Maintenance**: Scanner service images need to be maintained and updated

## Complete Example

See the `gitlab-pipeline-examples/gitlab-ci-with-services.yml` file in the repository for a complete example of integrating scanner services into your GitLab CI/CD pipeline.

## Workflow Diagram

For a visual representation of how GitLab CI services integrate with the scanning workflow, see the [Workflow Diagrams](../../architecture/diagrams/workflow-diagrams.md) document.

## Related Integration Resources

- [Standard Container Workflow Integration](../workflows/standard-container.md)
- [Distroless Container Workflow Integration](../workflows/distroless-container.md)
- [Sidecar Container Workflow Integration](../workflows/sidecar-container.md)
- [GitLab CI Integration](gitlab-ci.md)
- [GitLab Services Analysis](../gitlab-services-analysis.md)
- [Integration Configuration](../configuration/index.md)
