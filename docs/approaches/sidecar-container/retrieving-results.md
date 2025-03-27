# Retrieving Results from Sidecar Container Scans

This document explains how to retrieve and process scan results from the sidecar container scanning approach.

## Overview

When using the sidecar container approach, scan results are generated within the scanner container. There are several methods for retrieving these results for analysis and reporting.

## Result Storage Locations

Scan results are typically stored in a predetermined location within the sidecar container. By default, this might be configured as `/opt/scan-results` or a similar path defined in your deployment configuration.

The scanner generates results in JSON format, which is already in Heimdall Data Format (HDF) when using InSpec/CINC Auditor.

## Methods for Retrieving Results

### 1. Volume Mounts

The most straightforward method is to mount a volume that both the scanner container and an external process can access:

```yaml
volumes:
- name: results-volume
  persistentVolumeClaim:
    claimName: scan-results-pvc
```

Then mount this volume to your scanner container:

```yaml
volumeMounts:
- name: results-volume
  mountPath: /opt/scan-results
```

### 2. Using kubectl cp

You can copy files from the scanner container using `kubectl cp`:

```bash
kubectl cp <namespace>/<pod-name>:<path-in-container> <local-path> -c scanner
```

Example:

```bash
kubectl cp default/app-with-scanner:/opt/scan-results/results.json ./results/
```

## Processing Results with SAF CLI

The [Security Automation Framework (SAF) CLI](https://saf-cli.mitre.org/) is a powerful tool for processing and analyzing security scan results.

### Working with InSpec/CINC Auditor Results

InSpec/CINC Auditor JSON results are already in Heimdall Data Format (HDF), so no conversion is needed for use with SAF CLI.

### Threshold Evaluation

Validate results against defined thresholds:

```bash
saf validate threshold -i results.json -t threshold.yaml
```

### Viewing Results

View a summary of scan results directly from the command line:

```bash
saf view summary -i results.json
```

Launch Heimdall Lite for visual analysis:

```bash
saf view heimdall -i results.json
```

### Creating Threshold Files

Generate a threshold template based on your results:

```bash
saf generate threshold -i results.json -o threshold.yaml
```

## Integration with CI/CD

For CI/CD integration, you can:

1. Extract results using volume mounts or kubectl cp
2. Use SAF CLI to validate against thresholds
3. Fail the pipeline if thresholds aren't met

Example CI/CD script:

```bash
#!/bin/bash
# Copy results from container
kubectl cp default/scanner-pod:/opt/scan-results/results.json ./results.json

# Validate against thresholds using SAF CLI
saf validate threshold -i results.json -t threshold.yaml

# Check exit code
if [ $? -ne 0 ]; then
  echo "Scan failed to meet security thresholds"
  exit 1
fi
```

## Next Steps

- [Pod Configuration](pod-configuration.md) - Learn how to configure pods with sidecars
- [Implementation Details](implementation.md) - Understand how the sidecar scanning works
