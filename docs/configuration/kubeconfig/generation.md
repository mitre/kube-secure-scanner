# Kubeconfig Generation

This guide covers creating secure kubeconfig files for InSpec container scanning.

## Basic Kubeconfig Structure

A kubeconfig file for InSpec scanning contains three primary sections:

### Cluster Section

The cluster section defines the Kubernetes API server and its certificate authority:

```yaml
clusters:
- cluster:
    server: https://kubernetes.api.server:6443
    certificate-authority-data: BASE64_ENCODED_CA_DATA
  name: scanner-cluster
```

### User Section

The user section defines authentication details for the service account:

```yaml
users:
- name: scanner-user
  user:
    token: SERVICE_ACCOUNT_TOKEN
```

### Context Section

The context section binds a cluster and user with a namespace:

```yaml
contexts:
- context:
    cluster: scanner-cluster
    namespace: inspec-test
    user: scanner-user
  name: scanner-context
current-context: scanner-context
```

## Creating a Secure Kubeconfig

There are several methods to create a kubeconfig file. Choose the one that best fits your environment.

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

## Testing a Kubeconfig

Verify your kubeconfig works correctly:

```bash
# Check basic access
KUBECONFIG=./kubeconfig.yaml kubectl get pods

# Check specific permissions
KUBECONFIG=./kubeconfig.yaml kubectl auth can-i create pods/exec --resource-name=inspec-target
```

## Related Topics

- [Kubeconfig Management](management.md)
- [Security Considerations](security.md)
- [Dynamic Configuration](dynamic.md)
- [RBAC Configuration](../../rbac/index.md)
- [Service Accounts](../../service-accounts/index.md)
