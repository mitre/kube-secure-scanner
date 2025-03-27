# Threshold Configuration

!!! info "Directory Inventory"
    See the [Thresholds Directory Inventory](inventory.md) for a complete listing of files and resources in this directory.

This section provides detailed information on using SAF-CLI thresholds for quality gates in security scanning.

## What are Thresholds?

In the context of security scanning, thresholds define the minimum acceptable compliance level for your containerized applications. They allow you to:

- Set minimum passing scores
- Define acceptable failure counts for different severity levels
- Control how many skipped or error controls are permitted
- Implement quality gates in CI/CD pipelines

## Threshold Guides

- [Basic Threshold Configuration](basic.md) - Simple threshold configurations
- [Advanced Threshold Options](advanced.md) - Complex threshold configurations
- [Example Configurations](examples.md) - Example configurations for different environments
- [CI/CD Integration](cicd.md) - Using thresholds in CI/CD pipelines

## Common Use Cases

| Use Case | Guide | Description |
|----------|-------|-------------|
| Simple Compliance | [Basic](basic.md#compliance-score) | Set a minimum overall compliance score |
| Production Enforcement | [Examples](examples.md#production-environment) | Strict thresholds for production environments |
| Development Flow | [Examples](examples.md#development-environment) | Lenient thresholds for development |
| Pipeline Quality Gates | [CI/CD](cicd.md) | Implementing thresholds in automated pipelines |

## Getting Started

A simple threshold configuration looks like this:

```yaml
# threshold.yml
compliance:
  min: 80
failed:
  critical:
    max: 0
  high:
    max: 2
```

This configuration requires:

- At least 80% overall compliance
- No critical failures
- No more than 2 high severity failures

## Related Topics

- [SAF CLI Integration](../integration/saf-cli.md)
- [CI/CD Integration](../../integration/index.md)
- [Helm Chart Configuration](../../helm-charts/usage/configuration.md)
