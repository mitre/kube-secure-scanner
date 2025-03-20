// Code for displaying example files inline
document.addEventListener('DOMContentLoaded', function() {
  // Find all links to example files (.yml, .yaml, .json, .sh, etc.)
  const exampleFileLinks = document.querySelectorAll('a[href$=".yml"], a[href$=".yaml"], a[href$=".json"], a[href$=".sh"], a[href$=".rb"]');
  
  exampleFileLinks.forEach(link => {
    // Skip links that are external (contain ://)
    if (link.href.includes('://') && !link.href.includes(window.location.hostname)) {
      return;
    }
    
    // Create container elements
    const container = document.createElement('div');
    container.className = 'example-file-container';
    
    const header = document.createElement('div');
    header.className = 'example-file-header';
    
    const fileName = link.href.split('/').pop();
    const fileType = fileName.split('.').pop();
    
    // Determine language class for syntax highlighting
    let language = fileType;
    if (fileType === 'yml' || fileType === 'yaml') {
      language = 'yaml';
    } else if (fileType === 'sh') {
      language = 'bash';
    } else if (fileType === 'rb') {
      language = 'ruby';
    }
    
    // Create the header with file name and buttons
    header.innerHTML = `
      <span class="example-file-name">${fileName}</span>
      <div class="example-file-actions">
        <button class="example-file-copy" data-file="${fileName}" title="Copy to clipboard">
          <span class="copy-icon">📋</span> Copy
        </button>
        <a href="${link.href}" download="${fileName}" class="example-file-download" title="Download file">
          <span class="download-icon">⬇️</span> Download
        </a>
      </div>
    `;
    
    // Create code display area
    const codeContainer = document.createElement('div');
    codeContainer.className = 'example-file-code';
    codeContainer.innerHTML = `<pre><code class="language-${language}" id="code-${fileName.replace(/\./g, '-')}">Loading...</code></pre>`;
    
    // Add elements to container
    container.appendChild(header);
    container.appendChild(codeContainer);
    
    // Insert container after the link
    link.parentNode.insertBefore(container, link.nextSibling);
    
    // Store the original text and href
    const originalText = link.textContent;
    const originalHref = link.href;
    
    // Fetch the file content
    fetch(link.href)
      .then(response => response.text())
      .then(content => {
        // Update the code element with the content
        const codeElement = document.getElementById(`code-${fileName.replace(/\./g, '-')}`);
        codeElement.textContent = content;
        
        // Apply syntax highlighting if Prism is available
        if (window.Prism) {
          Prism.highlightElement(codeElement);
        }
        
        // Set up copy functionality
        const copyButton = container.querySelector('.example-file-copy');
        copyButton.addEventListener('click', function() {
          navigator.clipboard.writeText(content).then(() => {
            const originalText = copyButton.innerHTML;
            copyButton.innerHTML = '<span class="copy-icon">✅</span> Copied!';
            setTimeout(() => {
              copyButton.innerHTML = originalText;
            }, 2000);
          });
        });
      })
      .catch(error => {
        console.error('Error fetching file:', error);
        const codeElement = document.getElementById(`code-${fileName.replace(/\./g, '-')}`);
        codeElement.textContent = 'Error loading file content';
      });
  });
});