# Git Diff Analyzer

A tool that prepares git branch diffs for local review by creating a worktree and organizing all necessary context files.

## Installation

### 1. Make the script executable

```bash
chmod +x bin/git-diff-review.sh
```

### 2. Create an alias (optional but recommended)

Add this to your `~/.bashrc`, `~/.zshrc`, or equivalent:

```bash
alias <your-alias-name>="/path/to/git-diff-analyzer/bin/git-diff-review.sh"
```

Then reload your shell:

```bash
source ~/.bashrc  # or ~/.zshrc
```

## Usage

### Prerequisites

Make sure you are on the `main` branch in your repository directory before running the script.

### Basic Usage

```bash
<your-alias-name> <remote-branch-name>
```

### Example

```bash
<your-alias-name> feature/DOC-5524
```

### Accessing the Worktree

After running the script, navigate to the created worktree to review the changes:

```bash
cd ../<branch-name>
```

For example:
```bash
cd ../DOC-5524
```

The worktree contains:
- **CONTEXT/** folder with the diff and all config files
- All branch files for review

### Viewing Files

View the generated diff:
```bash
cat CONTEXT/DIFF.md
```

Since it's a git worktree, you can use standard git commands:
```bash
git status
git log
git diff
```

## How It Works

1. **Fetches the branch** from origin
2. **Creates a worktree** (or uses existing one) for the branch at `../<branch-name>/`
3. **Creates a CONTEXT folder** in the worktree root
4. **Copies all config files** from `config/` into the CONTEXT folder
5. **Generates a diff** against `origin/main` and saves it as `CONTEXT/DIFF.md`

### Output Structure

```
../<branch-name>/
├── CONTEXT/
│   ├── DIFF.md                    # The git diff against origin/main
│   ├── CODING_STANDARDS.md        # Copied from config/
│   └── DIFF_STANDARDS.md          # Copied from config/
└── [your branch files...]
```

## Configuration

All files in the `config/` directory are automatically copied to the CONTEXT folder when the script runs.

### Customizing Standards

- **Coding Standards**: Edit `config/CODING_STANDARDS.md` to customize the coding standards used for review
- **Diff Review Standards**: Edit `config/DIFF_STANDARDS.md` to customize how diffs should be reviewed

### Adding Additional Config Files

Simply add any additional configuration or context files to the `config/` directory, and they will be automatically included in the CONTEXT folder.

## Troubleshooting

### "Branch does not exist"

Make sure the branch name is correct and that it exists on the remote:

```bash
git fetch origin
git branch -r | grep <branch-name>
```

### "No differences found"

The branch may already be merged into `origin/main`, or there may be no changes. Check the diff manually:

```bash
git diff origin/main origin/<branch-name>
```

### Worktree already exists

If a worktree already exists for the branch, the script will update it to match the latest remote state. To remove an existing worktree:

```bash
git worktree remove <worktree-path>
```
