# Documentation Tools

This directory contains scripts for maintaining and improving the documentation in the Kube CINC Secure Scanner project.

## Available Scripts

- **extract-doc-warnings.sh**: Extract and categorize documentation warnings from MkDocs build
- **fix-cross-references.sh**: Fix cross-references in documentation files
- **fix-links.sh**: Fix broken links in documentation
- **fix-links-lychee.sh**: Fix broken links using Lychee link checker
- **fix-links-simple.sh**: Simple script for fixing links based on mappings file
- **fix-relative-links.sh**: Fix relative links in documentation
- **fix-warning-file.sh**: Fix and verify individual files with warnings
- **generate-doc-mappings.sh**: Generate mappings between old and new documentation paths
- **track-warning-progress.sh**: Track progress in fixing documentation warnings
- **update-mkdocs-nav.sh**: Update the navigation structure in mkdocs.yml

## Script Details

### extract-doc-warnings.sh

```
Usage: ./extract-doc-warnings.sh [--info]
```

Extracts warnings from MkDocs build output and categorizes them by type. The `--info` flag includes INFO messages.

### fix-links-simple.sh

```
Usage: ./fix-links-simple.sh [--dry-run] [--verify-files] --path <docs-path> --mappings <mappings-file>
```

A simple script for fixing links based on a mappings file. The `--dry-run` flag shows changes without applying them, and `--verify-files` validates that target files exist.

### track-warning-progress.sh

```
Usage: ./track-warning-progress.sh
```

Tracks progress in fixing documentation warnings, showing metrics like the number of warnings fixed and percentage complete.

### generate-doc-mappings.sh

```
Usage: ./generate-doc-mappings.sh
```

Generates a comprehensive mapping file that maps old documentation paths to new ones, which can be used with fix-links-simple.sh.

### update-mkdocs-nav.sh

```
Usage: ./update-mkdocs-nav.sh [--dry-run]
```

Updates the navigation structure in mkdocs.yml based on the filesystem structure.