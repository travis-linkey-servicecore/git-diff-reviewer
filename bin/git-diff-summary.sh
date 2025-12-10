#!/usr/bin/env bash

# git-diff-summary - Generate a summary report from review comments in source files
# Usage: git-diff-summary <worktree-path>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if worktree path is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No worktree path provided${NC}"
    echo "Usage: git-diff-summary <worktree-path>"
    echo "Example: git-diff-summary ../DOC-5524"
    exit 1
fi

WORKTREE_PATH="$1"

# Resolve absolute path
if [ ! -d "$WORKTREE_PATH" ]; then
    echo -e "${RED}Error: Worktree path does not exist: $WORKTREE_PATH${NC}"
    exit 1
fi

WORKTREE_PATH="$(cd "$WORKTREE_PATH" && pwd)"
CONTEXT_DIR="$WORKTREE_PATH/CONTEXT"
SUMMARY_FILE="$CONTEXT_DIR/REVIEW_SUMMARY.md"

echo -e "${GREEN}=== Review Summary Generator ===${NC}\n"
echo -e "${YELLOW}→ Scanning worktree: $WORKTREE_PATH${NC}"

# Create temporary file for parsed issues
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Initialize counters (using regular variables for bash 3.x compatibility)
SEVERITY_CRITICAL=0
SEVERITY_MAJOR=0
SEVERITY_MINOR=0
SEVERITY_NITPICK=0
SEVERITY_UNKNOWN=0

# Defect categories list (for reference)
CATEGORY_LIST="Bugs / Functional Defects|Security Vulnerabilities|Performance Defects|Usability / UX Defects|Reliability / Stability Defects|Maintainability Issues (Code Smells)|Compatibility / Integration Defects|Data Quality / Integrity Defects|Localization / Internationalization Defects|Other"

# Function to detect severity from comment
detect_severity() {
    local comment="$1"
    if echo "$comment" | grep -qE "🔴|Critical|CRITICAL"; then
        echo "CRITICAL"
    elif echo "$comment" | grep -qE "🟠|Major|MAJOR"; then
        echo "MAJOR"
    elif echo "$comment" | grep -qE "🟡|Minor|MINOR"; then
        echo "MINOR"
    elif echo "$comment" | grep -qE "🟢|Nitpick|NITPICK"; then
        echo "NITPICK"
    else
        echo "UNKNOWN"
    fi
}

# Function to detect defect category from comment
detect_category() {
    local comment="$1"
    # Check each category in order
    if echo "$comment" | grep -qiF "Bugs / Functional Defects"; then
        echo "Bugs / Functional Defects"
    elif echo "$comment" | grep -qiF "Security Vulnerabilities"; then
        echo "Security Vulnerabilities"
    elif echo "$comment" | grep -qiF "Performance Defects"; then
        echo "Performance Defects"
    elif echo "$comment" | grep -qiF "Usability / UX Defects"; then
        echo "Usability / UX Defects"
    elif echo "$comment" | grep -qiF "Reliability / Stability Defects"; then
        echo "Reliability / Stability Defects"
    elif echo "$comment" | grep -qiF "Maintainability Issues"; then
        echo "Maintainability Issues (Code Smells)"
    elif echo "$comment" | grep -qiF "Compatibility / Integration Defects"; then
        echo "Compatibility / Integration Defects"
    elif echo "$comment" | grep -qiF "Data Quality / Integrity Defects"; then
        echo "Data Quality / Integrity Defects"
    elif echo "$comment" | grep -qiF "Localization / Internationalization Defects"; then
        echo "Localization / Internationalization Defects"
    else
        echo "Other"
    fi
}

# Function to extract issue details from multi-line comment
extract_issue_details() {
    local file="$1"
    local line_num="$2"
    local issue_line="$3"
    
    # Read next few lines to get full comment block
    local issue_text=""
    local suggestion_text=""
    local reference_text=""
    
    # Read up to 5 lines after the TODO/Consider line
    local start_line=$((line_num + 1))
    local end_line=$((line_num + 5))
    
    # Use process substitution to avoid pipeline variable scoping issues
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*//[[:space:]]*Issue:[[:space:]]*(.+) ]]; then
            issue_text="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]*//[[:space:]]*Suggestion:[[:space:]]*(.+) ]]; then
            suggestion_text="${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^[[:space:]]*//[[:space:]]*Reference:[[:space:]]*(.+) ]]; then
            reference_text="${BASH_REMATCH[1]}"
        elif [[ ! "$line" =~ ^[[:space:]]*// ]] && [[ ! "$line" =~ ^[[:space:]]*$ ]]; then
            # Hit non-comment, non-empty line - we're done with this comment block
            break
        fi
    done < <(sed -n "${start_line},${end_line}p" "$file" 2>/dev/null)
    
    echo "$issue_text|$suggestion_text|$reference_text"
}

# Scan source files for review comments
# Only scan files that were changed in the diff (against origin/main)
file_count=0
issue_count=0

# Change to worktree directory to run git commands
cd "$WORKTREE_PATH"

# Get list of changed files from git diff
# Use origin/main as base, or main if origin/main doesn't exist
if git show-ref --verify --quiet "refs/remotes/origin/main"; then
    BASE_REF="origin/main"
elif git show-ref --verify --quiet "refs/heads/main"; then
    BASE_REF="main"
else
    # Fallback: try to find the default branch
    BASE_REF=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
fi

echo -e "${YELLOW}→ Getting changed files from git diff (base: $BASE_REF)...${NC}"

# Get changed files and filter to source files only
CHANGED_FILES=$(git diff --name-only "$BASE_REF"...HEAD 2>/dev/null | grep -E '\.(ts|tsx|js|jsx|py|java|go|rs|cpp|c|h|hpp)$' || true)

if [ -z "$CHANGED_FILES" ]; then
    echo -e "${YELLOW}⚠ No changed source files found in diff${NC}"
    echo -e "${GREEN}✓ Scanned $file_count files, found $issue_count review comments${NC}"
else
    # Use process substitution to avoid subshell issues with counters
    while IFS= read -r rel_file; do
        # Skip if file doesn't exist (might have been deleted)
        if [ ! -f "$WORKTREE_PATH/$rel_file" ]; then
            continue
        fi
        
        # Skip files in excluded directories
        if echo "$rel_file" | grep -qE '(CONTEXT|node_modules|\.git|dist|build|\.next|coverage)/'; then
            continue
        fi
        
        file="$WORKTREE_PATH/$rel_file"
        ((file_count++))
        line_num=0
        
        while IFS= read -r line; do
            ((line_num++))
            
            # Check for TODO: pattern with severity
            if [[ "$line" =~ ^[[:space:]]*//[[:space:]]*(TODO|FIXME|REVIEW):[[:space:]]*(.+) ]]; then
                comment_text="${BASH_REMATCH[2]}"
                severity=$(detect_severity "$comment_text")
                category=$(detect_category "$comment_text")
                
                # Extract issue details
                details=$(extract_issue_details "$file" $line_num "$line")
                IFS='|' read -r issue_text suggestion_text reference_text <<< "$details"
                
                # Extract title (everything after severity emoji/word)
                title=$(echo "$comment_text" | sed -E 's/^[🔴🟠🟡🟢]*[[:space:]]*(Critical|Major|Minor|Nitpick|CRITICAL|MAJOR|MINOR|NITPICK)[[:space:]]*-?[[:space:]]*//' | sed -E 's/^[🔴🟠🟡🟢]*[[:space:]]*//')
                if [ -z "$title" ]; then
                    title="$comment_text"
                fi
                
                # Store issue
                echo "$severity|$category|$rel_file|$line_num|$title|$issue_text|$suggestion_text|$reference_text" >> "$TEMP_FILE"
                
                # Update severity counters
                case "$severity" in
                    CRITICAL) ((SEVERITY_CRITICAL++)) ;;
                    MAJOR) ((SEVERITY_MAJOR++)) ;;
                    MINOR) ((SEVERITY_MINOR++)) ;;
                    NITPICK) ((SEVERITY_NITPICK++)) ;;
                    *) ((SEVERITY_UNKNOWN++)) ;;
                esac
                
                ((issue_count++))
                
            # Check for Consider: pattern (simpler format)
            elif [[ "$line" =~ ^[[:space:]]*//[[:space:]]*Consider:[[:space:]]*(.+) ]]; then
                comment_text="${BASH_REMATCH[1]}"
                severity="MINOR"  # Consider comments are typically minor suggestions
                category=$(detect_category "$comment_text")
                if [ "$category" = "Other" ]; then
                    category="Maintainability Issues (Code Smells)"
                fi
                
                echo "$severity|$category|$rel_file|$line_num|$comment_text|||" >> "$TEMP_FILE"
                
                # Update severity counters
                case "$severity" in
                    CRITICAL) ((SEVERITY_CRITICAL++)) ;;
                    MAJOR) ((SEVERITY_MAJOR++)) ;;
                    MINOR) ((SEVERITY_MINOR++)) ;;
                    NITPICK) ((SEVERITY_NITPICK++)) ;;
                    *) ((SEVERITY_UNKNOWN++)) ;;
                esac
                
                ((issue_count++))
            fi
        done < "$file"
    done < <(echo "$CHANGED_FILES")
    
    echo -e "${GREEN}✓ Scanned $file_count changed files, found $issue_count review comments${NC}"
fi

echo -e "${GREEN}✓ Scanned $file_count files, found $issue_count review comments${NC}"

# Generate summary report
mkdir -p "$CONTEXT_DIR"

cat > "$SUMMARY_FILE" << EOF
# Review Summary Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')  
**Worktree:** \`$WORKTREE_PATH\`  
**Total Issues Found:** $issue_count

---

## 📊 Executive Summary

EOF

# Calculate merge readiness
if [ $SEVERITY_CRITICAL -gt 0 ]; then
    merge_status="❌ **NOT READY** - Critical issues must be addressed"
    risk_level="🔴 High"
elif [ $SEVERITY_MAJOR -gt 3 ]; then
    merge_status="⚠️ **REVIEW REQUIRED** - Multiple major issues found"
    risk_level="🟡 Medium"
elif [ $SEVERITY_MAJOR -gt 0 ]; then
    merge_status="⚠️ **CONDITIONAL** - Some major issues should be addressed"
    risk_level="🟡 Medium"
elif [ $issue_count -eq 0 ]; then
    merge_status="✅ **READY TO MERGE** - No issues found"
    risk_level="🟢 Low"
else
    merge_status="✅ **READY TO MERGE** - Only minor/nitpick issues"
    risk_level="🟢 Low"
fi

cat >> "$SUMMARY_FILE" << EOF
**Merge Status:** $merge_status  
**Risk Level:** $risk_level

---

## 🔴 Issues by Severity

| Severity | Count | Percentage |
|----------|-------|------------|
| 🔴 Critical | $SEVERITY_CRITICAL | $(awk "BEGIN {printf \"%.1f\", ($SEVERITY_CRITICAL / $issue_count) * 100}" 2>/dev/null || echo "0")% |
| 🟠 Major | $SEVERITY_MAJOR | $(awk "BEGIN {printf \"%.1f\", ($SEVERITY_MAJOR / $issue_count) * 100}" 2>/dev/null || echo "0")% |
| 🟡 Minor | $SEVERITY_MINOR | $(awk "BEGIN {printf \"%.1f\", ($SEVERITY_MINOR / $issue_count) * 100}" 2>/dev/null || echo "0")% |
| 🟢 Nitpick | $SEVERITY_NITPICK | $(awk "BEGIN {printf \"%.1f\", ($SEVERITY_NITPICK / $issue_count) * 100}" 2>/dev/null || echo "0")% |
EOF

if [ $SEVERITY_UNKNOWN -gt 0 ]; then
    cat >> "$SUMMARY_FILE" << EOF
| ⚪ Unknown | $SEVERITY_UNKNOWN | $(awk "BEGIN {printf \"%.1f\", ($SEVERITY_UNKNOWN / $issue_count) * 100}" 2>/dev/null || echo "0")% |
EOF
fi

cat >> "$SUMMARY_FILE" << EOF

---

## 📋 Issues by Defect Category

| Category | Count |
|----------|-------|
EOF

# Sort categories by count (descending) - extract from temp file
cut -d'|' -f2 "$TEMP_FILE" 2>/dev/null | sort | uniq -c | sort -rn | while read -r count category; do
    if [ -n "$category" ] && [ "$count" -gt 0 ]; then
        echo "| $category | $count |" >> "$SUMMARY_FILE"
    fi
done

cat >> "$SUMMARY_FILE" << EOF

---

## 📁 Files with Most Issues

| File | Issue Count |
|------|-------------|
EOF

# Sort files by issue count (descending) - extract from temp file
cut -d'|' -f3 "$TEMP_FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -10 | while read -r count file; do
    if [ -n "$file" ] && [ "$count" -gt 0 ]; then
        echo "| \`$file\` | $count |" >> "$SUMMARY_FILE"
    fi
done

cat >> "$SUMMARY_FILE" << EOF

---

## 📝 Detailed Issue List

EOF

# Group issues by file
current_file=""
while IFS='|' read -r severity category file line title issue suggestion reference; do
    if [ "$file" != "$current_file" ]; then
        if [ -n "$current_file" ]; then
            echo "" >> "$SUMMARY_FILE"
        fi
        current_file="$file"
        echo "### \`$file\`" >> "$SUMMARY_FILE"
        echo "" >> "$SUMMARY_FILE"
    fi
    
    # Determine severity emoji
    case "$severity" in
        CRITICAL) sev_emoji="🔴" ;;
        MAJOR) sev_emoji="🟠" ;;
        MINOR) sev_emoji="🟡" ;;
        NITPICK) sev_emoji="🟢" ;;
        *) sev_emoji="⚪" ;;
    esac
    
    echo "**$sev_emoji [$severity] $category - Line $line:** $title" >> "$SUMMARY_FILE"
    
    if [ -n "$issue" ]; then
        echo "- **Issue:** $issue" >> "$SUMMARY_FILE"
    fi
    if [ -n "$suggestion" ]; then
        echo "- **Suggestion:** $suggestion" >> "$SUMMARY_FILE"
    fi
    if [ -n "$reference" ]; then
        echo "- **Reference:** $reference" >> "$SUMMARY_FILE"
    fi
    echo "" >> "$SUMMARY_FILE"
done < <(sort -t'|' -k3,3 -k4,4n "$TEMP_FILE")

cat >> "$SUMMARY_FILE" << EOF

---

## 💡 Recommendations

EOF

# Generate recommendations based on findings
if [ $SEVERITY_CRITICAL -gt 0 ]; then
    cat >> "$SUMMARY_FILE" << EOF
### Must Fix (Before Merge) - 🔴 Critical
- [ ] Address $SEVERITY_CRITICAL critical issue(s) that could cause bugs, crashes, or data loss

EOF
fi

if [ $SEVERITY_MAJOR -gt 0 ]; then
    cat >> "$SUMMARY_FILE" << EOF
### Should Fix (High Priority) - 🟠 Major
- [ ] Review and address $SEVERITY_MAJOR major issue(s) impacting performance, architecture, or maintainability

EOF
fi

if [ $SEVERITY_MINOR -gt 0 ] || [ $SEVERITY_NITPICK -gt 0 ]; then
    cat >> "$SUMMARY_FILE" << EOF
### Consider (Nice to Have) - 🟡 Minor / 🟢 Nitpick
- [ ] Consider addressing $SEVERITY_MINOR minor and $SEVERITY_NITPICK nitpick issue(s) for code quality improvements

EOF
fi

cat >> "$SUMMARY_FILE" << EOF
---

*This report was generated automatically by scanning source files for review comments.*  
*To update this report, run: \`git-diff-summary $WORKTREE_PATH\`*
EOF

echo -e "${GREEN}✓ Summary report generated: $SUMMARY_FILE${NC}"
echo -e "\n${GREEN}=== Summary Statistics ===${NC}"
echo -e "  ${BLUE}Total Issues:${NC} $issue_count"
echo -e "  ${RED}Critical:${NC} $SEVERITY_CRITICAL  ${YELLOW}Major:${NC} $SEVERITY_MAJOR  ${YELLOW}Minor:${NC} $SEVERITY_MINOR  ${GREEN}Nitpick:${NC} $SEVERITY_NITPICK"
# Count unique files from temp file
files_with_issues=$(cut -d'|' -f3 "$TEMP_FILE" 2>/dev/null | sort -u | wc -l | tr -d ' ')
echo -e "  ${BLUE}Files with Issues:${NC} $files_with_issues"
echo -e "  ${BLUE}Merge Status:${NC} $merge_status"
echo -e "\n${GREEN}→ View full report: cat $SUMMARY_FILE${NC}"

