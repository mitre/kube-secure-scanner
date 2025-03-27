# CI/CD Integration

This section provides comprehensive guidance on integrating the Kube CINC Secure Scanner with various CI/CD platforms.

## Integration Overview

The Kube CINC Secure Scanner can be integrated with popular CI/CD platforms to automate container security scanning as part of your deployment pipeline. This allows you to catch security issues early in the development lifecycle and ensure that only compliant containers are deployed to your environments.

## Integration Categories

Our integration documentation is organized into the following categories:

- [CI/CD Platforms](platforms/index.md) - Integration guides for specific CI/CD platforms
- [Integration Workflows](workflows/index.md) - Workflows for integrating different scanning approaches
- [Integration Examples](examples/index.md) - Practical examples of CI/CD integrations
- [Integration Configuration](configuration/index.md) - Configuration guidance for CI/CD integrations

## Getting Started

To get started with CI/CD integration, follow these steps:

1. Review the [Approach Mapping](approach-mapping.md) to select the appropriate scanning approach
2. Choose your [CI/CD Platform](platforms/index.md) and follow the platform-specific guide
3. Implement the appropriate [Integration Workflow](workflows/index.md) for your selected approach
4. Configure your integration using the [Configuration Guide](configuration/index.md)
5. Reference the [Integration Examples](examples/index.md) for practical implementation guidance

## Best Practices

When integrating with CI/CD platforms, follow these best practices:

1. **Use dedicated service accounts** with limited permissions
2. **Implement appropriate security controls** for access to scan results
3. **Configure appropriate thresholds** for failing builds based on scan results
4. **Use caching** to improve performance where possible
5. **Include remediation guidance** in scan result notifications

## Implementation Examples

For practical implementation examples, see:

- [GitHub Workflow Examples](../github-workflow-examples/index.md)
- [GitLab Pipeline Examples](../gitlab-pipeline-examples/index.md)

## Related Resources

- [Scanning Approaches](../approaches/index.md)
- [Advanced Configuration](../configuration/advanced/index.md)
- [Scanning Thresholds](../configuration/thresholds/index.md)
