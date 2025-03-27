# Integration Configuration Inventory

This page provides an inventory of all configuration documentation for container scanning integrations.

## Configuration Files

| File | Description | Key Topics |
|------|-------------|------------|
| [index.md](index.md) | Overview of configuration options | Common patterns, key considerations |
| [environment-variables.md](environment-variables.md) | Environment variable documentation | Common variables, approach-specific variables |
| [secrets-management.md](secrets-management.md) | Managing secrets in CI/CD pipelines | Secret types, platform-specific practices |
| [thresholds-integration.md](thresholds-integration.md) | Configuring compliance thresholds | Threshold types, progressive implementation |
| [reporting.md](reporting.md) | Configuring scan result reporting | Report types, visualization, distribution |

## Configuration by Integration Type

### GitHub Actions Configuration

The following files contain GitHub Actions-specific configuration information:

- [Environment Variables](environment-variables.md#example-github-actions-configuration)
- [Secrets Management](secrets-management.md#github-actions)
- [Thresholds Integration](thresholds-integration.md#github-actions-integration)
- [Reporting Configuration](reporting.md#github-actions-integration)

### GitLab CI/CD Configuration

The following files contain GitLab CI/CD-specific configuration information:

- [Environment Variables](environment-variables.md#example-gitlab-cicd-configuration)
- [Secrets Management](secrets-management.md#gitlab-cicd)
- [Thresholds Integration](thresholds-integration.md#gitlab-cicd-integration)
- [Reporting Configuration](reporting.md#gitlab-cicd-integration)

## Configuration by Scanning Approach

### Standard Container Scanning

Variables and configuration for scanning standard containers using the Kubernetes API approach:

- [Kubernetes API Approach Variables](environment-variables.md#kubernetes-api-approach-variables)
- [Standard Container Workflow Configuration](../workflows/standard-container.md#configuration)

### Distroless Container Scanning

Variables and configuration for scanning distroless containers using the debug container approach:

- [Debug Container Approach Variables](environment-variables.md#debug-container-approach-variables)
- [Distroless Container Workflow Configuration](../workflows/distroless-container.md#configuration)

### Sidecar Container Scanning

Variables and configuration for scanning containers using the sidecar approach:

- [Sidecar Container Approach Variables](environment-variables.md#sidecar-container-approach-variables)
- [Sidecar Container Workflow Configuration](../workflows/sidecar-container.md#configuration)

## Security Configuration

Security-related configuration for scanning:

- [Label-Based Scanning Variables](environment-variables.md#label-based-scanning-variables)
- [Secret Management Variables](environment-variables.md#secret-management-variables)
- [Temporary Credentials Workflow](secrets-management.md#temporary-credentials-workflow)
- [Creating Least-Privilege RBAC Roles](secrets-management.md#kubernetes-secret-management)

## Related Resources

- [GitHub Actions Integration Guide](../platforms/github-actions.md)
- [GitLab CI/CD Integration Guide](../platforms/gitlab-ci.md)
- [GitLab Services Integration Guide](../platforms/gitlab-services.md)
- [Standard Container Workflow](../workflows/standard-container.md)
- [Distroless Container Workflow](../workflows/distroless-container.md)
- [Sidecar Container Workflow](../workflows/sidecar-container.md)
- [Security Workflows](../workflows/security-workflows.md)
- [SAF CLI Documentation](https://saf-cli.mitre.org/)
