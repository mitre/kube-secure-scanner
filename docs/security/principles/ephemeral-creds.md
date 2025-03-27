# Ephemeral Credentials

Ephemeral credentials are short-lived authentication tokens that provide temporary access to Kubernetes resources. This approach significantly reduces the security risks associated with long-lived credentials.

## Implementation Details

The Secure CINC Auditor Kubernetes Container Scanning solution implements ephemeral credentials through:

- Short-lived tokens are generated for each scan
- Token expiration can be configured (default: 1 hour)
- No long-lived tokens stored in CI/CD variables or config files

## Token Generation Process

Tokens are generated using the Kubernetes TokenRequest API, which creates temporary credentials with a specified expiration time:

```bash
kubectl create token scanner-service-account \
  --bound-object-kind=Pod \
  --bound-object-name=scanner-pod \
  --audience=kubernetes \
  --validity-duration=1h
```

This token is automatically invalidated after the specified duration (1 hour in this example).

## Security Benefits

Ephemeral credentials provide several security advantages:

1. **Limited Exposure Window**: Even if credentials are leaked, they have a short validity period
2. **No Persistent Storage**: Tokens are generated on-demand and not persistently stored
3. **Audience Binding**: Tokens can be bound to specific target systems
4. **Automatic Invalidation**: No manual revocation required when access is no longer needed
5. **CI/CD Security**: Reduces risk of credential leakage in CI/CD pipelines

## Implementation Considerations

When implementing ephemeral credentials:

- Set an appropriate token validity period based on scan duration requirements
- Implement proper error handling for token expiration during long-running scans
- Consider regenerating tokens for batch operations rather than using a single token
- Integrate token generation within automated workflows

## Recommended Token Lifetimes

| Scanning Scenario | Recommended Token Lifetime |
|-------------------|----------------------------|
| **Interactive Debugging** | 15-30 minutes |
| **CI/CD Pipeline Scan** | Duration of pipeline + 5 minutes |
| **Scheduled Batch Scans** | Maximum duration of batch + 15 minutes |
| **Production Monitoring** | 1 hour maximum |

## Integration with CI/CD Systems

For CI/CD integrations:

1. Generate token at the beginning of the pipeline
2. Use token for all scanning operations
3. Token automatically expires after pipeline completion
4. No token storage between pipeline runs

## Related Documentation

- [Risk Analysis](../risk/index.md) - Security risks mitigated by ephemeral credentials
- [Compliance Documentation](../compliance/index.md) - Compliance requirements for temporary credentials
- [Service Accounts](../../service-accounts/index.md) - Service account configuration
- [Tokens](../../tokens/index.md) - Token generation and management
