# Lateral Movement Analysis

This document analyzes lateral movement risks in the Secure CINC Auditor Kubernetes Container Scanning solution, focusing on how an attacker might move from one compromised component to others.

## Lateral Movement Risks

Lateral movement involves an attacker expanding their access from an initial foothold to other components within the Kubernetes cluster. In the context of container scanning, this could involve:

1. Moving from scanner access to wider pod/namespace access
2. Accessing secrets or sensitive configuration data
3. Gaining access to other containers in the cluster
4. Escalating privileges to modify resources or access host resources

## RBAC-Based Prevention

The RBAC configuration in our solution prevents lateral movement through careful permission scoping:

### No Access to Secrets

```yaml
# What's NOT in our RBAC configuration:
# We explicitly do not grant access to secrets
apiGroups: [""]
resources: ["secrets"]
verbs: ["get", "list", "watch"]
```

Without secrets access, attackers cannot retrieve:

- API credentials
- Encryption keys
- Database passwords
- Other sensitive information

### No Access to ConfigMaps

```yaml
# What's NOT in our RBAC configuration:
# We explicitly do not grant access to configmaps
apiGroups: [""]
resources: ["configmaps"]
verbs: ["get", "list", "watch"]
```

Without configmap access, attackers cannot retrieve:

- Configuration data
- Connection strings
- Environment settings
- Other non-sensitive but useful information

### No Ability to Create New Resources

```yaml
# What's NOT in our RBAC configuration:
# We explicitly do not grant resource creation permissions
apiGroups: [""]
resources: ["pods"]
verbs: ["create", "update", "patch", "delete"]
```

Without resource creation permissions, attackers cannot:

- Deploy new malicious pods
- Modify existing deployments
- Create persistent access mechanisms
- Deploy privileged containers

### No Ability to Modify Service Accounts

```yaml
# What's NOT in our RBAC configuration:
# We explicitly do not grant service account management
apiGroups: [""]
resources: ["serviceaccounts"]
verbs: ["get", "list", "create", "update", "patch", "delete"]
```

Without service account management permissions, attackers cannot:

- Create new service accounts
- Modify existing service account permissions
- Access service account tokens
- Create persistence through service account changes

## Approach-Specific Lateral Movement Risks

Each scanning approach has different lateral movement characteristics:

### Kubernetes API Approach

**Risk Level: Low**

Key characteristics:

- Standard API access only
- No additional containers deployed
- Container boundaries fully preserved
- Least privilege implementation

Potential lateral movement paths:

- Limited to accessing other pods with the same RBAC permissions
- No process or network-based lateral movement paths

### Debug Container Approach

**Risk Level: Medium**

Key characteristics:

- Ephemeral debug container with process namespace access
- Temporary existence
- Access to target container filesystem

Potential lateral movement paths:

- Access to target container files and processes
- Potential for credential harvesting from process memory
- Limited by ephemeral nature of debug container

### Sidecar Container Approach

**Risk Level: Medium-High**

Key characteristics:

- Shared process namespace with target container
- Persistent existence throughout pod lifecycle
- Direct access to target container processes and filesystem

Potential lateral movement paths:

- Complete access to target container memory, files, and processes
- Potential for credential harvesting from process memory
- Network visibility from container perspective
- Persistent access to container resources

## Namespace Isolation

Namespace isolation provides an additional barrier to lateral movement:

1. **Resource Scope**: RBAC roles are limited to specific namespaces
2. **Network Boundaries**: Network policies can limit cross-namespace communication
3. **Resource Isolation**: Resources from different namespaces are isolated
4. **Service Segregation**: Services are namespace-scoped by default

## Network-Based Lateral Movement Prevention

Network policies can further restrict lateral movement:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: scanner-network-policy
  namespace: scanning-namespace
spec:
  podSelector:
    matchLabels:
      role: scanner
  policyTypes:
  - Ingress
  - Egress
  ingress: []  # No inbound traffic allowed
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - port: 443
      protocol: TCP
```

This network policy:

- Restricts scanner pods from connecting to other pods
- Only allows API server communication
- Prevents network-based lateral movement
- Blocks external network access

## Process-Based Lateral Movement Prevention

For approaches that involve process interaction (Debug Container and Sidecar Container):

1. **Non-root Execution**: Scanner containers run as non-root users
2. **Minimal Capabilities**: Scanner containers have minimal Linux capabilities
3. **Security Contexts**: Strict security contexts prevent privilege escalation
4. **Read-only Filesystem**: Prevents modification of scanner container files

## Mitigation Recommendations

To further reduce lateral movement risks:

1. **Dedicated Scanning Namespaces**: Use dedicated namespaces for scanning infrastructure
2. **Network Segmentation**: Implement strict network policies
3. **Just-in-Time Access**: Generate short-lived tokens only when needed
4. **Monitoring and Alerting**: Implement monitoring for unusual access patterns
5. **Regular Audit**: Review RBAC permissions and scan operations logs

For the Sidecar Container approach specifically:

1. **Enhanced Container Hardening**: Additional security measures for sidecar containers
2. **Process Monitoring**: Monitor for unusual process access patterns
3. **Resource Isolation**: Strict resource limits to contain potential compromise

## Related Documentation

- [Attack Vectors](attack-vectors.md) - Analysis of general attack vectors
- [Token Exposure](token-exposure.md) - Analysis of token exposure risks
- [Threat Mitigations](threat-mitigations.md) - Comprehensive mitigation strategies
- [Risk Analysis](../risk/index.md) - Detailed risk assessment
