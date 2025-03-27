# CI/CD Platform Integrations

This section provides detailed documentation on integrating the Kube CINC Secure Scanner with various CI/CD platforms.

## Overview

The Kube CINC Secure Scanner supports integration with multiple CI/CD platforms to enable automated container security scanning as part of your deployment pipeline.

## Supported Platforms

We provide detailed integration guides for the following CI/CD platforms:

- [GitHub Actions](github-actions.md) - Integration with GitHub's native CI/CD service
- [GitLab CI](gitlab-ci.md) - Integration with GitLab's CI/CD pipelines
- [GitLab Services](gitlab-services.md) - Advanced integration using GitLab's Services feature
- [Jenkins](index.md#jenkins-integration) - Integration with Jenkins pipelines (coming soon)
- [Azure DevOps](index.md#azure-devops-integration) - Integration with Azure DevOps pipelines (coming soon)
- [Custom Platforms](index.md#custom-platform-integration) - Guidance for integrating with other CI/CD platforms (coming soon)

## Platform Selection Considerations

When selecting a CI/CD platform for integration, consider the following factors:

1. **Existing Infrastructure**: If you already use a particular CI/CD platform, integrating with that platform may be the most straightforward option.
2. **Container Support**: Ensure the platform has good support for container-based workflows.
3. **Kubernetes Integration**: Platforms with native Kubernetes integration simplify the setup process.
4. **Security Features**: Consider the platform's security features, such as secrets management.
5. **Scalability**: Ensure the platform can handle your desired scan frequency and volume.

## Future Platform Support

We are actively working on adding detailed integration guides for:

### Jenkins Integration

Jenkins integration will provide:

- Pipeline templates for Jenkins
- Step-by-step integration guides
- Best practices for Jenkins-specific configurations

### Azure DevOps Integration

Azure DevOps integration will include:

- YAML pipeline templates
- Detailed integration steps
- Security considerations for Azure environments

### Custom Platform Integration

For other CI/CD platforms, we will provide:

- Generic integration patterns
- Platform-agnostic configuration
- Adapting workflows to various environments

## Related Resources

- [Integration Workflows](../workflows/index.md)
- [Integration Examples](../examples/index.md)
- [Integration Configuration](../configuration/index.md)
- [Approach Mapping](../approach-mapping.md)
