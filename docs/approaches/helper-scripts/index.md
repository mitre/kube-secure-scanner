# Helper Scripts Approach

This document explains how to use helper scripts for container scanning operations as an alternative to direct commands.

## Introduction

Our container scanning solution provides helper scripts that wrap the complexity of the direct commands, making it easier to perform scanning operations with minimal expertise.

## Key Features

- Easy-to-use wrapper scripts that handle the complexity
- Automatic RBAC creation and cleanup
- Built-in integration with threshold validation
- Streamlined workflows for different container types

## Detailed Documentation

- [Helper Scripts vs. Direct Commands](scripts-vs-commands.md) - Comparison of approaches
- [Available Scripts](available-scripts.md) - Overview of the scripts provided
- [Script Implementation](../kubernetes-api/implementation.md) - How the scripts work under the hood
- [Customizing Scripts](../../helm-charts/usage/customization.md) - How to modify scripts for specific requirements
- [Integration](../index.md) - Integration with CI/CD pipelines and other systems
- [Limitations and Requirements](../kubernetes-api/limitations.md) - What's needed and where the approach has constraints

## When to Use Helper Scripts

- You want a simpler, more streamlined experience
- You're new to Kubernetes or CINC Auditor
- You need to quickly implement scanning in CI/CD
- You want automatic cleanup of temporary resources

## Related Resources

- [Direct Commands](scripts-vs-commands.md) - Using the underlying tools directly
- [Approach Comparison](../comparison.md) - Compare the different scanning approaches
- [Decision Matrix](../decision-matrix.md) - Help decide which approach is best for specific scenarios
