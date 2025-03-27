# Deployment Scenarios Overview

This guide provides an overview of different deployment scenarios for the Secure CINC Auditor Kubernetes Container Scanning solution.

## Introduction

Different environments and organizational requirements call for different deployment approaches. These scenario guides provide detailed, real-world examples to help you implement the scanner in various environments.

## Available Scenarios

We provide detailed guidance for several common deployment scenarios:

- [Enterprise Production Environment](enterprise.md): Secure, scalable deployment for large organizations with multiple Kubernetes clusters
- [Development Environment](development.md): Quick setup for development teams working on applications
- [CI/CD Pipeline Environment](cicd.md): Integration with automated CI/CD pipelines for continuous security validation
- [Multi-Tenant Kubernetes Environment](multi-tenant.md): Deployment in shared clusters with multiple teams
- [Air-Gapped Environment](air-gapped.md): Deployment in secure environments without internet access

## Choosing the Right Scenario

When selecting a deployment scenario, consider the following factors:

1. **Environment Type**: Production, development, testing, or specialized environment
2. **Scale**: Single cluster vs. multiple clusters, number of containers to scan
3. **Security Requirements**: Security posture, compliance needs, data sensitivity
4. **Team Structure**: Single team or multiple teams sharing resources
5. **Integration Needs**: CI/CD pipelines, security monitoring, compliance reporting

## Customizing Scenarios

Each scenario can be customized to meet your specific requirements:

- Adjust resource allocations based on your environment scale
- Modify security controls to match your security policies
- Customize scanning profiles for your application types
- Adapt deployment scripts or Helm values for your infrastructure

## Related Topics

- [Deployment Overview](../index.md)
- [Script Deployment](../script-deployment.md)
- [Helm Deployment](../helm-deployment.md)
- [CI/CD Integration](../cicd-deployment.md)
- [Advanced Deployment Topics](../advanced-topics/index.md)
