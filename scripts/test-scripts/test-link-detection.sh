#!/bin/bash
# Enhanced test-link-detection.sh - Script to test link pattern detection

set -e

# Default to architecture/index.md if no file specified
TARGET_FILE="${1:-/Users/alippold/github/mitre/kube-cinc-secure-scanner/docs/architecture/index.md}"

# Also create a test file with known patterns for verification
TEST_FILE="/tmp/test-links.md"

cat > "$TEST_FILE" << 'EOL'
# Test Link Detection

This file contains various link patterns to test detection:

## Standard Links
- [Standard Link](file.md)
- [Link with Path](dir/file.md)
- [Link with Anchor](file.md#section)
- [Nested Path](dir/subdir/file.md)

## Index Links (Already Correct Format)
- [Index Link](dir/index.md)
- [Nested Index](dir/subdir/index.md)
- [Index with Anchor](dir/index.md#section)

## Directory-Style Links (Need Fixing)
- [Directory Link](dir/)
- [Nested Directory](dir/subdir/)

## Mixed Links
- [Relative Path Link](../file.md)
- [Relative Directory](../dir/)
- [External Link](https://example.com)
- [Fragment Link](#section)
EOL

echo "Created test file with various link patterns at $TEST_FILE"
echo ""

# Function to analyze links in a file
analyze_file() {
    local file="$1"
    
    echo "Testing link detection on: $file"
    echo "================================"
    
    if [ ! -f "$file" ]; then
        echo "ERROR: File not found: $file"
        return 1
    fi
    
    file_content=$(cat "$file")
    
    # Extract all markdown links - pattern: [text](url)
    all_links=$(echo "$file_content" | grep -o -E '\[[^]]+\]\([^)]+\)' || echo "")
    link_count=$(echo "$all_links" | grep -c -E '\[[^]]+\]\(' || echo 0)
    [[ "$link_count" =~ ^[0-9]+$ ]] || link_count=0
    
    echo "All detected links ($link_count total):"
    if [ "$link_count" -gt 0 ]; then
        echo "$all_links" | sed 's/^/  - /'
    else
        echo "  No links found"
    fi
    echo ""
    
    # 1. Find links with /index.md (already correct directory references)
    index_links_lines=$(echo "$all_links" | grep "/index.md" 2>/dev/null || echo "")
    index_links=$(echo "$index_links_lines" | grep -c "/index.md" 2>/dev/null || echo 0)
    [[ "$index_links" =~ ^[0-9]+$ ]] || index_links=0
    
    echo "Links with /index.md: $index_links"
    if [ "$index_links" -gt 0 ]; then
        echo "$index_links_lines" | sed 's/^/  - /'
    else
        echo "  None found"
    fi
    echo ""
    
    # 2. Find links to specific .md files (not index.md)
    md_links=$(echo "$all_links" | grep ".md" 2>/dev/null || echo "")
    specific_links_lines=$(echo "$md_links" | grep -v "/index.md" 2>/dev/null || echo "")
    specific_links=$(echo "$specific_links_lines" | grep -c ".md" 2>/dev/null || echo 0)
    [[ "$specific_links" =~ ^[0-9]+$ ]] || specific_links=0
    
    echo "Links to specific .md files: $specific_links"
    if [ "$specific_links" -gt 0 ]; then
        echo "$specific_links_lines" | sed 's/^/  - /'
    else
        echo "  None found"
    fi
    echo ""
    
    # 3. Find directory-style links (with trailing slash)
    dir_links_lines=$(echo "$all_links" | grep -E '\([^)]+/\)' 2>/dev/null || echo "")
    dir_links=$(echo "$dir_links_lines" | grep -c "/" 2>/dev/null || echo 0)
    [[ "$dir_links" =~ ^[0-9]+$ ]] || dir_links=0
    
    echo "Directory-style links (with trailing slash): $dir_links"
    if [ "$dir_links" -gt 0 ]; then
        echo "$dir_links_lines" | sed 's/^/  - /'
    else
        echo "  None found"
    fi
    echo ""
    
    # 4. Find other types of links (external, fragment, etc.)
    external_links=$(echo "$all_links" | grep -c "http" 2>/dev/null || echo 0)
    fragment_links=$(echo "$all_links" | grep -c ")(#" 2>/dev/null || echo 0)
    standalone_fragment_links=$(echo "$all_links" | grep -c '(#[^)]*)'  2>/dev/null || echo 0)
    [[ "$external_links" =~ ^[0-9]+$ ]] || external_links=0
    [[ "$fragment_links" =~ ^[0-9]+$ ]] || fragment_links=0
    [[ "$standalone_fragment_links" =~ ^[0-9]+$ ]] || standalone_fragment_links=0
    
    echo "Other link types:"
    echo "  - External links (http): $external_links"
    echo "  - Fragment links in paths (#): $fragment_links"
    echo "  - Standalone fragment links (#): $standalone_fragment_links"
    echo ""
    
    # 5. Summary of correctly formatted links
    total_correct=$((index_links + specific_links))
    echo "SUMMARY:"
    echo "-----------------------------------------"
    echo "Total links: $link_count"
    echo "Correctly formatted links: $total_correct"
    echo "  - index.md references: $index_links"
    echo "  - Specific .md files: $specific_links"
    echo "Directory-style links (need fixing): $dir_links"
    echo "Other links: $((link_count - total_correct - dir_links))"
    
    # Metrics validation
    # Calculate other links: external + fragment links + standalone fragments
    other_links=$((external_links + fragment_links + standalone_fragment_links))
    # Calculate expected total
    expected_total=$((total_correct + dir_links + other_links))
    
    echo ""
    echo "METRICS VALIDATION:"
    echo "-----------------------------------------"
    if [ "$expected_total" -eq "$link_count" ]; then
        echo "✅ PASSED: All $link_count links are correctly classified"
        echo "  - Correctly formatted (.md): $total_correct"
        echo "  - Directory-style links (/): $dir_links"
        echo "  - Other links (external, etc.): $other_links"
    else
        echo "❌ FAILED: Link classification doesn't match total count"
        echo "  - Total links found: $link_count"
        echo "  - Links classified: $expected_total"
        echo "  - Discrepancy: $((link_count - expected_total)) unclassified links"
    fi
    echo ""
    
    # Verification of problematic patterns
    echo "PATTERN DETECTION VERIFICATION:"
    echo "-----------------------------------------"
    echo "Detection using regex patterns:"
    
    # Use advanced regex to test pattern detection for all types
    index_regex_match=$(echo "$file_content" | grep -o -E '\[[^]]+\]\([^)]+/index\.md[^)]*\)' | wc -l | tr -d '[:space:]')
    specific_regex_match=$(echo "$file_content" | grep -o -E '\[[^]]+\]\([^)]+\.md[^)]*\)' | grep -v "/index.md" | wc -l | tr -d '[:space:]')
    dir_regex_match=$(echo "$file_content" | grep -o -E '\[[^]]+\]\([^)]+/\)' | wc -l | tr -d '[:space:]')
    
    [[ "$index_regex_match" =~ ^[0-9]+$ ]] || index_regex_match=0
    [[ "$specific_regex_match" =~ ^[0-9]+$ ]] || specific_regex_match=0
    [[ "$dir_regex_match" =~ ^[0-9]+$ ]] || dir_regex_match=0
    
    echo "  - index.md links (regex): $index_regex_match (vs counted: $index_links)"
    echo "  - Specific .md files (regex): $specific_regex_match (vs counted: $specific_links)"
    echo "  - Directory-style links (regex): $dir_regex_match (vs counted: $dir_links)"
    echo ""
    
    # Test the problematic pattern from the script
    # This is key: Testing if the main code issue is in the counting or detection
    echo "TESTING PROBLEMATIC REGEX PATTERNS FROM MAIN SCRIPT:"
    echo "-----------------------------------------"
    
    # Debug for index.md links (already correct)
    index_script_pattern="/index.md)"
    index_script_match=$(echo "$all_links" | grep -c "$index_script_pattern" 2>/dev/null || echo 0)
    [[ "$index_script_match" =~ ^[0-9]+$ ]] || index_script_match=0
    
    echo "Using basic pattern '$index_script_pattern': $index_script_match matches"
    if [ "$index_script_match" -gt 0 ]; then
        echo "Sample matches:"
        echo "$all_links" | grep "$index_script_pattern" | head -3 | sed 's/^/  - /'
    fi
    echo ""
    
    # Test with proper quoting/escaping
    index_esc_pattern='\]/index\.md'
    index_esc_match=$(echo "$all_links" | grep -c "$index_esc_pattern" 2>/dev/null || echo 0)
    [[ "$index_esc_match" =~ ^[0-9]+$ ]] || index_esc_match=0
    
    echo "Using escaped pattern '$index_esc_pattern': $index_esc_match matches"
    if [ "$index_esc_match" -gt 0 ]; then
        echo "Sample matches:"
        echo "$all_links" | grep "$index_esc_pattern" | head -3 | sed 's/^/  - /'
    fi
    echo ""
}

# Analyze both the real file and our test file
echo "===== ANALYZING REAL DOCUMENTATION FILE ====="
analyze_file "$TARGET_FILE"

echo ""
echo "===== ANALYZING TEST FILE WITH KNOWN PATTERNS ====="
analyze_file "$TEST_FILE"

echo "Test completed."
