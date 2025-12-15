
# Summary
It has come to my attention that Cursor has a CLI. I want to see if there are any features that I can use from the CLI to enhance the way this diff analyzer works.

# Goal
Have a single command that I can run from the cli which will run the diff analyzer. 

## Current Workflow
Runnning `gdr <feature-branch>` will create the worktree (See README.md) and will create a CONTEXT folder which has all of the relevant context for analyzing the diff. The user must then **manually** drag and drop the CONTEXT folder into an interactive prompt to begin the diff analysis process. Please help me leverage the Cursor CLI so that this manual step is removed. Give me a few suggestions on how this can be done.

## Cursor CLI Automation Options

Based on the Cursor CLI capabilities, here are several approaches to automate the diff analysis workflow:

### Option 1: Use `cursor agent` with `--print` (Recommended for Automation)
**Best for:** Fully automated, scriptable workflow

The `cursor agent` command supports non-interactive mode with the `--print` flag and can accept a workspace path and initial prompt.

**Implementation:**
- Modify `git-diff-review.sh` to automatically invoke `cursor agent` after creating the CONTEXT folder
- Use `--workspace` to point to the worktree directory
- Use `--print` for non-interactive output (or omit for interactive mode)
- Pass a prompt that instructs the agent to analyze the diff using the CONTEXT files

**Example command:**
```bash
cursor agent --workspace "$WORKTREE_DIR" --print \
  "Please analyze the git diff in CONTEXT/DIFF.md according to the standards in CONTEXT/. Review the changes and provide feedback."
```

**Pros:**
- Fully automated, no manual intervention
- Can be integrated directly into the `gdr` script
- Supports both interactive (`--print` omitted) and non-interactive modes
- Can output results to console or files

**Cons:**
- Requires Cursor to be authenticated (`cursor agent login`)
- May require API key setup for headless use

### Option 2: Use `cursor agent` in Interactive Mode
**Best for:** Semi-automated workflow with user interaction

Open Cursor Agent in interactive mode with the workspace already set, ready for the user to start chatting.

**Implementation:**
- After `gdr` completes, automatically open `cursor agent` with the worktree as workspace
- User can immediately start chatting without needing to drag/drop files
- The agent will have access to all files in the workspace

**Example command:**
```bash
cursor agent --workspace "$WORKTREE_DIR" \
  "I've prepared a git diff for review. The diff is in CONTEXT/DIFF.md and review standards are in CONTEXT/. Please help me analyze this diff."
```

**Pros:**
- Still interactive, allowing for back-and-forth conversation
- No manual file dragging needed
- Agent has full context from the start

**Cons:**
- Still requires user interaction (though streamlined)
- Opens in terminal, may not be as user-friendly as GUI

### Option 3: Open Cursor IDE with Worktree + Auto-prompt
**Best for:** GUI-based workflow with automation

Open the worktree in Cursor IDE and optionally use the `--add` flag to add the CONTEXT folder to the workspace.

**Implementation:**
- After `gdr` completes, open Cursor with the worktree directory
- Optionally create a `.cursorrules` or similar file in the worktree that provides context
- User opens Cursor and can immediately use Composer with all context available

**Example command:**
```bash
cursor "$WORKTREE_DIR"
# Or add CONTEXT folder explicitly:
cursor -a "$CONTEXT_DIR" "$WORKTREE_DIR"
```

**Pros:**
- Uses familiar Cursor GUI interface
- All files are already in the workspace
- User can use Composer naturally

**Cons:**
- Still requires manual step to open Composer and start chat
- Less automated than agent approach

### Option 4: Hybrid Approach - Script with User Choice
**Best for:** Maximum flexibility

Create a wrapper script that gives the user options after `gdr` completes.

**Implementation:**
- After `gdr` completes, prompt user: "Open in Cursor Agent? (y/n)"
- If yes, launch `cursor agent` with appropriate flags
- If no, just open Cursor IDE or provide instructions

**Example:**
```bash
echo "Diff analysis ready! How would you like to proceed?"
echo "1) Open in Cursor Agent (interactive)"
echo "2) Open in Cursor Agent (non-interactive/print)"
echo "3) Open in Cursor IDE"
read -p "Choice [1-3]: " choice

case $choice in
  1) cursor agent --workspace "$WORKTREE_DIR" ;;
  2) cursor agent --workspace "$WORKTREE_DIR" --print ;;
  3) cursor "$WORKTREE_DIR" ;;
esac
```

**Pros:**
- Flexible, user chooses their preferred workflow
- Can support multiple use cases

**Cons:**
- Adds an extra step/prompt
- More complex implementation

## Recommended Implementation

**Recommended: Manual Workflow (see section below)** - Don't force analysis immediately. Let users open Cursor when ready and run the agent command from the worktree root.

**Alternative:** Option 1 or Option 2 if you want automatic launching, but this is less flexible.

### Suggested Script Enhancement

Add to the end of `git-diff-review.sh`:

```bash
# Optional: Auto-launch Cursor Agent for diff analysis
if command -v cursor >/dev/null 2>&1; then
    echo -e "\n${YELLOW}→ Launching Cursor Agent for diff analysis...${NC}"
    echo -e "${GREEN}→ Workspace: $WORKTREE_DIR${NC}"
    echo -e "${GREEN}→ Context files available in: $CONTEXT_DIR${NC}"
    
    # Check if user wants interactive or non-interactive
    if [ "${CURSOR_AUTO_ANALYZE:-}" = "1" ]; then
        # Non-interactive mode (set CURSOR_AUTO_ANALYZE=1)
        cursor agent --workspace "$WORKTREE_DIR" --print \
          "Analyze the git diff in CONTEXT/DIFF.md according to CODING_STANDARDS.md and DIFF_STANDARDS.md in CONTEXT/. Provide a comprehensive code review."
    else
        # Interactive mode (default)
        cursor agent --workspace "$WORKTREE_DIR" \
          "I've prepared a git diff for review. The diff is in CONTEXT/DIFF.md. Review standards are in CONTEXT/CODING_STANDARDS.md and CONTEXT/DIFF_STANDARDS.md. Please help me analyze this diff."
    fi
else
    echo -e "${YELLOW}⚠ Cursor CLI not found. Install it to enable automatic diff analysis.${NC}"
    echo -e "${YELLOW}→ To analyze manually, open Cursor and drag the CONTEXT folder into Composer.${NC}"
fi
```

### Prerequisites

Before using Cursor Agent, users need to:
1. Authenticate: `cursor agent login`
2. (Optional) For non-interactive mode, may need to set `CURSOR_API_KEY` environment variable

### Environment Variable Control

Users can control behavior with environment variables:
- `CURSOR_AUTO_ANALYZE=1` - Enable automatic analysis (non-interactive)
- `CURSOR_SKIP_ANALYZE=1` - Skip automatic analysis (just create worktree)

## Manual Workflow (Recommended)

**Preferred approach:** Don't force analysis immediately after `gdr` runs. Instead, let users open Cursor in the worktree root when they're ready.

### Step 1: Run `gdr` to create worktree
```bash
gdr feature/DOC-5524
cd ../DOC-5524
```

### Step 2: Open Cursor in worktree root (when ready)
```bash
cursor .
```

### Step 3: From worktree root, run Cursor Agent
Once you're in the worktree root directory, run:

```bash
cursor agent --workspace . "I've prepared a git diff for review. The diff is in CONTEXT/DIFF.md. Review standards are in CONTEXT/CODING_STANDARDS.md and CONTEXT/DIFF_STANDARDS.md. Please help me analyze this diff given the files inside of CONTEXT."
```

**Note:** The `--workspace .` sets the workspace to the current directory (worktree root), giving the agent access to all files including the `CONTEXT/` folder. Since you're already in the worktree root, the agent will automatically have access to `CONTEXT/DIFF.md`, `CONTEXT/CODING_STANDARDS.md`, etc.

### Alternative: Create a helper script in worktree

You could also create a simple script in the worktree root (e.g., `analyze-diff.sh`) that users can run:

```bash
#!/usr/bin/env bash
cursor agent --workspace . "I've prepared a git diff for review. The diff is in CONTEXT/DIFF.md. Review standards are in CONTEXT/CODING_STANDARDS.md and CONTEXT/DIFF_STANDARDS.md. Please help me analyze this diff given the files inside of CONTEXT."
```

This way users can simply run `./analyze-diff.sh` from the worktree root.

**Optional Enhancement to `git-diff-review.sh`:**

You could modify `gdr` to automatically create this helper script in the worktree root:

```bash
# Create helper script for easy analysis
cat > "$WORKTREE_DIR/analyze-diff.sh" << 'ANALYZE_EOF'
#!/usr/bin/env bash
cursor agent --workspace . "I've prepared a git diff for review. The diff is in CONTEXT/DIFF.md. Review standards are in CONTEXT/CODING_STANDARDS.md and CONTEXT/DIFF_STANDARDS.md. Please help me analyze this diff given the files inside of CONTEXT."
ANALYZE_EOF
chmod +x "$WORKTREE_DIR/analyze-diff.sh"
echo -e "${GREEN}✓ Created helper script: $WORKTREE_DIR/analyze-diff.sh${NC}"
echo -e "${YELLOW}→ Run './analyze-diff.sh' from the worktree root to start analysis${NC}"
```

This gives users a convenient one-command way to start the analysis when they're ready.