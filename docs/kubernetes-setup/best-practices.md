# Kubernetes Setup Best Practices

## Overview

This guide provides best practices for setting up Kubernetes environments for secure container scanning. Following these practices ensures that your scanning infrastructure is secure, reliable, and follows the principle of least privilege.

## Security-First Practices

### Namespace Isolation

Always use dedicated namespaces for scanning operations:

```bash
# Create a dedicated namespace
kubectl create namespace scanner-ns

# Run all scanner operations in this namespace
kubectl -n scanner-ns apply -f scanner-resources.yaml
```

Benefits:

- Isolates scanner resources from other workloads
- Allows namespace-specific RBAC controls
- Simplifies resource management and cleanup

### Least Privilege RBAC

Create role-based access controls that provide only the minimum necessary permissions:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scanner-role
  namespace: scanner-ns
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
  # Optionally restrict to specific pod names
  resourceNames: ["target-pod-1", "target-pod-2"]
```

Benefits:

- Minimizes potential damage from compromised credentials
- Follows security principle of least privilege
- Creates clear audit trails for scanner actions

### Ephemeral Credentials

Use short-lived credentials for scanning operations:

```bash
# Generate a short-lived token (default 1 hour)
TOKEN=$(kubectl create token scanner-sa -n scanner-ns)

# Generate a kubeconfig with this token
./kubernetes-scripts/generate-kubeconfig.sh scanner-sa scanner-ns ./kubeconfig.yaml
```

Benefits:

- Reduces risk window if credentials are compromised
- Enforces regular credential rotation
- Simplifies credential management

### Network Policies

Implement network policies to restrict scanner pod communications:

```yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: scanner-network-policy
  namespace: scanner-ns
spec:
  podSelector:
    matchLabels:
      app: scanner
  policyTypes:
  - Ingress
  - Egress
  ingress: []  # No inbound connections allowed
  egress:
  - to:
    - namespaceSelector: {}  # Allow access to Kubernetes API
      podSelector:
        matchLabels:
          k8s-app: kube-apiserver
    ports:
    - protocol: TCP
      port: 443
```

Benefits:

- Prevents lateral movement in case of compromise
- Enforces explicit communication paths
- Reduces attack surface

## Operational Best Practices

### Resource Limits

Always set resource limits for scanner components:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "200m"
```

Benefits:

- Prevents resource exhaustion attacks
- Ensures predictable cluster resource utilization
- Improves scheduler decision making

### Liveness and Readiness Probes

Implement appropriate health checks for longer-running scanner components:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 2
  periodSeconds: 5
```

Benefits:

- Improves reliability and automatic recovery
- Prevents traffic to non-ready instances
- Simplifies troubleshooting

### Logging and Monitoring

Configure comprehensive logging for scanner operations:

```yaml
env:
- name: LOG_LEVEL
  value: "info"
volumeMounts:
- name: scanner-logs
  mountPath: /logs
```

Benefits:

- Creates audit trail for compliance requirements
- Aids in troubleshooting and debugging
- Enables operational insights

## Cluster Configuration Best Practices

### API Server Throttling

Configure appropriate API server throttling to handle scanner requests:

```yaml
# In kube-apiserver configuration
--max-requests-inflight=800
--max-mutating-requests-inflight=400
```

Benefits:

- Prevents API server overload
- Ensures cluster stability during scanning
- Maintains responsiveness for critical operations

### Admission Controllers

Use admission controllers to enforce security policies:

```yaml
# In kube-apiserver configuration
--enable-admission-plugins=PodSecurityPolicy,ResourceQuota,LimitRanger
```

Benefits:

- Enforces consistent security policies
- Prevents privileged scanner pods by default
- Maintains cluster security posture

### Feature Gates

Enable only necessary feature gates for scanning:

```yaml
# For distroless scanning in older clusters
--feature-gates=EphemeralContainers=true
```

Benefits:

- Reduces potential attack surface
- Simplifies security analysis
- Improves stability

## Environment-Specific Recommendations

### Development and Testing

For development and testing environments:

- Use Minikube with [our provided setup script](minikube-setup.md)
- Enable debug logs for scanner components
- Consider using local filesystem for profiles and results

### CI/CD Environments

For CI/CD pipeline integration:

- Use dedicated service accounts per pipeline
- Configure short-lived tokens (e.g., 15 minutes)
- Store sensitive configuration in CI/CD secrets

### Production Environments

For production environments:

- Implement strict network policies
- Use node affinity to run scanners on designated nodes
- Configure comprehensive audit logging
- Consider using Pod Security Standards

## High Availability Considerations

For production use, consider:

1. **Multiple Scanner Deployments**: Deploy scanners across multiple namespaces or clusters
2. **Load Balancing**: Distribute scanning workloads evenly
3. **Failure Domains**: Ensure scanners span multiple availability zones
4. **Graceful Degradation**: Design for partial functionality during outages

## Validation and Compliance

Regularly validate your scanner setup:

```bash
# Validate RBAC configuration
kubectl auth can-i --as=system:serviceaccount:scanner-ns:scanner-sa get pods -n target-ns

# Validate network policies
kubectl exec -it network-test -n scanner-ns -- curl -k https://kubernetes.default.svc
```

## Next Steps

After implementing these best practices:

- [Configure secure kubeconfig files](../configuration/kubeconfig/security.md)
- [Set up label-based RBAC for fine-grained control](../rbac/label-based.md)
- [Implement security-focused scanning thresholds](../configuration/thresholds/basic.md)

## Related Resources

- [Existing Cluster Requirements](existing-cluster-requirements.md)
- [Minikube Setup for Testing](minikube-setup.md)
- [Security Principles](../security/principles/index.md)
- [RBAC Configuration](../rbac/index.md)
