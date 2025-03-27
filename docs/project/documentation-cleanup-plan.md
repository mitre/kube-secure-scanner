# Documentation Cleanup and Stabilization Plan

This document outlines our systematic approach to stabilizing the documentation structure after the comprehensive reorganization. It serves as a reference for maintaining continuity in the cleanup process.

## Current Understanding

### Reorganization Process

- Large documentation files were broken into smaller, focused files organized in subdirectories
- Each section follows a consistent pattern: index.md (overview), inventory.md (listing), and specific topic files
- Original files and new reorganized structure currently coexist
- Reorganization documented in `/docs/project/*-reorganization-summary.md` files

### Current State

- Navigation in mkdocs.yml mostly points to the new structure
- Cross-references in content still often point to old file paths
- Both old files (e.g., `kubernetes-api.md`) and new structure (e.g., `kubernetes-api/index.md`) exist

### Reorganized Sections

- **Approaches**: kubernetes-api/, debug-container/, sidecar-container/, helper-scripts/
- **Architecture**: components/, deployment/, diagrams/, integrations/, workflows/
- **Configuration**: advanced/, integration/, kubeconfig/, plugins/, security/, thresholds/
- **Contributing**: testing/
- **Developer Guide**: deployment/ (including advanced-topics/, scenarios/), testing/
- **Helm Charts**: overview/, scanner-types/, infrastructure/, usage/, security/, operations/
- **Integration**: platforms/, workflows/, examples/, configuration/
- **Security**: principles/, risk/, compliance/, threat-model/, recommendations/
- **Other Directories**: examples/, github-workflow-examples/, gitlab-pipeline-examples/, gitlab-services-examples/, kubernetes-setup/, overview/, rbac/, service-accounts/, tokens/, utilities/

## Order of Operations

### Phase 1: Preparation

1. **Create backup directory**

   ```bash
   mkdir -p /Users/alippold/github/mitre/kube-secure-scanner/docs-backup
   ```

2. **Create TODO list document**
   - Document placeholder files that need to be created
   - Track content gaps identified during reorganization

### Phase 2: Approaches Section Cleanup

1. **Identify cross-references**
   - Find all references to old file paths (e.g., `kubernetes-api.md`)
   - Document the files that need updating

2. **Update cross-references**
   - Update links to point to new structure
   - Follow established patterns:
     - `approaches/kubernetes-api.md` → `approaches/kubernetes-api/index.md`
     - `approaches/debug-container.md` → `approaches/debug-container/index.md`
     - `approaches/sidecar-container.md` → `approaches/sidecar-container/index.md`

3. **Move old files to backup**
   - Move original files to docs-backup directory at the project root
   - Maintain directory structure for reference

### Phase 3: Integration Section Cleanup

1. **Identify cross-references**
   - Find all references to old file paths

2. **Update cross-references**
   - Update links to point to new structure
   - Follow established patterns:
     - `integration/github-actions.md` → `integration/platforms/github-actions.md`
     - `integration/gitlab.md` → `integration/platforms/gitlab-ci.md`
     - `integration/gitlab-services.md` → `integration/platforms/gitlab-services.md`
     - `integration/overview.md` → `integration/index.md`

3. **Move old files to backup**
   - Move any remaining original files to backup directory

### Phase 4: Architecture Section Cleanup

1. **Identify cross-references**
   - Find all references to old file paths (e.g., `architecture/workflows.md`)

2. **Update cross-references**
   - Update links to point to new structure
   - Follow patterns:
     - `architecture/workflows.md` → `architecture/workflows/index.md`
     - `architecture/diagrams.md` → `architecture/diagrams/index.md`

3. **Move old files to backup**
   - Move original files to backup directory

### Phase 5: Configuration Section Cleanup

1. **Identify cross-references**
   - Find all references to old configuration files

2. **Update cross-references**
   - Update links to point to new subdirectory structure

3. **Move old files to backup**
   - Move original files to backup directory

### Phase 6: Security Section Cleanup

1. **Identify cross-references**
   - Find all references to old file paths

2. **Update cross-references**
   - Update links to point to new structure
   - Follow established patterns

3. **Move old files to backup**
   - Move original files to backup directory

### Phase 7: Helm Charts Section Cleanup

1. **Identify cross-references**
   - Find all references to old file paths

2. **Update cross-references**
   - Update links to point to new structure

3. **Move old files to backup**
   - Move original files to backup directory

### Phase 8: Developer Guide Section Cleanup

1. **Identify cross-references**
   - Find all references to old file paths (e.g., `developer-guide/deployment/scenarios.md`)

2. **Update cross-references**
   - Update links to point to appropriate subdirectory files

3. **Move old files to backup**
   - Move original files to backup directory

### Phase 9: Validation and Finalization

1. **Build documentation**

   ```bash
   ./docs-tools.sh build
   ```

2. **Check for warnings**
   - Review build output for warnings about missing files or broken links
   - Update any remaining issues

3. **Run link checker**

   ```bash
   ./docs-tools.sh links
   ```

4. **Verify navigation**
   - Preview the documentation
   - Test navigation paths for key user journeys

5. **Review backup files**
   - Confirm all content from old files exists in the new structure
   - Document any content that still needs to be migrated

## Cross-Reference Patterns

### Approaches Section

- `approaches/kubernetes-api.md` → `approaches/kubernetes-api/index.md`
- `approaches/debug-container.md` → `approaches/debug-container/index.md`
- `approaches/sidecar-container.md` → `approaches/sidecar-container/index.md`
- `approaches/direct-commands.md` → `approaches/helper-scripts/scripts-vs-commands.md`

### Architecture Section

- `architecture/workflows.md` → `architecture/workflows/index.md`
- `architecture/diagrams.md` → `architecture/diagrams/index.md`
- `architecture/components.md` → `architecture/components/index.md` (if exists)

### Configuration Section

- `configuration/kubeconfig.md` → `configuration/kubeconfig/index.md` (if exists)
- `configuration/thresholds.md` → `configuration/thresholds/index.md`
- `configuration/plugins.md` → `configuration/plugins/index.md` (if exists)
- `configuration/security.md` → `configuration/security/index.md` (if exists)

### Developer Guide Section

- `developer-guide/deployment/scenarios.md` → `developer-guide/deployment/scenarios/index.md`
- `developer-guide/deployment/advanced-topics.md` → `developer-guide/deployment/advanced-topics/index.md`

### Integration Section

- `integration/github-actions.md` → `integration/platforms/github-actions.md`
- `integration/gitlab.md` → `integration/platforms/gitlab-ci.md`
- `integration/gitlab-services.md` → `integration/platforms/gitlab-services.md`
- `integration/overview.md` → `integration/index.md`

### Security Section

- `security/analysis.md` → Multiple files in subdirectories
- `security/compliance.md` → `security/compliance/index.md`
- `security/risk-analysis.md` → `security/risk/index.md`
- `security/overview.md` → `security/index.md`
- `security/principles.md` → `security/principles/index.md` (if exists)
- `security/threat-model.md` → `security/threat-model/index.md` (if exists)

### Helm Charts Section

- `helm-charts/architecture.md` → `helm-charts/overview/architecture.md`
- `helm-charts/common-scanner.md` → `helm-charts/scanner-types/common-scanner.md`
- `helm-charts/distroless-scanner.md` → `helm-charts/scanner-types/distroless-scanner.md`
- `helm-charts/sidecar-scanner.md` → `helm-charts/scanner-types/sidecar-scanner.md`
- `helm-charts/standard-scanner.md` → `helm-charts/scanner-types/standard-scanner.md`
- `helm-charts/scanner-infrastructure.md` → `helm-charts/infrastructure/index.md`
- `helm-charts/security.md` → `helm-charts/security/index.md`
- `helm-charts/troubleshooting.md` → `helm-charts/operations/troubleshooting.md`
- `helm-charts/overview.md` → `helm-charts/overview/index.md`
- `helm-charts/customization.md` → `helm-charts/usage/customization.md`

### Other Directories

- From root paths to appropriate subdirectory paths based on reorganization pattern

## Useful Commands

### Finding Cross-References

```bash
# Find references to old file paths
grep -r "kubernetes-api\.md" --include="*.md" /Users/alippold/github/mitre/kube-secure-scanner/docs | grep -v node_modules

# Find all markdown files in a directory
find /Users/alippold/github/mitre/kube-secure-scanner/docs/approaches -type f -name "*.md" | sort

# List reorganization summary files
ls -la /Users/alippold/github/mitre/kube-secure-scanner/docs/project/*reorganization*
```

### Viewing Directory Structure

```bash
# View directory structure with tree command
tree -L 2 /Users/alippold/github/mitre/kube-secure-scanner/docs/approaches

# View directory structure with limited depth
tree -L 1 /Users/alippold/github/mitre/kube-secure-scanner/docs
tree -L 3 /Users/alippold/github/mitre/kube-secure-scanner/docs/approaches
```

### Backup Operations

```bash
# Create backup directory
mkdir -p /Users/alippold/github/mitre/kube-secure-scanner/docs-backup

# Move a file to backup (preserving directory structure)
mkdir -p /Users/alippold/github/mitre/kube-secure-scanner/docs-backup/approaches
mv /Users/alippold/github/mitre/kube-secure-scanner/docs/approaches/kubernetes-api.md /Users/alippold/github/mitre/kube-secure-scanner/docs-backup/approaches/
```

### Documentation Tools

```bash
# Build documentation
./docs-tools.sh build

# Check links
./docs-tools.sh links

# Preview documentation
./docs-tools.sh preview
```

## Note on Context Restoration

This document serves as a reference for restoring context when returning to the documentation cleanup task. Refer to this file to quickly understand the state of the reorganization and next steps in the process.
