# Performance Optimization Guide

!!! info "Directory Context"
    This document is part of the [Operations Directory](index.md). See the [Operations Directory Inventory](inventory.md) for related resources.

## Overview

This guide provides strategies for optimizing the performance of the Secure Kubernetes Container Scanning Helm charts. Proper performance tuning is essential for running efficient scanning operations, particularly in environments with many containers or limited resources.

## Performance Factors

Several factors affect container scanning performance:

1. **Profile Complexity**: The number of controls and their complexity
2. **Container Size**: The size of the target container's filesystem
3. **Network Latency**: The latency between scanner and target
4. **Resource Allocation**: CPU and memory allocated to scanner components
5. **Concurrency**: The number of concurrent scans
6. **Scanning Approach**: Different approaches have different performance characteristics

## Performance Optimization Strategies

### 1. Profile Optimization

Optimize your CINC Auditor profiles for better performance:

```ruby
# Efficient file checking using wildcards
describe file('/etc/passwd') do
  it { should exist }
end

# Instead of checking every file in a directory individually,
# use a single check with wildcard for better performance
describe command('find /etc -name "*.conf" -type f -perm -o+w | wc -l') do
  its('stdout.strip') { should eq '0' }
end
```

Create focused, purpose-specific profiles:

```bash
# Create a lightweight profile for basic checks
cat > basic-profile/inspec.yml << EOF
name: basic-profile
version: 1.0.0
depends:
  - name: container-baseline
    path: ../container-baseline
    skip_controls:
      - filesystem_checks
      - process_checks
EOF

# Use the lightweight profile for faster scans
./kubernetes-scripts/scan-container.sh scanning-namespace target-pod container-name ./basic-profile
```

### 2. Resource Allocation

Adjust resource limits and requests for scanner containers:

```bash
# Optimize sidecar scanner resources
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set scanner.resources.requests.cpu=200m \
  --set scanner.resources.requests.memory=256Mi \
  --set scanner.resources.limits.cpu=500m \
  --set scanner.resources.limits.memory=512Mi
```

For debug containers:

```bash
# Optimize debug container resources
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set debugContainer.resources.requests.cpu=100m \
  --set debugContainer.resources.requests.memory=128Mi \
  --set debugContainer.resources.limits.cpu=200m \
  --set debugContainer.resources.limits.memory=256Mi
```

### 3. Scan Timing and Scheduling

Schedule scans during off-peak hours:

```bash
# Example cron job for off-peak scanning
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-scan
  namespace: scanning-namespace
spec:
  schedule: "0 2 * * *"  # Run at 2 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: scanner
            image: scanner-image:latest
            command: ["/bin/sh", "-c"]
            args:
            - |
              ./kubernetes-scripts/scan-container.sh scanning-namespace target-pod container-name ./profiles/container-baseline
          restartPolicy: OnFailure
```

### 4. Parallel Scanning

Implement parallel scanning for multiple containers:

```bash
#!/bin/bash
# parallel-scan.sh
NAMESPACE="scanning-namespace"
PODS=$(kubectl get pods -n $NAMESPACE -l app=target-app -o jsonpath='{.items[*].metadata.name}')

# Scan pods in parallel
for POD in $PODS; do
  ./kubernetes-scripts/scan-container.sh $NAMESPACE $POD container-name ./profiles/container-baseline --output-file=results-$POD.json &
done

# Wait for all background processes to complete
wait

# Process results
for POD in $PODS; do
  echo "Results for $POD:"
  saf summary --input results-$POD.json --output-md summary-$POD.md
done
```

### 5. Approach-Specific Optimizations

#### Kubernetes API Scanner (Standard)

```bash
# Optimize standard scanner
helm install standard-scanner ./helm-charts/standard-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set common-scanner.scripts.includeScanScript=true \
  --set common-scanner.scripts.includeDistrolessScanScript=false \
  --set common-scanner.scripts.includeSidecarScanScript=false
```

Use direct transport invocation for faster scanning:

```bash
# Direct transport for better performance
KUBECONFIG=./kubeconfig.yaml cinc-auditor exec ./profiles/container-baseline \
  -t k8s-container://scanning-namespace/target-pod/container --sudo=false
```

#### Debug Container Scanner (Distroless)

```bash
# Optimize debug container approach
helm install distroless-scanner ./helm-charts/distroless-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set debugContainer.image=alpine:3.15  # Smaller image
```

Use minimal debug container image:

```yaml
# Minimal debug container for faster startup
debugContainer:
  image: busybox:musl  # Smaller than alpine
  command: null
  args: null
  timeout: 300  # Shorter timeout
```

#### Sidecar Scanner

```bash
# Optimize sidecar scanner
helm install sidecar-scanner ./helm-charts/sidecar-scanner \
  --set common-scanner.scanner-infrastructure.targetNamespace=scanning-namespace \
  --set scanner.image=chef/inspec:slim  # Use smaller image if available
```

### 6. CINC Auditor Performance Tuning

Enable CINC Auditor caching:

```bash
# Use caching for repeated scans
INSPEC_CACHE_ENABLED=true \
INSPEC_CACHE_LOCATION=/tmp/inspec-cache \
./kubernetes-scripts/scan-container.sh scanning-namespace target-pod container-name ./profiles/container-baseline
```

Disable unnecessary reporters:

```bash
# Use only required reporters
./kubernetes-scripts/scan-container.sh scanning-namespace target-pod container-name \
  ./profiles/container-baseline --reporter json:/results/scan-results.json
```

## Performance Benchmarks

### Scanning Approach Comparison

| Approach | Small Container | Medium Container | Large Container |
|----------|----------------|-----------------|----------------|
| Kubernetes API | 5-10 seconds | 10-30 seconds | 30-120 seconds |
| Debug Container | 15-30 seconds | 30-60 seconds | 60-180 seconds |
| Sidecar Container | 5-15 seconds | 15-45 seconds | 45-150 seconds |

*Note: Actual times will vary based on profile complexity, container content, and system resources.*

### Profile Performance Impact

| Profile Type | Controls | Scan Time Impact |
|--------------|----------|-----------------|
| Basic Security | 10-20 | Minimal |
| CIS Benchmark | 50-100 | Moderate |
| Full Compliance | 100+ | Significant |

## Performance Monitoring

### Resource Usage Monitoring

Monitor resource usage during scans:

```bash
# Monitor scanner pod resource usage
kubectl top pod -n scanning-namespace scanner-pod --containers

# Monitor debug container usage
kubectl top pod -n scanning-namespace target-pod
```

### Scan Timing Metrics

Collect scan timing metrics:

```bash
# Add timing to scan script
time ./kubernetes-scripts/scan-container.sh scanning-namespace target-pod container-name ./profiles/container-baseline

# Output detailed timing in profiles
control 'container-1.1' do
  impact 0.7
  title 'Ensure container has proper permissions'
  
  describe.one do
    start_time = Time.now
    describe file('/etc/passwd') do
      it { should exist }
      it { should be_owned_by 'root' }
    end
    puts "Executed control container-1.1 in #{Time.now - start_time} seconds"
  end
end
```

## Optimizing for Different Environments

### CI/CD Pipeline Optimization

For CI/CD environments, focus on speed:

```bash
# CI/CD optimized scan
./kubernetes-scripts/scan-container.sh ci-namespace target-pod container-name ./profiles/ci-profile \
  --reporter json-min:/results/scan-results.json
```

Use a streamlined CI profile:

```ruby
# ci-profile/inspec.yml
name: ci-profile
version: 1.0.0
depends:
  - name: container-baseline
    path: ../container-baseline
    controls:
      - critical_controls  # Only run critical controls for faster CI
```

### Production Environment Optimization

For production environments, balance thoroughness with performance:

```bash
# Production scan with optimal balance
./kubernetes-scripts/scan-container.sh prod-namespace target-pod container-name ./profiles/prod-profile \
  --reporter json:/results/scan-results.json \
  --ignore-warning-controls  # Skip warning-level controls
```

### Large-Scale Environment Optimization

For environments with many containers:

```bash
# Distributed scanning with multiple scanners
for NAMESPACE in namespace1 namespace2 namespace3; do
  kubectl create job --from=cronjob/scanner-job scanner-$NAMESPACE -n scanning-namespace
done
```

## Conclusion

Optimizing container scanning performance requires a multi-faceted approach. By fine-tuning profiles, resource allocation, and scanning strategies, you can significantly improve scanning efficiency while maintaining security effectiveness.

## Related Documentation

- [Troubleshooting](troubleshooting.md)
- [Maintenance Procedures](maintenance.md)
- [Scanner Types](../scanner-types/index.md)
- [Usage & Customization](../usage/index.md)
