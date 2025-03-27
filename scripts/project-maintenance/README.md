# Project Maintenance Scripts

This directory contains scripts for cleaning up and maintaining the Kube CINC Secure Scanner project.

## Available Scripts

- **cleanup-project.sh**: Comprehensive project cleanup script
- **cleanup-script.sh**: Script for cleaning up specific types of files

## Script Details

### cleanup-project.sh

```
Usage: ./cleanup-project.sh [--dry-run] [--verbose] [--remove]
```

A comprehensive project cleanup script that identifies and handles:
- Backup files (*.bak, *.backup, *.old, *.tmp, etc.)
- Test files created for validation
- Warning tracking files
- "-new" files created for comparison
- Unused documentation files

Options:
- `--dry-run`: Preview changes without making them
- `--verbose`: Show detailed output
- `--remove`: Actually remove files (without this, it runs in dry-run mode)

### cleanup-script.sh

```
Usage: ./cleanup-script.sh [--dry-run] [--verbose] [--remove]
```

A script for cleaning up specific types of files, similar to cleanup-project.sh but with a focus on specific file patterns.

Options:
- `--dry-run`: Preview changes without making them
- `--verbose`: Show detailed output
- `--remove`: Actually remove files (without this, it runs in dry-run mode)