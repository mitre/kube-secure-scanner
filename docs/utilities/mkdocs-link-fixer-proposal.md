# MkDocs Link Fixer - Enhancement Proposal

## Overview

The current `fix-links-simple.sh` script provides a foundation for a potentially valuable tool for the broader MkDocs community. This document outlines a proposal to enhance and extend this script into a full-featured solution for maintaining documentation cross-references during reorganizations.

## Problem Statement

Documentation reorganizations frequently lead to broken cross-references, especially in large projects. When files are moved, renamed, or restructured (particularly when transitioning from flat structures to nested ones), maintaining correct internal links becomes challenging. This is a common pain point across the MkDocs ecosystem.

## Current Solution

Our current `fix-links-simple.sh` script provides:

- Detection and fixing of standard Markdown links
- Support for directory-style links (with trailing slashes)
- Mapping-based approach for link transformations
- Detailed metrics and reporting
- Support for dry-run preview

## Enhancement Vision

### Core Functionality Improvements

1. **MkDocs Configuration Integration**
   - Parse `mkdocs.yml` to understand the navigation structure
   - Auto-generate mappings based on the navigation hierarchy
   - Support navigation structure changes between versions

2. **Dynamic Mapping Generation**
   - Detect common patterns (like `dir.md` → `dir/index.md`) automatically
   - Generate mappings by scanning directory structure
   - Option to auto-detect moved files using git history

3. **Extensible Path Strategies**
   - Support different link path strategies (relative vs. absolute)
   - Handle MkDocs' specific URL handling and path normalization
   - Support various permalink styles

4. **Enhanced Reporting**
   - Generate HTML reports with clickable links
   - Provide visualization of link changes
   - Integration with MkDocs build process (as a plugin)

5. **Cross-Repository Support**
   - Handle documentation spread across multiple repositories
   - Support for versioned documentation

6. **Interactive Mode**
   - Prompt for confirmation on complex changes
   - Suggest fixes for ambiguous cases

7. **Advanced Features**
   - Link validity checking against live site
   - Support for API documentation integration
   - Support for multiple documentation formats (Markdown, reStructuredText)

### Technical Implementation Options

1. **Standalone Tool**
   - Create a proper Python package installable via pip
   - Add proper command-line interface with argparse
   - Include comprehensive documentation

2. **MkDocs Plugin**
   - Create a plugin that runs during the build process
   - Add hooks for pre-build and post-build phases
   - Integrate with MkDocs' internal link processing

3. **CI/CD Integration**
   - Package as a GitHub Action for CI/CD workflows
   - Automate documentation maintenance in PRs

## Implementation Roadmap

### Phase 1: Foundation (1-2 months)

- Rewrite script in Python for better maintainability and cross-platform support
- Implement proper command-line interface
- Add unit tests for core functionality
- Create basic documentation

### Phase 2: Advanced Features (2-3 months)

- Add MkDocs configuration parsing
- Implement dynamic mapping generation
- Add interactive mode
- Enhance reporting with HTML output

### Phase 3: Integration (1-2 months)

- Develop MkDocs plugin version
- Create GitHub Action
- Add CI/CD integration examples

### Phase 4: Community Engagement (Ongoing)

- Submit to MkDocs community resources
- Share on documentation forums
- Create a dedicated repository with contribution guidelines
- Collect and implement community feedback

## Resource Requirements

- Development time: 4-7 months (part-time)
- Testing environments for various MkDocs configurations
- Documentation hosting

## Benefits

- Reduce maintenance burden for documentation reorganizations
- Improve documentation quality by maintaining correct cross-references
- Enhance MkDocs ecosystem with specialized tooling
- Potential to become a standard tool in documentation maintenance workflows

## Next Steps

1. Seek feedback on this proposal from the team
2. Evaluate resource availability for initial development
3. Create a prototype Python implementation
4. Test with our existing documentation to validate approach

## References

- Current `fix-links-simple.sh` script
- [MkDocs Documentation](https://www.mkdocs.org/)
- [MkDocs Plugins](https://github.com/mkdocs/mkdocs/wiki/MkDocs-Plugins)
- [Python-Markdown Extension Development](https://python-markdown.github.io/extensions/api/)
