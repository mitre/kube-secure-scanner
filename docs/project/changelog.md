# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure and core functionality
- Three container scanning approaches:
  - Kubernetes API Approach (train-k8s-container plugin)
  - Debug Container Approach (ephemeral containers)
  - Sidecar Container Approach (shared process namespace)
- Helm charts for all scanning approaches
- CI/CD pipeline examples for GitHub Actions and GitLab
- Comprehensive documentation with approach comparisons and decision matrices

### Changed
- 2025-03-19: Documentation consistency enhancement
  - Added consistent strategic priority statements about Kubernetes API Approach in key files
  - Standardized terminology from "InSpec" to "CINC Auditor" across all documents
  - Fixed broken relative links to use absolute paths (e.g., `/docs/overview/workflows.md`)
  - Updated path references to reflect current directory structure
  - Added clear labeling of interim approaches vs enterprise-recommended solutions
  - Standardized approach naming (Kubernetes API Approach, Debug Container Approach, Sidecar Container Approach)
  - Added explicit strategic priority statements for train-k8s-container plugin enhancement 
  - Updated integration documentation to consistently recommend Kubernetes API Approach
  - Fixed cross-references between GitHub Actions and GitLab CI documentation
  - Corrected examples' directory paths and workflow references
  - Updated TASKS.md to highlight highest priority implementation items
  - Added consistent "Strategic Priority" banners to key technical documents
  - Enhanced integration guides with consistent approach recommendations
  - Fixed repository name references in quickstart documentation
  - Updated index files for GitHub and GitLab examples with consistent messaging
  - Added strategic implementation path to plugin-modifications.md

### Fixed
- Broken links in documentation
- Directory structure inconsistencies
- MkDocs build warnings with proper exclude_docs configuration

### Security
- Enhanced documentation of security compliance considerations
- Clarified risk documentation requirements for alternative approaches