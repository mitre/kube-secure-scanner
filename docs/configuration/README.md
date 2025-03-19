# Kubeconfig Generation and Management

This guide covers creating and managing secure kubeconfig files for InSpec container scanning.

## Basic Kubeconfig Structure

A kubeconfig file for InSpec scanning contains:

1. **Cluster configuration**: Server address and certificate authority
2. **User authentication**: Service account token
3. **Context**: Binding a cluster and user with a namespace

## Creating a Secure Kubeconfig

### Manual Generation

```bash
TOKEN=$(kubectl create token inspec-scanner -n inspec-test)
SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')

cat << EOF > secure-kubeconfig.yaml
apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    server: ${SERVER}
    certificate-authority-data: ${CA_DATA}
  name: scanner-cluster
contexts:
- context:
    cluster: scanner-cluster
    namespace: inspec-test
    user: scanner-user
  name: scanner-context
current-context: scanner-context
users:
- name: scanner-user
  user:
    token: ${TOKEN}
EOF
```

### Using kubectl Tools

```bash
# Create a new kubeconfig file
KUBECONFIG=new-config.yaml kubectl config set-cluster scanner-cluster \
  --server=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}') \
  --certificate-authority-data=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}') \
  --embed-certs=true

# Set the user with token
KUBECONFIG=new-config.yaml kubectl config set-credentials scanner-user \
  --token=$(kubectl create token inspec-scanner -n inspec-test)

# Set the context
KUBECONFIG=new-config.yaml kubectl config set-context scanner-context \
  --cluster=scanner-cluster \
  --namespace=inspec-test \
  --user=scanner-user

# Use the context
KUBECONFIG=new-config.yaml kubectl config use-context scanner-context
```

## Dynamic Configuration in CI/CD

For CI/CD pipelines, you can generate configurations dynamically:

```bash
#!/bin/bash
# generate-kubeconfig.sh
NAMESPACE=$1
SA_NAME=$2
OUTPUT_FILE=${3:-"./kubeconfig.yaml"}

# Get cluster information
SERVER=$(kubectl config view --minify --output=jsonpath='{.clusters[0].cluster.server}')
CA_DATA=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}')

# Create token
TOKEN=$(kubectl create token ${SA_NAME} -n ${NAMESPACE})

# Generate kubeconfig
cat > ${OUTPUT_FILE} << EOF
apiVersion: v1
kind: Config
preferences: {}
clusters:
- cluster:
    server: ${SERVER}
    certificate-authority-data: ${CA_DATA}
  name: scanner-cluster
contexts:
- context:
    cluster: scanner-cluster
    namespace: ${NAMESPACE}
    user: ${SA_NAME}
  name: scanner-context
current-context: scanner-context
users:
- name: ${SA_NAME}
  user:
    token: ${TOKEN}
EOF

echo "Generated kubeconfig at ${OUTPUT_FILE}"
```

Usage:
```bash
./generate-kubeconfig.sh inspec-test inspec-scanner ./my-kubeconfig.yaml
```

## Security Considerations

### File Permissions

Always set restrictive permissions on kubeconfig files:

```bash
chmod 600 kubeconfig.yaml
```

### Token Expiration

Remember that tokens expire, which will invalidate the kubeconfig:

```bash
# Create a kubeconfig with a short-lived token (5 minutes)
TOKEN=$(kubectl create token inspec-scanner -n inspec-test --duration=5m)
# ... create kubeconfig ...

# After token expiration, kubeconfig must be regenerated
```

### Namespace Limitation

The kubeconfig sets a default namespace, but doesn't restrict access to that namespace. Access control still relies on the RBAC configuration.

### Multiple Environments

For different environments (dev, test, prod), create separate kubeconfig files:

```bash
# Development
./generate-kubeconfig.sh dev-namespace inspec-scanner ./kubeconfig-dev.yaml

# Production
./generate-kubeconfig.sh prod-namespace inspec-scanner ./kubeconfig-prod.yaml
```

## Testing a Kubeconfig

Verify your kubeconfig works correctly:

```bash
# Check basic access
KUBECONFIG=./kubeconfig.yaml kubectl get pods

# Check specific permissions
KUBECONFIG=./kubeconfig.yaml kubectl auth can-i create pods/exec --resource-name=inspec-target
```

## References

- [Kubernetes Configure Access to Multiple Clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
- [Kubernetes Authentication](https://kubernetes.io/docs/reference/access-authn-authz/authentication/)