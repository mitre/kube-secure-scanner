# Documentation

This directory contains the comprehensive documentation for the Secure CINC Auditor Kubernetes Container Scanning project.

## Documentation Structure

The documentation is organized into the following sections:

- **overview/** - High-level project information, executive summaries, and approach comparisons
- **configuration/** - Kubeconfig generation and scanner configuration
- **rbac/** - RBAC configuration for secure scanning access
- **service-accounts/** - Service account setup and management
- **tokens/** - Token generation and security
- **integration/** - CI/CD integration guides
- **github-workflow-examples/** - Example GitHub Actions workflows
- **gitlab-pipeline-examples/** - Example GitLab CI pipelines
- **deployment/** - Deployment scenarios and considerations
- **testing/** - Testing strategies and validation
- **helm-charts/** - Helm chart documentation

## Documentation System

This project uses [MkDocs](https://www.mkdocs.org/) with the [Material theme](https://squidfunk.github.io/mkdocs-material/) for documentation. The configuration is defined in `mkdocs.yml` at the root of the repository.

### Documentation Tools

We provide a unified documentation tooling script `docs-tools.sh` that serves as the **required entry point** for all documentation tasks. This ensures consistent tooling, validation, and formatting across all contributors.

```bash
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
┃ Secure CINC Auditor Kubernetes Container Scanning          ┃
┃ Documentation Tools                                        ┃
┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

Usage: ./docs-tools.sh [command]

Documentation Preview:
  preview      - Start MkDocs server for local preview
  status       - Check status of running preview server
  stop         - Stop running preview server
  restart      - Restart preview server
  serve-prod   - Serve the production build locally

Documentation Quality:
  lint         - Check Markdown files for style issues
  fix          - Automatically fix linting issues where possible
  spell        - Check spelling in documentation files
  links        - Check for broken links (requires build first)
  check-all    - Run all validation checks (lint, spell, links)

Build and Setup:
  build        - Build static documentation site
  setup        - Install/update all dependencies
  help         - Show this help message
```

#### Common Documentation Workflows

When working on documentation, follow these standard patterns:

1. **Starting a documentation session**:
   ```bash
   # Install/update dependencies and start the preview server
   ./docs-tools.sh setup
   ./docs-tools.sh preview
   ```

2. **Validating your changes**:
   ```bash
   # Run all checks before committing
   ./docs-tools.sh check-all
   ```

3. **Fixing common issues**:
   ```bash
   # Fix automatically fixable linting issues
   ./docs-tools.sh fix
   
   # Run spell check and add words to dictionary as needed
   ./docs-tools.sh spell
   ```

4. **Finishing your session**:
   ```bash
   # Stop the preview server when done
   ./docs-tools.sh stop
   ```

#### Important Documentation Policies

1. **Always run validation before submitting changes**
2. **Use the built-in linting and spell check tools**
3. **Add new terminology to the spelling dictionary using the spell check tool**
4. **Run the preview server to visualize your changes before committing**

### Documentation Guidelines

When contributing to documentation:

1. **Consistent Terminology** - Use "CINC Auditor" (not InSpec) consistently
2. **Approach Names** - Use standardized approach names:
   - Kubernetes API Approach (recommended for enterprise)
   - Debug Container Approach (interim solution)
   - Sidecar Container Approach (interim solution)
3. **Strategic Priority** - Emphasize the Kubernetes API Approach as the enterprise-recommended solution and the train-k8s-container plugin enhancement as the highest strategic priority
4. **Absolute Links** - Use absolute paths for links (e.g., `/docs/overview/workflows.md`)
5. **File Organization** - Place example files in their respective directories

## Recent Documentation Enhancement

The documentation has recently undergone a comprehensive consistency update to ensure:

1. Strategic recommendations are clear and consistent
2. Terminology is standardized 
3. File paths and references are accurate
4. Cross-document references are working correctly
5. The enterprise-recommended approach (Kubernetes API Approach) is clearly identified across all materials

See the project [CHANGELOG.md](/CHANGELOG.md) for details on the documentation improvements.

## MKDOCS.yml Configuration

The mkdocs.yml configuration includes important settings:

- Section-specific README.md files are used for navigation
- The root README.md is excluded to avoid conflicts with index.md
- Various non-documentation files are excluded from processing
- Custom theme overrides in `docs/theme_overrides/` for dynamic copyright year
- Dark mode/light mode toggle with automatic system preference detection