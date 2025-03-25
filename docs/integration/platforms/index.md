# CI/CD Platform Integrations

This section provides detailed documentation on integrating the Kube CINC Secure Scanner with various CI/CD platforms.

## Overview

The Kube CINC Secure Scanner supports integration with multiple CI/CD platforms to enable automated container security scanning as part of your deployment pipeline.

## Supported Platforms

We provide detailed integration guides for the following CI/CD platforms:

- [GitHub Actions](github-actions.md) - Integration with GitHub's native CI/CD service
- [GitLab CI](gitlab-ci.md) - Integration with GitLab's CI/CD pipelines
- [GitLab Services](gitlab-services.md) - Advanced integration using GitLab's Services feature
- [Jenkins](jenkins.md) - Integration with Jenkins pipelines
- [Azure DevOps](azure-devops.md) - Integration with Azure DevOps pipelines
- [Custom Platforms](custom-platforms.md) - Guidance for integrating with other CI/CD platforms

## Platform Selection Considerations

When selecting a CI/CD platform for integration, consider the following factors:

1. **Existing Infrastructure**: If you already use a particular CI/CD platform, integrating with that platform may be the most straightforward option.
2. **Container Support**: Ensure the platform has good support for container-based workflows.
3. **Kubernetes Integration**: Platforms with native Kubernetes integration simplify the setup process.
4. **Security Features**: Consider the platform's security features, such as secrets management.
5. **Scalability**: Ensure the platform can handle your desired scan frequency and volume.

## Related Resources

- [Integration Workflows](../workflows/index.md)
- [Integration Examples](../examples/index.md)
- [Integration Configuration](../configuration/index.md)
- [Approach Mapping](../approach-mapping.md)