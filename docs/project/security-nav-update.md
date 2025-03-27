# Security Navigation Updates

This document outlines the changes needed to update the mkdocs.yml navigation to reflect the reorganized security section structure.

## Current Navigation (Before)

```yaml
- Security:
  - Overview: security/overview.md
  - Risk Analysis: security/risk-analysis.md
  - Security Analysis: security/analysis.md
  - Compliance Analysis: security/compliance.md
```

## Updated Navigation (After)

```yaml
- Security:
  - Overview: security/index.md
  - Directory: security/inventory.md
  - Security Principles:
    - Overview: security/principles/index.md
    - Directory: security/principles/inventory.md
    - Least Privilege: security/principles/least-privilege.md
    - Ephemeral Credentials: security/principles/ephemeral-creds.md
    - Resource Isolation: security/principles/resource-isolation.md
    - Secure Transport: security/principles/secure-transport.md
  - Risk Analysis:
    - Overview: security/risk/index.md
    - Directory: security/risk/inventory.md
    - Risk Model: security/risk/model.md
    - Kubernetes API Approach: security/risk/kubernetes-api.md
    - Debug Container Approach: security/risk/debug-container.md
    - Sidecar Container Approach: security/risk/sidecar-container.md
    - Risk Mitigations: security/risk/mitigations.md
  - Threat Model:
    - Overview: security/threat-model/index.md
    - Directory: security/threat-model/inventory.md
    - Attack Vectors: security/threat-model/attack-vectors.md
    - Lateral Movement: security/threat-model/lateral-movement.md
    - Token Exposure: security/threat-model/token-exposure.md
    - Threat Mitigations: security/threat-model/threat-mitigations.md
  - Compliance:
    - Overview: security/compliance/index.md
    - Directory: security/compliance/inventory.md
    - Approach Comparison: security/compliance/approach-comparison.md
    - Risk Documentation: security/compliance/risk-documentation.md
  - Recommendations:
    - Overview: security/recommendations/index.md
    - Directory: security/recommendations/inventory.md
```

## Changes Summary

1. **Main Navigation**
   - Changed security overview link from `security/overview.md` to `security/index.md`
   - Added `security/inventory.md` as "Directory"

2. **New Subdirectory Navigation**
   - Added five new subdirectory sections:
     - Security Principles
     - Risk Analysis
     - Threat Model
     - Compliance
     - Recommendations

3. **Entry Points and Content**
   - Each subdirectory has:
     - Overview (index.md)
     - Directory (inventory.md)
     - Topic-specific content files

4. **Removed Obsolete Entries**
   - Removed direct links to old files:
     - `security/risk-analysis.md`
     - `security/analysis.md`
     - `security/compliance.md`
     - `security/overview.md`

## Implementation Notes

When implementing this navigation update:

1. Ensure all file paths are correct (especially watch for typos in directory names)
2. Verify that all referenced files exist in the correct locations
3. Maintain proper indentation in the YAML structure
4. Test navigation after changes to ensure all links work correctly
5. The old files can be retained in the repository as redirects to their new locations if needed

## Benefits

1. **Logical Organization**
   - Clear, hierarchical structure for security documentation
   - Improved content discoverability

2. **Progressive Disclosure**
   - Top-level navigation shows major security categories
   - Drill-down for detailed information

3. **Consistency**
   - Follows the same pattern used in the approaches section
   - Standardized structure across documentation

This navigation update should be applied to the mkdocs.yml file as part of completing the security section reorganization.
