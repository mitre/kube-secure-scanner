# Security Enhancements

This guide provides detailed security enhancements for the Secure CINC Auditor Kubernetes Container Scanning solution.

## Overview

Security is a critical aspect of deploying container scanning solutions, especially in production environments. This guide covers advanced security configurations to protect your scanning infrastructure and the data it processes.

## RBAC Restrictions

Implement fine-grained role-based access control (RBAC) to limit scanner permissions:

```yaml
# restricted-rbac-values.yaml
rbac:
  create: true
  restrictive: true
  timebound: true
  tokenExpiration: 300  # 5 minutes
  podSelector:
    matchLabels:
      scan: enabled
  namespaceSelector:
    matchLabels:
      scan: enabled
```

### Principle of Least Privilege

Follow these guidelines for RBAC restrictions:

1. Limit scanner to specific namespaces
2. Use time-bound tokens for ephemeral access
3. Implement label-based targeting to restrict scope
4. Use restrictive verbs (get, list) instead of broad permissions

### Advanced RBAC Configuration

For more complex security scenarios:

```yaml
# advanced-rbac-values.yaml
rbac:
  clusterRoles:
    enabled: false  # Use namespaced roles when possible
  
  roles:
    - name: scanner-reader
      rules:
        - apiGroups: [""]
          resources: ["pods"]
          verbs: ["get", "list"]
          resourceNames: []  # Optional list of specific resources
    
    - name: scanner-reporter
      rules:
        - apiGroups: [""]
          resources: ["configmaps"]
          verbs: ["get", "create", "update"]
  
  serviceAccounts:
    - name: scanner-sa
      namespace: scanner-ns
      annotations:
        eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/scanner-role"
```

## Scanner Isolation

Isolate scanner components to prevent privilege escalation and limit the impact of potential breaches:

```yaml
# isolation-values.yaml
podSecurityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  runAsNonRoot: true

securityContext:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: ["ALL"]

networkPolicy:
  enabled: true
  restrictEgress: true
  allowedEgressDomains:
    - kubernetes.default.svc.cluster.local
```

### Pod Security Standards

Implement Kubernetes Pod Security Standards:

```yaml
# pod-security-values.yaml
podSecurity:
  standard: restricted
  enforce: true
  audit: true
  warn: true
  
  seccompProfile:
    type: RuntimeDefault
```

### Network Policies

Restrict scanner network communications:

```yaml
# network-policy-values.yaml
networkPolicies:
  - name: scanner-network-policy
    spec:
      podSelector:
        matchLabels:
          app: scanner
      policyTypes:
        - Ingress
        - Egress
      ingress:
        - from:
            - namespaceSelector:
                matchLabels:
                  name: security-tools
      egress:
        - to:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: default
            - podSelector:
                matchLabels:
                  k8s-app: kube-dns
          ports:
            - protocol: UDP
              port: 53
```

## Sensitive Data Handling

Implement secure handling of scan results and sensitive information:

```yaml
# data-security-values.yaml
results:
  encryption:
    enabled: true
    provider: kubernetes-secrets
  redaction:
    enabled: true
    patterns:
      - PASSWORD
      - SECRET
      - TOKEN
  rbac:
    viewResults:
      create: true
      subjects:
        - kind: Group
          name: security-team
```

### Data Classification

Classify and protect data according to sensitivity:

```yaml
# data-classification-values.yaml
dataClassification:
  enabled: true
  levels:
    - name: public
      protection: none
    - name: internal
      protection: encryption
    - name: confidential
      protection: encryption-and-access-control
  
  classifications:
    scanResults: confidential
    scanConfigurations: internal
    scanLogs: internal
```

### Secret Management

Integrate with external secret managers:

```yaml
# secret-management-values.yaml
secretManagement:
  provider: vault  # or aws-secrets-manager, azure-key-vault
  
  vault:
    address: https://vault.example.com
    role: scanner
    secretPath: secret/scanner
    
  integratedSecrets:
    - name: scanner-credentials
      keys:
        - apiKey
        - token
```

## Authentication & Authorization

Implement strong authentication and authorization:

```yaml
# auth-values.yaml
authentication:
  serviceAccounts:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::123456789012:role/scanner-role"
  
  oidc:
    enabled: true
    issuerUrl: https://auth.example.com
    clientId: scanner-client
    requestedScopes:
      - openid
      - profile
```

## Mutual TLS Configuration

Implement mutual TLS for secure communication:

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

### TLS Rotation and Management

Implement certificate rotation and management:

```yaml
# certificate-management-values.yaml
certificateManagement:
  provider: cert-manager
  autoRenew: true
  notifyBeforeExpiry: 30  # days
  certDuration: 365  # days
```

## Audit Logging

Enable comprehensive audit logging for security monitoring:

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

### Log Forwarding and Integration

Forward logs to security information and event management (SIEM) systems:

```yaml
# log-integration-values.yaml
logging:
  forwarding:
    enabled: true
    destination: splunk  # or elasticsearch, datadog, etc.
    splunk:
      hec:
        url: https://splunk-hec.example.com
        token: ${SPLUNK_TOKEN}
      index: kubernetes-security
  
  format: json
  includeMetadata: true
```

## Container Image Security

Enhance container image security:

```yaml
# image-security-values.yaml
imageSecurity:
  policy:
    allowedRegistries:
      - docker.io/cinc
      - registry.example.com
    scanBeforePull: true
    enforceSignature: true
  
  scanner:
    image:
      pullPolicy: Always
      pullSecrets:
        - name: registry-credentials
```

## Related Topics

- [Specialized Environments](specialized-environments.md)
- [Monitoring and Maintenance](monitoring.md)
- [RBAC Configuration](../../../rbac/index.md)
