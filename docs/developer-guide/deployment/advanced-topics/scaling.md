# Scaling and Performance

This guide provides detailed guidance on scaling and optimizing performance for the Secure CINC Auditor Kubernetes Container Scanning solution.

## Overview

As the number of containers to scan increases, proper scaling and resource allocation become critical for maintaining performance and reliability. This guide covers strategies for scaling the scanner to handle large Kubernetes environments.

## Parallel Scanning

Distribute scanning load across multiple scanner instances to increase throughput:

```yaml
# parallel-scanning-values.yaml
scanner:
  parallelism:
    enabled: true
    maxConcurrent: 5
    queueSize: 100
  resources:
    requests:
      cpu: 250m
      memory: 256Mi
    limits:
      cpu: 1000m
      memory: 1Gi
```

### Key Parallelism Parameters

- **maxConcurrent**: Maximum number of concurrent scans
- **queueSize**: Size of the scan request queue
- **processingStrategy**: Choose between `parallel` or `sequential` processing

### Parallelism Considerations

- Increase maxConcurrent for faster processing but watch resource usage
- Use larger queueSize for bursty workloads
- Consider worker pods for distributing scanning workloads

## Resource Allocation

Properly allocate CPU and memory resources based on your environment size:

| Environment Size | Containers | CPU Request | Memory Request | CPU Limit | Memory Limit |
|------------------|------------|-------------|----------------|-----------|--------------|
| Small            | <50        | 250m        | 256Mi          | 500m      | 512Mi        |
| Medium           | 50-200     | 500m        | 512Mi          | 1000m     | 1Gi          |
| Large            | 200-1000   | 1000m       | 1Gi            | 2000m     | 2Gi          |
| Enterprise       | >1000      | 2000m       | 2Gi            | 4000m     | 4Gi          |

### Tuning Resource Allocations

For optimal resource utilization:

```yaml
# optimized-resources-values.yaml
scanner:
  resources:
    requests:
      cpu: "1"
      memory: 1Gi
    limits:
      cpu: "2"
      memory: 2Gi
  
  tuning:
    memoryBufferPercent: 20
    cpuThrottling: false
    optimizeFor: throughput  # or latency
```

## Result Storage

Implement centralized storage for scan results to handle large volumes of data:

```yaml
# storage-values.yaml
persistence:
  enabled: true
  storageClass: managed-premium
  accessMode: ReadWriteMany
  size: 20Gi
  retention:
    days: 90
    maxSize: 50Gi
```

### Storage Considerations

- Use ReadWriteMany access mode for multi-scanner deployments
- Implement appropriate retention policies
- Consider cloud-based storage for enterprise deployments

### Storage Provider Options

```yaml
# storage-providers-values.yaml
persistence:
  provider: aws  # or azure, gcp, local
  aws:
    bucketName: scanner-results
    region: us-west-2
  
  compression:
    enabled: true
    format: gzip
```

## Horizontal Pod Autoscaling

Configure Horizontal Pod Autoscaling (HPA) for dynamic scaling based on workload:

```yaml
# hpa-values.yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80
```

### Advanced HPA Configuration

For more precise control over scaling behavior:

```yaml
# advanced-hpa-values.yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  metrics:
    - type: Resource
      resource:
        name: cpu
        targetAverageUtilization: 70
    - type: Resource
      resource:
        name: memory
        targetAverageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 15
```

## Distribution and Scheduling

Optimize pod distribution across nodes:

```yaml
# distribution-values.yaml
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
              - key: app
                operator: In
                values:
                  - scanner
          topologyKey: kubernetes.io/hostname
  
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        preference:
          matchExpressions:
            - key: node-role.kubernetes.io/worker
              operator: Exists
```

## Performance Tuning

Fine-tune scanner performance for specific environments:

```yaml
# performance-tuning-values.yaml
scanner:
  performance:
    concurrency: 4
    memoryOptimization: true
    scanTimeout: 600
    batchSize: 20
    workerPoolSize: 5
    
  profiles:
    optimized: true
    excludeControls:
      - resource-intensive-control-1
      - resource-intensive-control-2
```

### Scanner Performance Parameters

- **concurrency**: Number of concurrent scans per scanner pod
- **memoryOptimization**: Enable memory usage optimizations
- **scanTimeout**: Maximum time for a scan to complete
- **batchSize**: Number of containers processed in a single batch
- **workerPoolSize**: Size of the worker pool for processing

## Scaling Across Multiple Clusters

For large enterprises with multiple Kubernetes clusters:

```yaml
# multi-cluster-values.yaml
multiCluster:
  enabled: true
  strategy: federation  # or aggregation
  centralized:
    reporting: true
    storage: true
  
  clusters:
    - name: cluster-1
      kubeconfig: /path/to/kubeconfig-1
    - name: cluster-2
      kubeconfig: /path/to/kubeconfig-2
```

## Performance Benchmarks

Use these benchmarks as a reference for sizing your deployment:

| Environment | Scanner Pods | Concurrent Scans | Containers Scanned | Time to Complete |
|-------------|--------------|------------------|-------------------|------------------|
| Small       | 1            | 5                | 50                | ~10 minutes      |
| Medium      | 2            | 10               | 200               | ~25 minutes      |
| Large       | 5            | 20               | 1000              | ~60 minutes      |
| Enterprise  | 10+          | 50+              | 5000+             | ~3 hours         |

## Related Topics

- [Monitoring and Maintenance](monitoring.md)
- [Helm Deployment](../helm-deployment.md)
- [Advanced Security](security.md)
