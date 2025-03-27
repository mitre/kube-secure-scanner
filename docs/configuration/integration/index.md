# Integration Configuration

!!! info "Directory Inventory"
    See the [Integration Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

This section provides documentation for integrating the CINC Auditor container scanning solution with external tools and systems.

## Integration Overview

Integrating the scanning solution with external tools enhances its capabilities and enables it to fit into larger workflows. Key integrations include:

1. **SAF CLI Integration**: Enhanced reporting and validation with MITRE's Security Automation Framework CLI
2. **GitHub Actions Integration**: Configuration for GitHub CI/CD pipelines
3. **GitLab CI Integration**: Configuration for GitLab CI/CD pipelines

## Integration Guides

- [SAF CLI Integration](saf-cli.md) - Integration with MITRE's Security Automation Framework CLI
- [GitHub Actions Integration](github.md) - Configuration for GitHub workflows
- [GitLab CI Integration](gitlab.md) - Configuration for GitLab pipelines

## Common Use Cases

| Use Case | Guide | Description |
|----------|-------|-------------|
| Enhanced Reporting | [SAF CLI](saf-cli.md) | Generate rich reports from scan results |
| Quality Gates | [SAF CLI](saf-cli.md#threshold-validation) | Validate results against thresholds |
| GitHub CI/CD | [GitHub Actions](github.md) | Integrate scanning into GitHub workflows |
| GitLab CI/CD | [GitLab CI](gitlab.md) | Integrate scanning into GitLab pipelines |

## Getting Started

Most users should begin with [SAF CLI Integration](saf-cli.md) to enhance the reporting and validation capabilities of the scanning solution, followed by integration with their specific CI/CD platform.

## Related Topics

- [Threshold Configuration](../thresholds/index.md)
- [CI/CD Integration](../../integration/index.md)
- [GitHub Workflows](../../github-workflow-examples/index.md)
- [GitLab Pipelines](../../gitlab-pipeline-examples/index.md)
