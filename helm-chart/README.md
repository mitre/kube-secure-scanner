# InSpec Scanner Helm Chart

This Helm chart deploys the infrastructure needed for secure container scanning with InSpec.

## Introduction

The InSpec Scanner chart provides a secure setup for scanning Kubernetes containers using Chef InSpec with the train-k8s-container transport. It implements a least-privilege security model to minimize access to containers.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- kubectl installed

## Installing the Chart

To install the chart with the release name `inspec-scanner`:

```bash
helm install inspec-scanner ./inspec-scanner
```

## Uninstalling the Chart

To uninstall/delete the `inspec-scanner` deployment:

```bash
helm delete inspec-scanner
```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter                     | Description                                     | Default                     |
| ----------------------------- | ----------------------------------------------- | --------------------------- |
| `targetNamespace`             | Namespace for deployment                        | `inspec-test`               |
| `serviceAccount.create`       | Create service account                          | `true`                      |
| `serviceAccount.name`         | Service account name                            | `inspec-scanner`            |
| `serviceAccount.annotations`  | Service account annotations                     | `{}`                        |
| `serviceAccount.labels`       | Service account labels                          | `{app: inspec-scanner, ...}`|
| `rbac.create`                 | Create RBAC resources                           | `true`                      |
| `rbac.roleName`               | Role name                                       | `inspec-container-role`     |
| `rbac.roleBindingName`        | Role binding name                               | `inspec-container-rolebinding` |
| `rbac.useResourceNames`       | Use resource names to restrict access           | `true`                      |
| `rbac.useLabelSelector`       | Use label selectors instead of resource names   | `false`                     |
| `rbac.podSelectorLabels`      | Labels to use for pod selection                 | `{scan-target: "true"}`    |
| `testPod.deploy`              | Deploy a test pod                               | `false`                     |
| `testPod.name`                | Test pod name                                   | `inspec-target`             |
| `testPod.image`               | Test pod image                                  | `busybox:latest`            |
| `testPod.command`             | Test pod command                                | `["sleep", "infinity"]`     |
| `testPod.labels`              | Test pod labels                                 | `{app: inspec-target, ...}` |
| `scripts.generate`            | Generate helper scripts                         | `true`                      |
| `scripts.directory`           | Directory to store scripts                      | `/tmp/inspec-scanner`       |
| `security.tokenDuration`      | Default token duration in minutes               | `60`                        |

## Usage

### Running a Scan

After deploying the chart, you can run a scan using the included scripts:

1. Get the generated kubeconfig:

```bash
./generate-kubeconfig.sh inspec-test inspec-scanner ./kubeconfig.yaml
```

2. Run a scan:

```bash
KUBECONFIG=./kubeconfig.yaml inspec exec ~/inspec-profile -t k8s-container://inspec-test/inspec-target/busybox
```

Or use the convenience script:

```bash
./scan-container.sh inspec-target busybox ~/inspec-profile
```

## Security Considerations

This chart is designed with security in mind:

- Service accounts have minimal permissions
- Roles can be restricted to specific pods by name
- Short-lived tokens are generated for each scan
- No long-lived credentials are stored

For additional security:

1. Use `rbac.useResourceNames: true` to limit access to specific pods
2. Keep `security.tokenDuration` as short as practical
3. Consider setting up dedicated namespaces for different security levels