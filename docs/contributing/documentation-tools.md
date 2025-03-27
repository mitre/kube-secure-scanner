# Documentation Tools

This project provides a comprehensive documentation toolchain to ensure consistent, high-quality documentation. We use MkDocs with the Material theme as our documentation system, along with various validation tools.

## The docs-tools.sh Script

Our `docs-tools.sh` script serves as the **unified entry point** for all documentation tasks, ensuring all contributors use consistent tooling and validation processes.

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

## Getting Started

To start working on documentation:

1. Clone the repository

   ```bash
   git clone https://github.com/mitre/kube-secure-scanner.git
   ```

2. Navigate to the project root directory

   ```bash
   cd kube-secure-scanner
   ```

3. Run initial setup to install dependencies:

```bash
./docs-tools.sh setup
```

4. Start the preview server:

```bash
./docs-tools.sh preview
```

The documentation will be available at [http://localhost:8000](http://localhost:8000).

## Documentation Workflow

When working on documentation, follow this recommended workflow:

### 1. Start Your Session

```bash
# Update dependencies and start preview server
./docs-tools.sh setup
./docs-tools.sh preview
```

### 2. Make Your Changes

Edit markdown files in the `docs/` directory. The preview server automatically refreshes to show your changes.

### 3. Validate Your Work

Before committing, always run the validation tools:

```bash
# Check for style, spelling, and link issues
./docs-tools.sh check-all
```

### 4. Address Any Issues

For linting issues:

```bash
# Automatically fix common style issues
./docs-tools.sh fix
```

For spelling issues:

```bash
# Run spell check and add valid terms to dictionary
./docs-tools.sh spell
```

### 5. Finish Your Session

```bash
# Stop the preview server when done
./docs-tools.sh stop
```

## Documentation Standards

When contributing to documentation, adhere to these standards:

1. **Consistent Terminology**:
   - Use "CINC Auditor" (not InSpec) consistently
   - Use standardized approach names:
     - Kubernetes API Approach (recommended for enterprise)
     - Debug Container Approach (interim solution)
     - Sidecar Container Approach (interim solution)

2. **Strategic Emphasis**:
   - Emphasize the Kubernetes API Approach as the enterprise-recommended solution
   - Clearly communicate that enhancing the train-k8s-container plugin is the highest strategic priority

3. **Links and References**:
   - Use relative paths for links (e.g., `../overview/workflows.md`)
   - Ensure all external links are valid

4. **Code Snippets and Examples**:
   - Use the Material for MkDocs snippet inclusion feature for code examples
   - Place reusable code snippets in the `includes/` directory
   - Reference existing example files rather than duplicating them

5. **Validation Requirements**:
   - All documentation must pass linting checks
   - All spelling must be correct (with project-specific terms added to the dictionary)
   - All links must be valid

## Troubleshooting

### Preview Server Issues

If the preview server is unresponsive:

```bash
# Check server status
./docs-tools.sh status

# Restart if necessary
./docs-tools.sh restart
```

### Dependency Issues

If you encounter dependency problems:

```bash
# Clean and reinstall dependencies
./docs-tools.sh setup --force
```

## CI/CD Integration

The documentation is automatically built and validated in CI/CD pipelines using the same tools provided by the `docs-tools.sh` script. Any pull request with documentation changes will be checked for:

- Markdown style compliance
- Spelling correctness
- Link validity
- Successful build

## Finding Help

If you need assistance with documentation:

1. Check the output of `./docs-tools.sh help`
2. Review the comments in the `mkdocs.yml` file
3. Consult the [MkDocs documentation](https://www.mkdocs.org/)
4. Review the [Material for MkDocs documentation](https://squidfunk.github.io/mkdocs-material/)
