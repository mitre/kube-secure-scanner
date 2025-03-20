# Using Code Snippets

This guide explains how to use the Material for MkDocs code snippet inclusion feature to embed code examples in your documentation.

## Overview

Our documentation uses [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) with the [PyMdown Extensions](https://facelessuser.github.io/pymdown-extensions/) to provide advanced code block functionality, including:

- Code syntax highlighting
- Line numbers and line highlighting
- Code block annotations
- Code copying button
- Code file inclusion

## Including Code Files

To include code from existing files in the repository:

```markdown
```yaml
--8<-- "github-workflow-examples/ci-cd-pipeline.yml"
```
```

This will render as:

```yaml
--8<-- "github-workflow-examples/ci-cd-pipeline.yml"
```

## Highlighting Specific Lines

You can highlight specific lines in the code:

```markdown
```yaml hl_lines="3-5 8"
--8<-- "github-workflow-examples/ci-cd-pipeline.yml"
```
```

## Adding Line Numbers

Line numbers are automatically added to code blocks, but you can disable them if needed:

```markdown
```yaml linenums="1"
--8<-- "github-workflow-examples/ci-cd-pipeline.yml"
```
```

## Adding Annotations

You can add annotations to specific lines in code blocks:

```markdown
```yaml
--8<-- "github-workflow-examples/ci-cd-pipeline.yml"
```

1. This line defines the workflow name
2. These are the events that trigger the workflow
```

## Using Tabs for Multiple Code Examples

You can group related code examples in tabs:

```markdown
=== "GitHub Workflow"
    ```yaml
    --8<-- "github-workflow-examples/ci-cd-pipeline.yml"
    ```

=== "GitLab CI"
    ```yaml
    --8<-- "gitlab-pipeline-examples/gitlab-ci.yml"
    ```
```

## Best Practices

1. **Use Existing Examples**: Reference existing example files rather than duplicating code
2. **Relative Paths**: Use relative paths from the docs directory
3. **Context**: Always provide explanatory text around code snippets
4. **Highlighting**: Use line highlighting to draw attention to important parts
5. **Annotations**: Add annotations to explain complex code sections

## Available Example Files

### GitHub Workflow Examples

- `github-workflow-examples/ci-cd-pipeline.yml`
- `github-workflow-examples/setup-and-scan.yml`
- `github-workflow-examples/dynamic-rbac-scanning.yml`
- `github-workflow-examples/existing-cluster-scanning.yml`
- `github-workflow-examples/sidecar-scanner.yml`

### GitLab CI Examples

- `gitlab-pipeline-examples/gitlab-ci.yml`
- `gitlab-pipeline-examples/dynamic-rbac-scanning.yml`
- `gitlab-pipeline-examples/existing-cluster-scanning.yml`
- `gitlab-pipeline-examples/gitlab-ci-with-services.yml`
- `gitlab-pipeline-examples/gitlab-ci-sidecar.yml`
- `gitlab-pipeline-examples/gitlab-ci-sidecar-with-services.yml`

## Further Reading

For more information, see:

- [PyMdown Extensions Documentation](https://facelessuser.github.io/pymdown-extensions/extensions/snippets/)
- [Material for MkDocs Code Blocks](https://squidfunk.github.io/mkdocs-material/reference/code-blocks/)