# Material for MkDocs Features Guide

This document provides a comprehensive guide to Material for MkDocs features that can enhance our documentation during the restructuring process. It focuses on features that will improve visual presentation, organization, and user experience.

## Navigation and Structure Features

### Primary Navigation

- **Navigation Tabs**: Top-level navigation using tabs for main sections
- **Navigation Sections**: Collapsible sections for sub-navigation
- **Expandable Navigation**: Allow expanding all navigation items
- **Instant Loading**: Fast page transitions without full page reload
- **Navigation Breadcrumbs**: Clear path indication for current location
- **Sticky Navigation**: Persistent navigation as user scrolls
- **Section Indexes**: Automatically generated index pages for sections

### Table of Contents

- **Auto-generated TOC**: Based on page headings
- **Configurable Depth**: Control how many heading levels to include
- **Custom Title**: Change the default "Table of contents" title
- **Sticky TOC**: Keep TOC visible while scrolling
- **Back-to-top Button**: Quick navigation to page top

## Visual Content Elements

### Icons and Emojis

- **Material Design Icons**: [10,000+ icons available](https://squidfunk.github.io/mkdocs-material/reference/icons-emojis/)
- **Custom Icons**: Add project-specific icons
- **Icon Colors**: Apply colors to icons (use for security level indicators)
- **Icon Animations**: Animate icons for interactive elements
- **Emoji Support**: Use in text and headings for visual cues

### Images and Diagrams

- **Image Lazy Loading**: Improve page load performance
- **Light/Dark Mode Images**: Different images based on theme
- **Image Captions**: Add descriptive text below images
- **Image Alignment**: Left, center, right alignment options
- **Lightbox Integration**: Click to enlarge images
- **Responsive Images**: Adapt to different screen sizes

### Lists and Organization

- **Unordered Lists**: Bullet points for general items
- **Ordered Lists**: Numbered steps for procedures
- **Definition Lists**: Term-definition pairs for glossaries
- **Task Lists**: Checkboxes for procedures and requirements
- **Custom List Markers**: Change the appearance of list bullets
- **Collapsible Lists**: Show/hide details when needed

## Interactive Elements

### Admonitions (Call-outs)

- **Standard Types**: Note, Tip, Warning, Danger, Info, etc.
- **Custom Admonitions**: Create project-specific admonition types
- **Collapsible Admonitions**: Toggle visibility of detailed content
- **Nested Admonitions**: Place admonitions inside other admonitions
- **Icon Customization**: Change icons for different admonition types

Example:

```markdown
!!! security "Security Consideration"
    This configuration requires additional security controls.
```

### Content Tabs

- **Content Comparison**: Compare different approaches
- **Environment-specific Content**: Show content for different environments
- **Code Examples**: Show examples in different languages
- **Role-based Content**: Show content appropriate for different user roles
- **Linked Content Tabs**: Link tabs across multiple blocks

Example:

```markdown
=== "Kubernetes API Approach"
    Configure the Kubernetes API scanner...

=== "Debug Container Approach"
    Configure the Debug Container scanner...

=== "Sidecar Container Approach"
    Configure the Sidecar Container scanner...
```

### Buttons

- **Call-to-action Buttons**: Highlight important links
- **Primary/Secondary Styles**: Visual hierarchy for actions
- **Icon Buttons**: Buttons with icons for visual emphasis
- **Button Sizing**: Control button sizes
- **Custom Colors**: Match buttons to documentation theme

Example:

```markdown
[Start Scanning](#){ .md-button .md-button--primary }
[Learn More](#){ .md-button }
```

### Code Blocks

- **Syntax Highlighting**: Language-specific highlighting
- **Line Numbers**: Show line numbers for reference
- **Code Annotations**: Add explanatory comments to specific lines
- **Code Highlighting**: Highlight specific lines or sections
- **Copy Button**: One-click copy of code examples
- **Code Links**: Link to source code repositories

Example with annotations:

````markdown
```yaml
apiVersion: v1 # (1)
kind: Pod
metadata:
  name: security-scanner # (2)
```

1. Kubernetes API version
2. Name of the scanner pod
````

## Layout and Organization

### Grids

- **Card Grids**: Visual grids of content cards
- **Feature Comparison**: Compare approaches or features
- **Responsive Layouts**: Adapt to different screen sizes
- **Custom Spacing**: Control grid spacing and alignment

Example:

```markdown
<div class="grid cards" markdown>

- :material-kubernetes: **Kubernetes API Approach**
    
    Standard container scanning using train-k8s-container transport.

- :material-docker: **Debug Container Approach**
    
    Distroless container scanning using ephemeral debug containers.

- :material-server: **Sidecar Container Approach**
    
    Shared process namespace for both container types.

</div>
```

### Data Tables

- **Column Alignment**: Left, center, right alignment
- **Sortable Tables**: Allow sorting table data
- **Responsive Tables**: Adapt to different screen sizes
- **Custom Styling**: Apply special styles to tables

Example:

```markdown
| Approach | Container Types | Security Level |
|:---------|:---------------:|---------------:|
| Kubernetes API | Standard | Low |
| Debug Container | Distroless | Medium |
| Sidecar | Both | High |
```

### Social Cards

- **Automatic Generation**: Create preview cards for social media sharing
- **Custom Designs**: Brand-specific card templates
- **Per-page Cards**: Different cards for different sections

## Search and Discovery

### Search Features

- **Full-text Search**: Search across all documentation
- **Search Highlighting**: Highlight search terms in results
- **Search Suggestions**: Show suggestions as user types
- **Search Exclusion**: Exclude certain content from search
- **Result Ranking**: Prioritize important content in results

### Tooltips and Glossary

- **Inline Tooltips**: Hover explanations for technical terms
- **Abbreviation Support**: Auto-explain abbreviations across the site
- **Glossary Integration**: Central glossary with site-wide tooltips
- **Custom Tooltip Styling**: Control appearance of tooltips
- **Term Highlighting**: Visual indication of terms with definitions

Example:

```markdown
[RBAC](../security/principles/least-privilege.md "Role-Based Access Control: A security approach that restricts system access to authorized users")

*[RBAC]: Role-Based Access Control
```

## Projects Plugin (Insiders Edition)

The [Projects plugin](https://squidfunk.github.io/mkdocs-material/plugins/projects/) is an Insiders-only feature that offers powerful capabilities for larger documentation sites:

- **Split documentation** into multiple projects while maintaining a unified experience
- **Build concurrently** for faster generation times
- **Preview individual projects** during development
- **Selective rebuilding** when files change

This plugin would be particularly valuable for our documentation as we could:

1. Create separate project sections for different user roles (developers, security teams, operators)
2. Build specialized documentation sections independently
3. Maintain a unified navigation and search experience
4. Improve build performance for large documentation sets

Note that this plugin is only available to sponsors of the Material for MkDocs project.

## Implementation Strategy

When implementing the restructuring, we should follow these principles:

1. **Progressive Enhancement**: Start with basic content and enhance with interactive elements
2. **Consistent Patterns**: Use the same patterns for similar content across the documentation
3. **Purposeful Use**: Only use visual enhancements when they improve understanding
4. **Performance Awareness**: Consider page load time impact of features
5. **Accessibility**: Ensure all enhancements work with screen readers and keyboard navigation

## Feature Integration Plan

### Phase 1: Basic Enhancement

- Add admonitions for security warnings and notes
- Implement content tabs for approach comparisons
- Add icons to main navigation sections

### Phase 2: Visual Improvements

- Create card grids for landing pages
- Implement code annotations for script examples
- Add task lists for compliance requirements

### Phase 3: Interactive Elements

- Add buttons for key user paths
- Implement collapsible sections for detailed content
- Create custom admonitions for security levels

### Phase 4: Advanced Features

- Add social cards for key documentation sections
- Implement diagrams for workflows and architectures
- Create custom stylesheets for security-specific highlighting
- Add tooltips for technical terms and abbreviations

## Reference Documentation

- [Material for MkDocs Documentation](https://squidfunk.github.io/mkdocs-material/)
- [Material for MkDocs Reference](https://squidfunk.github.io/mkdocs-material/reference/)
- [Material for MkDocs Setup](https://squidfunk.github.io/mkdocs-material/setup/)
- [Material for MkDocs Plugins](https://squidfunk.github.io/mkdocs-material/plugins/)
