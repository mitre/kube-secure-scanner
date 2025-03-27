# Contributing to Documentation

This section provides guidelines and tools for contributing to the Kube CINC Secure Scanner documentation.

## Overview

Our documentation is built with [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/), which provides a modern and responsive documentation experience with features like:

- Advanced code highlighting and annotations
- Content tabs for organizing related information
- Interactive diagrams with Mermaid integration
- Dark and light theme support
- Search functionality

## How to Contribute

To contribute to the documentation:

1. Set up your local development environment
2. Make your changes to the markdown files
3. Preview your changes locally
4. Submit a pull request

## Development Environment Setup

To set up your local development environment:

```bash
# Clone the repository
git clone https://github.com/mitre/kube-cinc-secure-scanner
cd kube-cinc-secure-scanner

# Install dependencies
cd docs
npm install
```

## Local Preview

To preview the documentation locally:

```bash
cd docs
npm run preview
```

This will start a local server at <http://localhost:8000/> where you can preview your changes in real-time.

## Documentation Tools

We provide several useful tools for documentation development:

- **Diagram Support**: Create diagrams using Mermaid syntax
- **Code Snippets**: Include code examples from actual project files
- **Styling Guidelines**: Maintain consistent styling across documents
- **Linting and Formatting**: Ensure markdown quality and consistency

For more details, see the individual topics in this section.

## Documentation Standards

When contributing to documentation, please follow these guidelines:

- Use clear, concise language
- Follow the established directory structure
- Maintain consistent markdown formatting
- Include examples where appropriate
- Test all links and references
- Include diagrams for complex concepts

## Related Resources

- [Material for MkDocs Documentation](https://squidfunk.github.io/mkdocs-material/)
- [Markdown Guide](https://www.markdownguide.org/)
- [Mermaid Diagram Syntax](https://mermaid-js.github.io/mermaid/#/)
