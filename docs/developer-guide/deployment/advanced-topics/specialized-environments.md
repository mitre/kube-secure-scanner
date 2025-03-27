# Specialized Environments

This guide covers deployment configurations for specialized environments, including air-gapped and high-security Kubernetes deployments.

## Overview

Some environments have specific requirements that necessitate specialized deployment approaches. This guide covers deployment in air-gapped environments (without internet access) and high-security environments with strict security controls.

## Air-Gapped Environments

Air-gapped environments have no internet connectivity, requiring all resources to be pre-downloaded and available locally.

### Image Bundling

Create a bundle of all required container images for air-gapped deployment:

```bash
#!/bin/bash
# create-image-bundle.sh

REGISTRY="docker.io"
IMAGES=(
  "cinc/auditor:latest"
  "bitnami/kubectl:latest"
  "busybox:latest"
)

mkdir -p ./airgap-bundle/images
for image in "${IMAGES[@]}"; do
  echo "Pulling $image..."
  docker pull $image
  filename=$(echo $image | tr '/:' '_')
  echo "Saving $image to ./airgap-bundle/images/$filename.tar"
  docker save $image > ./airgap-bundle/images/$filename.tar
done

# Bundle profiles and configurations
cp -r ./profiles ./airgap-bundle/
cp -r ./helm-charts ./airgap-bundle/
cp -r ./kubernetes ./airgap-bundle/
cp -r ./scripts ./airgap-bundle/

tar -czf scanner-airgap-bundle.tar.gz ./airgap-bundle
```

### Local Registry Setup

Set up and configure a local container registry:

```yaml
# local-registry-values.yaml
registry:
  internal:
    enabled: true
    persistence:
      enabled: true
      size: 50Gi
  imageOverrides:
    repository: registry.local:5000/cinc/auditor
    tag: latest
```

### Air-Gapped Deployment Configuration

Configure the scanner to use local resources:

```yaml
# airgapped-values.yaml
global:
  imageRegistry: registry.local:5000
  airgapped: true

scanner:
  image:
    repository: registry.local:5000/cinc/auditor
    tag: latest
  
  profiles:
    source: configmap
    configMap:
      name: airgapped-profiles
```

### Air-Gapped Updates

Manage updates in air-gapped environments:

```yaml
# airgapped-updates-values.yaml
updates:
  source: local
  bundle:
    path: /path/to/updates
  
  verification:
    enabled: true
    checksum: true
    signature: true
```

## High-Security Environments

High-security environments require additional security controls beyond standard deployments.

### Enhanced Security Controls

Implement enhanced security controls:

```yaml
# high-security-values.yaml
security:
  enhanced:
    enabled: true
    seccompProfile:
      type: RuntimeDefault
    seLinux:
      enabled: true
    apparmor:
      enabled: true
    psp:
      enabled: true
    admission:
      enabled: true
      validateImages: true
      validateSecrets: true
```

### Mutual TLS Configuration

Implement mutual TLS for secure communications:

```yaml
# mtls-values.yaml
tls:
  enabled: true
  mutual: true
  certificateAuthority:
    create: true
  certificates:
    server:
      create: true
    client:
      create: true
  verifyDepth: 2
```

### Audit Logging

Enable comprehensive audit logging:

```yaml
# audit-values.yaml
audit:
  enabled: true
  level: RequestResponse
  maxAge: 30
  maxBackups: 10
  maxSize: 100
  path: /var/log/scanner-audit.log
  policy:
    create: true
    rules:
      - level: RequestResponse
        resources:
          - group: ""
            resources: ["pods"]
```

### Defense in Depth Measures

Implement multiple layers of security:

```yaml
# defense-in-depth-values.yaml
defensiveControls:
  network:
    denyByDefault: true
    allowedRoutes:
      - source: scanner
        destination: kubernetes-api
      - source: scanner
        destination: containers
  
  application:
    securityFilters:
      - type: input-validation
        enabled: true
      - type: output-encoding
        enabled: true
  
  runtime:
    secureDefaults: true
    failClosed: true
```

### FedRAMP/FISMA Compliance

Configure for FedRAMP or FISMA compliance:

```yaml
# compliance-values.yaml
compliance:
  fedramp:
    enabled: true
    level: high  # moderate or high
  
  controls:
    - id: AC-2
      implementation: automatic
    - id: AC-3
      implementation: automatic
    - id: AU-2
      implementation: automatic
```

## Disconnected Edge Environments

Configure for disconnected edge deployments:

```yaml
# edge-values.yaml
edge:
  enabled: true
  autonomousOperation: true
  
  resilience:
    offlineMode: true
    dataRetention:
      local:
        enabled: true
        size: 10Gi
  
  synchronization:
    mode: manual
    schedule: "0 0 * * *"  # When connected
```

## Sensitive Data Environments

Configure for environments with sensitive data:

```yaml
# sensitive-data-values.yaml
dataProtection:
  encryption:
    enabled: true
    provider: vault
    vault:
      address: https://vault.example.com
      path: secret/scanner
  
  masking:
    enabled: true
    patterns:
      - type: regex
        pattern: "([0-9]{3}-[0-9]{2}-[0-9]{4})"
        replacement: "XXX-XX-XXXX"
```

## Regulated Environments

Configure for regulated industries:

```yaml
# regulated-values.yaml
regulated:
  enabled: true
  industry: healthcare  # healthcare, finance, government
  
  compliance:
    hipaa:
      enabled: true
    pci:
      enabled: false
    gdpr:
      enabled: false
  
  documentation:
    generateReports: true
    auditEvidence: true
```

## Cross-Regional Deployments

Configure for multi-region deployments:

```yaml
# multi-region-values.yaml
regions:
  enabled: true
  primary: us-east
  
  secondaries:
    - name: eu-central
      replication:
        enabled: true
        mode: async
    
    - name: ap-southeast
      replication:
        enabled: true
        mode: async
  
  failover:
    enabled: true
    automatic: false
```

## Related Topics

- [Security Enhancements](security.md)
- [Monitoring and Maintenance](monitoring.md)
- [Deployment Scenarios](../scenarios/index.md)
