# Kube CINC Secure Scanner Development Guide

## Commands
### Documentation Commands (Preferred Method)
- Use the comprehensive docs-tools.sh script:
  - Build docs: `./docs-tools.sh build`
  - Preview docs: `./docs-tools.sh preview` (add `--log` flag to enable logging)
  - Preview with custom log: `./docs-tools.sh preview --log path/to/logfile.log`
  - Check server status: `./docs-tools.sh status`
  - Stop server: `./docs-tools.sh stop`
  - Restart server: `./docs-tools.sh restart` (add `--log` flag to enable logging)
  - Restart with custom log: `./docs-tools.sh restart --log path/to/logfile.log`
  - View default server logs (last 25 lines): `./docs-tools.sh logs`
  - View custom log file (last 25 lines): `./docs-tools.sh logs path/to/logfile.log`
  - View entire log file: `./docs-tools.sh logs --all`
  - View specific number of lines: `./docs-tools.sh logs --lines=200` or `./docs-tools.sh logs -n 50`
  - Lint markdown: `./docs-tools.sh lint`
  - Fix markdown issues: `./docs-tools.sh fix`
  - Spell check: `./docs-tools.sh spell`
  - Check links: `./docs-tools.sh links`
  - Run all checks: `./docs-tools.sh check-all`
  - Serve production build: `./docs-tools.sh serve-prod` (add `--log` flag to enable logging)
  - Install dependencies: `./docs-tools.sh setup`
  - Show help: `./docs-tools.sh help`

### Alternative Documentation Commands
- Build docs: `cd docs && npm run build` or `mkdocs build`
- Preview docs: `cd docs && npm run preview` or `mkdocs serve`
- Lint markdown: `cd docs && npm run lint`
- Fix markdown issues: `cd docs && npm run fix`
- Spell check: `cd docs && npm run spell`
- Check links: `cd docs && npm run links`

### Testing Environment
- Setup testing environment: `./scripts/setup-minikube.sh [--with-distroless]`

## Testing
- Run standard scan: `./scripts/scan-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]`
- Run distroless scan: `./scripts/scan-distroless-container.sh <namespace> <pod-name> <container-name> <profile-path> [threshold_file]`
- Run sidecar scan: `./scripts/scan-with-sidecar.sh <namespace> <pod-name> <profile-path> [threshold_file]`

## Approaches
This project implements three container scanning approaches:
1. Kubernetes API (standard containers) - Using train-k8s-container transport
2. Debug container (distroless) - Using ephemeral debug containers with chroot
3. Sidecar container - Using shared process namespace for both container types

## Code Style Guidelines
- Ruby: Follow InSpec style (2-space indentation, descriptive control IDs)
- Bash: Use shellcheck compliant scripts with descriptive comments and error handling
- Markdown: Use consistent headers (ATX style) and list formatting
- YAML: Use 2-space indentation and follow Kubernetes schema conventions
- RBAC: Implement least privilege principle with role-based access control
- Helm: Structure charts in modular fashion with proper dependencies
- CI/CD: Provide practical examples for both GitHub Actions and GitLab CI

## Project Structure
- `/docs` - Documentation with MkDocs configuration
- `/scripts` - Helper scripts for scanning and setup
- `/kubernetes` - Kubernetes manifests and templates
- `/helm-charts` - Modular Helm charts for deployment
- `/examples` - Example resources and CINC profiles
- `/github-workflow-examples` - GitHub Actions workflow examples
- `/gitlab-pipeline-examples` - GitLab CI pipeline examples

## Git Commits
- Always sign commits using: `git commit -s`
- Sign-off should be with: "Aaron Lippold <lippold@gmail.com>"

## Context Management
- Always exclude node_modules from searches, file listings, and context to avoid token waste
- Use flags like `--exclude=node_modules` or patterns like `find . -type d -not -path "*/node_modules/*"`