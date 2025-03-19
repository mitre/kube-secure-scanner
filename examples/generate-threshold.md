# Generating SAF Threshold Files

MITRE's Security Automation Framework (SAF) CLI includes a feature to generate threshold files based on existing scan results. This can be useful for establishing an initial baseline.

## Using the SAF Generate Threshold Command

The `saf generate threshold` command creates a threshold file based on existing InSpec/CINC Auditor scan results:

```bash
# Basic usage
saf generate threshold -i scan-results.json -o threshold.yml

# With compliance margin
saf generate threshold -i scan-results.json -o threshold.yml --margin 5
```

## Example Usage

1. Run a baseline scan to get initial results:

```bash
# Run CINC Auditor scan
cinc-auditor exec my-profile -t k8s-container://namespace/pod/container --reporter json:baseline-scan.json
```

2. Generate a threshold file based on current compliance:

```bash
# Generate with 5% margin (if baseline is 82%, threshold becomes 77%)
saf generate threshold -i baseline-scan.json -o threshold.yml --margin 5

# Or generate with specific compliance percentage
saf generate threshold -i baseline-scan.json -o threshold.yml --compliance 80
```

3. Examine and adjust the generated threshold file:

```bash
# View the generated threshold
cat threshold.yml
```

4. Use the generated threshold for future scans:

```bash
# Validate future scans against the threshold
saf threshold -i new-scan.json -t threshold.yml
```

## Options for Generate Threshold

The `generate threshold` command supports these options:

- `-i, --input <file>`: Input file (InSpec JSON results)
- `-o, --output <file>`: Output file for threshold (YAML or JSON format)
- `--margin <percentage>`: Margin to subtract from current compliance (default: 0)
- `--compliance <percentage>`: Set a specific compliance percentage
- `--format <yaml|json>`: Output format (default: yaml)

## Best Practices

1. **Review generated thresholds**: Always manually review generated thresholds before using them
2. **Add a margin**: Use the `--margin` option to provide some flexibility
3. **Customize further**: Edit the generated file to add or modify specific criteria
4. **Version control**: Store threshold files in version control with your code
5. **Regular updates**: Regenerate thresholds as your security posture improves

## Example Generated Threshold

A generated threshold file might look like:

```yaml
compliance:
  min: 75
failed:
  critical:
    max: 0
  high:
    max: 3
  medium:
    max: 5
  low:
    max: 7
skipped:
  total:
    max: 4
error:
  total:
    max: 0
```