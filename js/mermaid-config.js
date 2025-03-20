// Mermaid configuration that supports dark mode with high contrast
document.addEventListener('DOMContentLoaded', function() {
  mermaid.initialize({
    startOnLoad: true,
    theme: 'base',
    themeVariables: {
      // Base settings for both light/dark modes - higher contrast colors
      primaryColor: '#0066CC', // Strong blue with good contrast in both modes
      primaryTextColor: '#FFFFFF', // White text for maximum contrast on primary
      primaryBorderColor: '#0056b3', // Slightly darker blue for borders
      lineColor: '#505050', // Darker line color for better visibility
      secondaryColor: '#4C366B', // Deep purple for secondary elements
      tertiaryColor: '#eeeeee', // Light gray background
      
      // Dynamically adapt to color scheme
      darkMode: window.matchMedia && 
                window.matchMedia('(prefers-color-scheme: dark)').matches,
      
      // Light mode specific colors - increased contrast
      nodeBorder: '#555555', 
      mainBkg: '#FFFFFF',
      
      // Conditional settings updated by theme toggle with WCAG considerations
      updateThemeVariables: function(theme) {
        if (theme === 'dark') {
          return {
            // Dark mode - high contrast colors (4.5:1 minimum contrast ratio)
            nodeBorder: '#999999', // Lighter border for dark mode
            mainBkg: '#2e303e', // Match slate background
            clusterBkg: '#252632', // Slightly darker than main background
            nodeBkg: '#363846', // Slightly lighter than main background for nodes
            textColor: '#FFFFFF', // Pure white text for max contrast
            lineColor: '#BBBBBB', // Much lighter lines for visibility
            
            // Node styling for better visibility
            nodeFontSize: '16px',
            nodeFontWeight: 'bold',
            
            // Higher contrast for flow diagram elements
            edgeLabelBackground: '#363846', // Match node background
            labelBackground: '#363846',
            labelColor: '#FFFFFF'
          };
        } else {
          return {
            // Light mode - high contrast colors
            nodeBorder: '#555555',
            mainBkg: '#FFFFFF',
            clusterBkg: '#F0F0F0',
            nodeBkg: '#F5F5F5',
            textColor: '#101010', // Almost black text
            lineColor: '#444444', // Darker lines for visibility
            
            // Node styling
            nodeFontSize: '16px',
            nodeFontWeight: 'normal',
            
            // Better contrast for flow diagram elements
            edgeLabelBackground: '#FFFFFF',
            labelBackground: '#FFFFFF',
            labelColor: '#101010'
          };
        }
      }
    },
    securityLevel: 'loose',
    flowchart: {
      htmlLabels: true,
      useMaxWidth: true,
      curve: 'basis'
    },
    sequence: {
      diagramMarginX: 50,
      diagramMarginY: 10,
      boxTextMargin: 5,
      noteMargin: 10,
      messageMargin: 35
    }
  });

  // Listen for theme changes
  const observer = new MutationObserver(function(mutations) {
    mutations.forEach(function(mutation) {
      if (mutation.attributeName === 'data-md-color-scheme') {
        const theme = document.documentElement.getAttribute('data-md-color-scheme');
        if (theme === 'slate') {
          mermaid.initialize({ 
            theme: 'dark',
            themeVariables: mermaid.mermaidAPI.getConfig().themeVariables.updateThemeVariables('dark')
          });
        } else {
          mermaid.initialize({ 
            theme: 'default',
            themeVariables: mermaid.mermaidAPI.getConfig().themeVariables.updateThemeVariables('light')  
          });
        }
        // Force redraw all diagrams
        document.querySelectorAll('.mermaid').forEach(function(el) {
          const graphCode = el.textContent || el.innerText;
          if (el.getAttribute('data-processed') === 'true') {
            el.removeAttribute('data-processed');
            // Use render method with callback for proper redraw
            try {
              mermaid.render('mermaid-svg-' + Math.random().toString(36).substr(2, 9), 
                        graphCode, 
                        function(svgCode) {
                          el.innerHTML = svgCode;
                        });
            } catch (error) {
              console.error('Error rendering mermaid diagram:', error);
              el.innerHTML = '<div class="mermaid-error">Error rendering diagram</div>';
            }
          }
        });
      }
    });
  });

  observer.observe(document.documentElement, {
    attributes: true,
    attributeFilter: ['data-md-color-scheme']
  });
});