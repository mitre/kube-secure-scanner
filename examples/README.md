# Examples for Secure Container Scanning

This directory contains example resources for demonstrating secure Kubernetes container scanning with CINC Auditor.

## Recommended Scanning Approach

We strongly recommend using the **Kubernetes API Approach** with the train-k8s-container plugin for container scanning, especially in enterprise and production environments. This approach provides:

- Complete isolation from container workloads
- Proper security boundaries
- Compliance with security frameworks
- Scalable implementation for CI/CD pipelines

Our highest strategic priority is enhancing the train-k8s-container plugin to support distroless containers. For detailed information on approach selection, see:
- [Approach Comparison](/docs/overview/approach-comparison.md)
- [Approach Decision Matrix](/docs/overview/approach-decision-matrix.md)
- [Security Compliance](/docs/overview/security-compliance.md)

## CINC Auditor Profiles

The `cinc-profiles` directory contains custom profiles for container scanning:

- **container-baseline**: A basic security profile for containerized applications
  - File permission checks
  - Process checks
  - User and capability checks

## Using the Profiles

You can use these profiles with the workflows or manually:

### With GitHub Actions

```yaml
- name: Run CINC Auditor scan
  run: |
    KUBECONFIG=scan-kubeconfig.yaml cinc-auditor exec ./examples/cinc-profiles/container-baseline \
      -t k8s-container://namespace/pod-name/container-name
```

For complete GitHub Actions workflow examples, see the [GitHub Workflow Examples](/docs/github-workflow-examples/index.md) directory.

### With GitLab CI/CD

See the [GitLab Integration Guide](/docs/integration/gitlab.md) and [GitLab Pipeline Examples](/docs/gitlab-pipeline-examples/index.md) for detailed examples of using these profiles in GitLab pipelines.

### Manually

```bash
# From the root directory of this repository:
./scripts/scan-container.sh inspec-test inspec-target busybox ./examples/cinc-profiles/container-baseline
```

### Distroless Containers

For distroless containers, we currently support two approaches:
1. The Debug Container Approach (using ephemeral debug containers)
2. The Sidecar Container Approach (using shared process namespaces)

Both are intended as interim solutions while we enhance the train-k8s-container plugin to support distroless containers through the primary Kubernetes API Approach. See [Distroless Containers](/docs/distroless-containers.md) for implementation details.

## Customizing Profiles

You can customize the profiles to match your security requirements:

1. Create a copy of an existing profile
2. Modify the controls to match your requirements
3. Add new controls for your specific use cases

### Example: Adding a New Control

Create a new file in the `controls` directory, like `04_custom_checks.rb`:

```ruby
# encoding: utf-8
# copyright: 2023

title 'Custom Checks'

control 'container-4.1' do
  impact 0.7
  title 'Check for required environment variables'
  desc 'Container should have required environment variables'
  
  describe os_env('PATH') do
    its('content') { should include '/usr/local/bin' }
  end
  
  describe os_env('SECURE_MODE') do
    its('content') { should eq 'enabled' }
  end
end
```

## Integration with Security Tools

These profiles can be integrated with other security tools:

- Security scanners (Trivy, Clair, etc.)
- Compliance dashboards
- CI/CD pipeline quality gates

For example, you can create a composite score by combining:
1. Static vulnerability scanning (using Trivy)
2. Runtime checks (using these CINC Auditor profiles)
3. Network policy validation

## References

- [CINC Auditor Documentation](https://cinc.sh/start/auditor/)
- [InSpec Profile Documentation](https://docs.chef.io/inspec/profiles/)
- [Ruby Language Documentation](https://ruby-doc.org/)