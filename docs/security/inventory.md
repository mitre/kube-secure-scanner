# Security Documentation Directory Contents

!!! info "Directory Purpose"
    This directory contains comprehensive documentation about security aspects of the Secure CINC Auditor Kubernetes Container Scanning platform.

## Overview Files

| File | Description |
|------|-------------|
| [index.md](index.md) | Overview of security documentation |
| [inventory.md](inventory.md) | Directory listing of all security documentation |

## Security Subdirectories

| Directory | Description |
|-----------|-------------|
| [principles/](principles) | Core security principles documentation |
| [risk/](risk) | Security risk analysis documentation |
| [compliance/](compliance) | Compliance frameworks alignment documentation |
| [threat-model/](threat-model) | Threat modeling and mitigation documentation |
| [recommendations/](recommendations) | Security best practices and recommendations |

## Security Principles Section

The [principles/](principles) directory contains:

| File | Description |
|------|-------------|
| [index.md](principles/index.md) | Overview of security principles |
| [least-privilege.md](principles/least-privilege.md) | Details on least privilege implementation |
| [ephemeral-creds.md](principles/ephemeral-creds.md) | Details on ephemeral credentials |
| [resource-isolation.md](principles/resource-isolation.md) | Details on resource isolation |
| [secure-transport.md](principles/secure-transport.md) | Details on secure transport |
| [inventory.md](principles/inventory.md) | Directory listing |

## Risk Analysis Section

The [risk/](risk) directory contains:

| File | Description |
|------|-------------|
| [index.md](risk/index.md) | Overview of risk analysis |
| [model.md](risk/model.md) | Risk model and methodology |
| [kubernetes-api.md](risk/kubernetes-api.md) | Risks for Kubernetes API approach |
| [debug-container.md](risk/debug-container.md) | Risks for Debug Container approach |
| [sidecar-container.md](risk/sidecar-container.md) | Risks for Sidecar Container approach |
| [mitigations.md](risk/mitigations.md) | Risk mitigation strategies |
| [inventory.md](risk/inventory.md) | Directory listing |

## Compliance Section

The [compliance/](compliance) directory contains:

| File | Description |
|------|-------------|
| [index.md](compliance/index.md) | Overview of compliance documentation |
| [dod-8500-01.md](compliance/dod-8500-01.md) | DoD Instruction 8500.01 alignment |
| [disa-srg.md](compliance/disa-srg.md) | DISA Container Platform SRG alignment |
| [kubernetes-stig.md](compliance/kubernetes-stig.md) | Kubernetes STIG alignment |
| [cis-benchmarks.md](compliance/cis-benchmarks.md) | CIS Kubernetes Benchmarks alignment |
| [approach-comparison.md](compliance/approach-comparison.md) | Compliance comparison of approaches |
| [risk-documentation.md](compliance/risk-documentation.md) | Requirements for risk documentation |
| [inventory.md](compliance/inventory.md) | Directory listing |

## Threat Model Section

The [threat-model/](threat-model) directory contains:

| File | Description |
|------|-------------|
| [index.md](threat-model/index.md) | Overview of threat modeling |
| [attack-vectors.md](threat-model/attack-vectors.md) | Potential attack vectors |
| [threat-mitigations.md](threat-model/threat-mitigations.md) | Threat mitigation strategies |
| [token-exposure.md](threat-model/token-exposure.md) | Token exposure threats and mitigations |
| [lateral-movement.md](threat-model/lateral-movement.md) | Preventing lateral movement |
| [inventory.md](threat-model/inventory.md) | Directory listing |

## Recommendations Section

The [recommendations/](recommendations) directory contains:

| File | Description |
|------|-------------|
| [index.md](recommendations/index.md) | Overview of security recommendations |
| [enterprise.md](../developer-guide/deployment/scenarios/enterprise.md) | Enterprise security recommendations |
| [ci-cd.md](../architecture/deployment/ci-cd-deployment.md) | CI/CD security recommendations |
| [monitoring.md](../developer-guide/deployment/advanced-topics/monitoring.md) | Security monitoring recommendations |
| [network.md](recommendations/network.md) | Network security recommendations |
| [inventory.md](recommendations/inventory.md) | Directory listing |

## Related Topics

- [RBAC Configuration](../rbac/index.md) - Role-Based Access Control configuration
- [Service Accounts](../service-accounts/index.md) - Service account management
- [Token Management](../tokens/index.md) - Secure token handling
- [Kubernetes API Approach](../approaches/kubernetes-api/index.md) - Standard approach security details
- [Debug Container Approach](../approaches/debug-container/index.md) - Debug container approach security details
- [Sidecar Container Approach](../approaches/sidecar-container/index.md) - Sidecar approach security details
