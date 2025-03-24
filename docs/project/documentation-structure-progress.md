# Documentation Structure Reorganization Progress

This document tracks the progress of our documentation structure reorganization, focusing on the migration from README.md files to index.md and inventory.md files across the project.

## Overview

As part of our documentation modernization, we're implementing a consistent pattern across all directories:

1. **index.md** - Main content file for each directory, serving as the entry point in MkDocs
2. **inventory.md** - Directory listing showing all files and subdirectories with descriptions
3. **Remove README.md** - Eliminate README.md files that conflict with index.md in MkDocs

This structure resolves conflicts in MkDocs while maintaining browsability in GitHub.

## Progress Matrix

| Directory | Current Status | Create/Update index.md | Create inventory.md | Update MkDocs Navigation | Remove README.md | Remaining Actions |
|-----------|----------------|------------------------|---------------------|--------------------------|------------------|-------------------|
| ./approaches | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./architecture | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./configuration | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./configuration/advanced | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./contributing | ❌ | ❌ | ❌ | ❌ | N/A | Create index.md and inventory.md, Update navigation |
| ./contributing/testing | ❌ | ❌ | ❌ | ❌ | N/A | Create index.md and inventory.md, Update navigation |
| ./developer-guide | ❌ | ❌ | ❌ | ❌ | N/A | Create index.md and inventory.md, Update navigation |
| ./developer-guide/deployment | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./developer-guide/testing | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./examples | ❌ | ❌ | ❌ | ❌ | N/A | Create index.md and inventory.md, Update navigation |
| ./github-workflow-examples | ⚠️ | ✅ | ❌ | ✅ | N/A | Create inventory.md |
| ./gitlab-pipeline-examples | ⚠️ | ✅ | ❌ | ✅ | N/A | Create inventory.md |
| ./gitlab-services-examples | ❌ | ❌ | ❌ | ❌ | N/A | Create index.md and inventory.md, Update navigation |
| ./helm-charts | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./helm-charts/scanner-infrastructure | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./integration | ❌ | ❌ | ❌ | ❌ | N/A | Create index.md and inventory.md, Update navigation |
| ./kubernetes-setup | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./overview | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./project | ❌ | ❌ | ❌ | ❌ | N/A | Create index.md and inventory.md, Update navigation |
| ./project/archive | ❌ | ❌ | ❌ | ❌ | N/A | Create index.md and inventory.md, Update navigation |
| ./rbac | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./security | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./service-accounts | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./tokens | ✅ | ✅ | ✅ | ✅ | ✅ | None |
| ./utilities | ⚠️ | ❌ | ❌ | ❌ | ❌ | Convert README.md to index.md, Create inventory.md, Update navigation, Remove README.md |

## Legend

- ✅ Complete
- ⚠️ Partially Complete
- ❌ Not Started
- N/A Not Applicable (no README.md exists)

## Implementation Plan

1. **Directory Analysis (Complete)**
   - Identify all directories requiring structure updates
   - Document the current state of each directory

2. **File Creation (In Progress)**
   - Create index.md files for each directory
   - Create inventory.md files for each directory
   - Ensure proper metadata and cross-linking

3. **MkDocs Navigation Updates (In Progress)**
   - Update mkdocs.yml to reference new index.md files
   - Include inventory.md files in appropriate navigation sections
   - Test navigation to ensure proper structure

4. **README.md Removal (In Progress)**
   - Remove redundant README.md files after confirming content migration
   - Maintain file history through git

5. **Cross-Reference Updates (In Progress)**
   - Update all internal links to point to new file structure
   - Fix relative paths in documentation

6. **Testing and Validation (Pending)**
   - Verify all pages are accessible in MkDocs
   - Ensure proper rendering of all content
   - Check for broken links or navigation issues

## Next Steps

- Complete the remaining index.md and inventory.md files
- Update the MkDocs navigation to include all new files
- Remove redundant README.md files after confirming content migration
- Update cross-references throughout the documentation

## References

- [Documentation Entry Point Refactoring Plan](documentation-entry-refactoring.md)
- [Documentation Review Plan](documentation-review-plan.md)