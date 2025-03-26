# STIG/SRG API Tools

This document describes useful online tools and APIs for accessing, validating, and working with DISA STIGs and SRGs in documentation and code.

## Cyber Trackr Live

[Cyber Trackr Live](https://cyber.trackr.live/) is a valuable online resource that provides access to Security Technical Implementation Guides (STIGs) and Security Requirements Guides (SRGs) through both a web interface and API.

### Web Interface

The web interface allows browsing and searching STIGs and SRGs by:
- Title
- Version
- Release date
- Content

For example, to view the Kubernetes STIG v1r11:
```
https://cyber.trackr.live/stig/Kubernetes/1/11
```

### API Usage

Cyber Trackr Live offers a robust API for programmatic access to STIGs and SRGs, which can be extremely valuable for:
- Validation of STIG/SRG requirements in documentation
- Automated compliance checking
- Building tools that integrate with STIG content
- Keeping documentation aligned with the latest STIG releases

#### API Endpoints

The base API URL is `https://cyber.trackr.live/api/`

| Endpoint | Description | Example |
|----------|-------------|---------|
| `/stig` | List all available STIGs | `https://cyber.trackr.live/api/stig` |
| `/stig/{title}/{version}/{release}` | Get specific STIG | `https://cyber.trackr.live/api/stig/Kubernetes/2/2` |

#### Getting a List of STIGs

```bash
curl -X GET https://cyber.trackr.live/api/stig
```

This returns a JSON object with available STIGs grouped by title, including all versions and releases.

Example response format:
```json
{
  "Kubernetes": [
    {
      "date": "2024-08-22",
      "released": "24 Oct 2024",
      "version": "2",
      "release": "2",
      "link": "/stig/Kubernetes/2/2"
    },
    {
      "date": "2023-08-29",
      "released": "25 Oct 2023",
      "version": "1",
      "release": "11",
      "link": "/stig/Kubernetes/1/11"
    }
    // Additional versions...
  ]
  // Other STIGs...
}
```

#### Getting a Specific STIG

To retrieve details for a specific STIG, including all requirements:

```bash
curl -X GET https://cyber.trackr.live/api/stig/Kubernetes/2/2
```

This returns detailed information including:
- STIG metadata (release date, version)
- Requirements with vulnerability IDs (V-######)
- Rule descriptions
- Check procedures
- Fix procedures

### Using the API for Documentation Validation

The API can be used to validate documentation against official STIG/SRG content:

1. **Verify Accuracy of Requirement References**:
   ```bash
   # Get specific requirement
   curl -X GET https://cyber.trackr.live/api/stig/Kubernetes/2/2 | jq '.[] | select(.vulnId=="V-242407")'
   ```

2. **Check for Updated Requirements**:
   ```bash
   # Compare versions
   curl -X GET https://cyber.trackr.live/api/stig/Kubernetes/1/11 > v1r11.json
   curl -X GET https://cyber.trackr.live/api/stig/Kubernetes/2/2 > v2r2.json
   diff <(jq -r '.[].vulnId' v1r11.json | sort) <(jq -r '.[].vulnId' v2r2.json | sort)
   ```

3. **Extract Requirement Text**:
   ```bash
   # Get requirement title and description
   curl -X GET https://cyber.trackr.live/api/stig/Kubernetes/2/2 | jq '.[] | select(.vulnId=="V-242407") | {title: .title, description: .description}'
   ```

### Integration into Documentation Workflow

This API can be integrated into documentation workflows to:

1. **Generate Documentation Stubs**:
   - Create initial compliance documentation with correct IDs and descriptions
   - Generate skeleton files for STIG/SRG requirements

2. **Validate Documentation Accuracy**:
   - Check that requirement IDs mentioned in documentation exist
   - Verify descriptions match official sources
   - Flag outdated references when new STIG versions are released

3. **Create Custom Compliance Reports**:
   - Generate reports showing alignment with specific STIGs
   - Create matrices showing coverage across multiple STIGs

## Implementation Example: STIG ID Validator Script

Here's a simple example script that could validate STIG IDs in markdown documentation:

```bash
#!/bin/bash
# validate-stig-ids.sh - Validate STIG IDs in markdown files
# 
# Extracts V-IDs from markdown files and validates them against the Cyber Trackr API

# Extract all V-IDs from markdown files
FOUND_IDS=$(grep -o 'V-[0-9]\{6\}' docs/security/compliance/*.md | sort | uniq)

# Get the official list from the API
OFFICIAL_IDS=$(curl -s https://cyber.trackr.live/api/stig/Kubernetes/2/2 | jq -r '.[].vulnId' | sort)

# Compare and report
echo "Validating STIG IDs in documentation..."
for id in $FOUND_IDS; do
  if echo "$OFFICIAL_IDS" | grep -q "$id"; then
    echo "✅ $id - Valid"
  else
    echo "❌ $id - Not found in official STIG"
  fi
done
```

## Related Documentation

- [Documentation Tools](documentation-tools.md) - Other documentation tools
- [Contributing Guidelines](index.md) - General contribution guidelines
- [DISA Container Platform SRG](../security/compliance/disa-srg.md) - Our SRG alignment
- [Kubernetes STIG](../security/compliance/kubernetes-stig.md) - Our STIG alignment