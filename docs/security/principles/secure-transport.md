# Secure Transport

Secure transport is a critical security principle in the Secure CINC Auditor Kubernetes Container Scanning solution. This principle ensures that all communications between components are encrypted and protected against eavesdropping and tampering.

## Implementation Details

The secure transport principle is implemented through:

- All API communication uses TLS
- Kubeconfig files include the cluster's certificate authority data
- No insecure TLS options are enabled

## TLS Communication

All communication with the Kubernetes API server is secured through TLS:

1. **Certificate Validation**: The Kubernetes API server's certificate is validated against trusted certificate authorities
2. **Encryption in Transit**: All data exchanged with the API server is encrypted
3. **No Insecure Fallback**: The solution does not permit insecure connections if TLS fails
4. **Modern TLS Versions**: Only secure TLS versions (TLS 1.2+) are used

## Kubeconfig Security

Kubeconfig files are configured securely:

```yaml
apiVersion: v1
kind: Config
clusters:
- name: kubernetes
  cluster:
    server: https://kubernetes.default.svc
    certificate-authority-data: <BASE64_ENCODED_CA_CERT>
users:
- name: scanner
  user:
    token: <EPHEMERAL_TOKEN>
contexts:
- name: scanner-context
  context:
    cluster: kubernetes
    user: scanner
current-context: scanner-context
```

Key security features:

- Certificate authority data is embedded (no insecure `insecure-skip-tls-verify: true`)
- TLS verification is always enabled
- Ephemeral tokens are used for authentication

## Network Security Considerations

Beyond TLS, additional network security measures include:

1. **Network Policies**: Optional Kubernetes NetworkPolicy resources to restrict pod communication
2. **Internal Service Communication**: Using internal Kubernetes service names to avoid external network traversal
3. **API Server Access Control**: Leveraging Kubernetes API server authentication and authorization

## Security Benefits

Secure transport provides several security benefits:

1. **Confidentiality**: Prevents eavesdropping on sensitive scanning data
2. **Integrity**: Ensures data cannot be tampered with during transmission
3. **Authentication**: Verifies the identity of the Kubernetes API server
4. **Man-in-the-Middle Protection**: Prevents interception attacks
5. **Regulatory Compliance**: Supports requirements for encrypted communications

## Implementation Across Scanning Approaches

All scanning approaches use the same secure transport mechanisms to communicate with the Kubernetes API server:

| Scanning Approach | Secure Transport Implementation |
|-------------------|----------------------------------|
| **Kubernetes API** | TLS-secured API server communication |
| **Debug Container** | TLS-secured API server communication |
| **Sidecar Container** | TLS-secured API server communication |

## Best Practices

1. **Certificate Rotation**: Ensure cluster certificates are rotated according to security policies
2. **TLS Version**: Configure minimum TLS version to 1.2 or higher
3. **Cipher Suites**: Use only strong cipher suites
4. **Kubeconfig Security**: Protect kubeconfig files with appropriate file permissions
5. **Network Segmentation**: Consider network segmentation for scanner components

## Related Documentation

- [Risk Analysis](../risk/index.md) - Security risks mitigated by secure transport
- [Compliance Documentation](../compliance/index.md) - Compliance requirements for transport security
- [Kubernetes Setup](../../kubernetes-setup/index.md) - Kubeconfig configuration
- [Tokens](../../tokens/index.md) - Token generation and security
