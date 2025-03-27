# Label-Based RBAC Configuration

This document describes how to implement label-based RBAC for more flexible container scanning access.

## Overview

Label-based RBAC allows you to grant access to containers based on their labels rather than their names. This approach is more flexible in dynamic environments where pod names change frequently.

## Implementation

### 1. Pod Labeling

Label your target pods with a designated label:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-pod
  namespace: production
  labels:
    security-scan: "enabled"  # Label for scan selection
```

### 2. Role Configuration

Create a role that doesn't specify resourceNames, but instead relies on the label selector:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: inspec-label-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get"]
```

Note: This role allows access to all pods in the namespace. The limitation will come from how we use this role.

### 3. Script-Based Access Control

Use a script to:

1. Find pods with the target label
2. Generate a temporary kubeconfig
3. Run InSpec only against those pods

```bash
#!/bin/bash
NAMESPACE="production"
LABEL_SELECTOR="security-scan=enabled"

# Find pods with the label
PODS=$(kubectl get pods -n ${NAMESPACE} -l ${LABEL_SELECTOR} -o jsonpath='{.items[*].metadata.name}')

if [ -z "$PODS" ]; then
  echo "No pods found with label ${LABEL_SELECTOR} in namespace ${NAMESPACE}"
  exit 1
fi

# Generate token for service account
TOKEN=$(kubectl create token scanner-sa -n ${NAMESPACE})

# Create kubeconfig
# [... kubeconfig generation code ...]

# For each pod, run the scan
for POD in $PODS; do
  CONTAINER=$(kubectl get pod ${POD} -n ${NAMESPACE} -o jsonpath='{.spec.containers[0].name}')
  echo "Scanning ${NAMESPACE}/${POD}/${CONTAINER}"
  KUBECONFIG=./kubeconfig.yaml inspec exec ./profiles/container \
    -t k8s-container://${NAMESPACE}/${POD}/${CONTAINER}
done
```

## Advanced: LabelSelector with SubjectAccessReview

For more robust access control, you can use a Kubernetes ValidatingWebhook to perform SubjectAccessReview based on pod labels. This approach requires additional components:

1. A ValidatingWebhookConfiguration
2. A webhook server that performs label checks
3. Integration with your authentication system

For a full implementation, see the advanced label RBAC section below.

## Security Considerations

Label-based RBAC is more permissive than name-based RBAC:

1. If a pod is mislabeled, it becomes accessible
2. Users can potentially scan any pod with the target label
3. More complex to audit and trace

Mitigations:

1. Strict control over who can apply labels to pods
2. Regular auditing of pod labels
3. Isolated namespaces for different sensitivity levels
4. Time-bound access tokens

## Example YAML

A complete example configuration is available in the repository under `kubernetes/templates/label-rbac.yaml`.
