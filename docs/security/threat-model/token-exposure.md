# Token Exposure Analysis

This document analyzes the risks associated with service account token exposure in the Secure CINC Auditor Kubernetes Container Scanning solution, and the mitigations implemented to address these risks.

## Token Exposure Risks

Service account tokens are used to authenticate with the Kubernetes API server. If exposed, these tokens could potentially allow unauthorized access to Kubernetes resources.

## Limited Token Capabilities

If a token is exposed, the attacker can only:

1. List pods in the target namespace
2. Execute commands in specifically allowed containers
3. View logs of specifically allowed containers

The token cannot be used to:

1. Create, modify, or delete any resources
2. Access any other containers
3. Access any cluster-wide information
4. Escalate privileges

## Potential Token Exposure Scenarios

### CI/CD Pipeline Exposure

**Scenario**: Tokens stored in CI/CD variables are exposed through pipeline logs or configuration.

**Mitigations**:

- Short-lived tokens generated for each pipeline run
- Masked variables in CI/CD systems
- Tokens automatically expire after pipeline completion
- Just-in-time token generation

### Scanner Process Compromise

**Scenario**: The scanner process itself is compromised, exposing the token it uses.

**Mitigations**:

- Token has minimal permissions through RBAC
- Token expires automatically (default: 15 minutes)
- Network policies restrict token usage
- Comprehensive audit logging of token usage

### Log Exposure

**Scenario**: Tokens are accidentally logged in debug output or error messages.

**Mitigations**:

- Sanitized logging to prevent token logging
- Token format detection in log pipelines
- Automatic token revocation if detected in logs
- Log access restrictions

### Network Interception

**Scenario**: Tokens are intercepted during transmission between components.

**Mitigations**:

- TLS encryption for all API communication
- Internal Kubernetes DNS for service communication
- Network policies restricting communication paths
- Token bound to specific service accounts

## Time-Limited Token Implementation

A key mitigation for token exposure is the use of short-lived tokens:

```bash
# Generate a token valid for 15 minutes
kubectl create token scanner-service-account \
  --duration=900s \
  --bound-object-kind=Pod \
  --bound-object-name=scanner-pod
```

This token:

- Automatically expires after 15 minutes
- Is bound to a specific pod
- Cannot be used from other contexts
- Does not need manual revocation

## RBAC Limitations

The following RBAC configuration limits what can be done with an exposed token:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-role
  namespace: target-namespace
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
  # Optional: further restrict by resource name or label selector
  resourceNames: ["app-pod-1", "app-pod-2"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  resourceNames: ["app-pod-1", "app-pod-2"]
```

This configuration:

- Limits access to specific pods
- Only allows execution, not modification
- Is namespace-scoped
- Provides no access to secrets or other resources

## Token Storage Recommendations

To minimize token exposure risk:

1. **Ephemeral Storage**: Store tokens in memory, not on disk
2. **Environment Variables**: Use environment variables instead of files when possible
3. **Secure Distribution**: Implement secure token distribution mechanisms
4. **No Caching**: Generate new tokens for each operation, don't cache tokens
5. **Masked Variables**: Mask tokens in CI/CD variables and logs

## Token Exposure Detection

Mechanisms to detect potential token exposure:

1. **Audit Logging**: Enable comprehensive API server audit logging
2. **Usage Monitoring**: Monitor token usage patterns for anomalies
3. **Access Analysis**: Analyze access patterns for unusual behavior
4. **Failed Authentication Monitoring**: Alert on multiple failed authentication attempts

## CI/CD System Integration

Best practices for token handling in CI/CD systems:

1. **Masked Variables**: Configure CI/CD systems to mask token values
2. **Pipeline-scoped Tokens**: Generate unique tokens for each pipeline run
3. **Token Rotation**: Rotate service accounts regularly
4. **Just-in-Time Generation**: Generate tokens only when needed, not in advance
5. **Post-pipeline Cleanup**: Ensure tokens are not persisted after pipeline completion

## Approach-Specific Considerations

All scanning approaches use the same token mechanism with similar exposure risks and mitigations. There are no significant differences in token handling between approaches.

## Related Documentation

- [Attack Vectors](attack-vectors.md) - Analysis of general attack vectors
- [Lateral Movement](lateral-movement.md) - Analysis of lateral movement risks
- [Threat Mitigations](threat-mitigations.md) - Comprehensive mitigation strategies
- [Ephemeral Credentials](../principles/ephemeral-creds.md) - Details on ephemeral credential implementation
