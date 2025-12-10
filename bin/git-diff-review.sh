#!/usr/bin/env bash

# git-diff-review - Tool for analyzing git branch diffs locally
# Usage: git-diff-review <remote-branch-name>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$PROJECT_ROOT/config"

# Check if branch name is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: No branch name provided${NC}"
    echo "Usage: git-diff-review <remote-branch-name>"
    exit 1
fi

BRANCH_NAME="$1"

# Extract just the branch name without feature/, fix/, etc for directory name
# e.g., feature/DOC-5524 -> DOC-5524
CLEAN_BRANCH_NAME=$(echo "$BRANCH_NAME" | sed 's/.*\///')

# Get current directory and set worktree one level up
CURRENT_DIR="$(pwd)"
PARENT_DIR="$(dirname "$CURRENT_DIR")"
WORKTREE_DIR="$PARENT_DIR/$CLEAN_BRANCH_NAME"
CONTEXT_DIR="$WORKTREE_DIR/CONTEXT"
DIFF_FILE="$CONTEXT_DIR/DIFF.md"

echo -e "${GREEN}=== Git Diff Analyzer ===${NC}\n"

# Step 1: Fetch latest from remote
echo -e "${YELLOW}→ Fetching latest from origin...${NC}"
git fetch origin

# Step 2: Check if branch exists
if ! git show-ref --verify --quiet "refs/remotes/origin/$BRANCH_NAME"; then
    echo -e "${RED}Error: Branch 'origin/$BRANCH_NAME' does not exist${NC}"
    exit 1
fi

# Step 3: Create or use existing worktree
if [ -d "$WORKTREE_DIR" ]; then
    echo -e "${YELLOW}→ Using existing worktree at $WORKTREE_DIR...${NC}"
    cd "$WORKTREE_DIR"
    git fetch origin
    git reset --hard "origin/$BRANCH_NAME"
else
    echo -e "${YELLOW}→ Creating worktree at $WORKTREE_DIR...${NC}"
    git worktree add "$WORKTREE_DIR" "origin/$BRANCH_NAME"
    cd "$WORKTREE_DIR"
fi

# Step 4: Create CONTEXT directory
echo -e "${YELLOW}→ Creating CONTEXT directory...${NC}"
mkdir -p "$CONTEXT_DIR"

# Step 5: Copy required config files to CONTEXT
REQUIRED_DIR="$CONFIG_DIR/required"
OPTIONAL_DIR="$CONFIG_DIR/optional"

echo -e "${YELLOW}→ Copying required config files to CONTEXT...${NC}"
if [ -d "$REQUIRED_DIR" ]; then
    for file in "$REQUIRED_DIR"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            cp "$file" "$CONTEXT_DIR/"
            echo -e "  ${GREEN}✓${NC} Copied required: $filename"
        fi
    done
else
    echo -e "  ${RED}✗${NC} Required config directory not found: $REQUIRED_DIR"
    exit 1
fi

# Step 5b: Copy optional config files to CONTEXT
if [ -d "$OPTIONAL_DIR" ]; then
    echo -e "${YELLOW}→ Copying optional config files to CONTEXT...${NC}"
    for file in "$OPTIONAL_DIR"/*; do
        if [ -f "$file" ] && [ "$(basename "$file")" != "README.md" ]; then
            filename=$(basename "$file")
            cp "$file" "$CONTEXT_DIR/"
            echo -e "  ${GREEN}✓${NC} Copied optional: $filename"
        fi
    done
fi

# Step 6: Generate diff
echo -e "${YELLOW}→ Generating diff against origin/main...${NC}"
git diff remotes/origin/main...HEAD > "$DIFF_FILE"

# Check if diff is empty
if [ ! -s "$DIFF_FILE" ]; then
    echo -e "${RED}Error: No differences found between origin/main and $BRANCH_NAME${NC}"
    exit 1
fi

DIFF_SIZE=$(wc -l < "$DIFF_FILE")
echo -e "${GREEN}✓ Generated diff with $DIFF_SIZE lines${NC}"

echo -e "\n${GREEN}=== Complete ===${NC}"
echo -e "${GREEN}→ Worktree available at: $WORKTREE_DIR${NC}"
echo -e "${GREEN}→ Context files saved to: $CONTEXT_DIR${NC}"
echo -e "${GREEN}→ Diff saved to: $DIFF_FILE${NC}"
echo -e "${YELLOW}→ To view changes: cd $WORKTREE_DIR${NC}"
