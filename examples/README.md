# Examples for Secure Container Scanning

This directory contains example resources for demonstrating secure Kubernetes container scanning with CINC Auditor.

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

### Manually

```bash
# From the root directory of this repository:
./scripts/scan-container.sh inspec-test inspec-target busybox ./examples/cinc-profiles/container-baseline
```

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