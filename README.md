# Git Diff Analyzer

A powerful tool for analyzing git branch diffs locally by creating isolated worktrees and organizing all necessary context files for comprehensive code reviews.

## Features

- 🚀 **Automated Worktree Setup** - Creates isolated git worktrees for branch review
- 📋 **Context Organization** - Automatically organizes diff files and configuration
- 🔍 **Review Summary Generator** - Generates comprehensive reports from review comments
- 🎯 **Defect Categorization** - Categorizes issues by severity and defect type
- ⚙️ **Flexible Configuration** - Required standards + optional team-specific context

## Quick Start

### Installation

1. **Make scripts executable:**
   ```bash
   chmod +x bin/git-diff-review.sh
   chmod +x bin/git-diff-summary.sh
   ```

2. **Create aliases (recommended):**
   
   Add to your `~/.bashrc`, `~/.zshrc`, or equivalent:
   ```bash
   alias gdr="/path/to/git-diff-analyzer/bin/git-diff-review.sh"
   alias gds="/path/to/git-diff-analyzer/bin/git-diff-summary.sh"
   ```
   
   Then reload your shell:
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

### Basic Usage

**Prepare a branch for review:**
```bash
gdr feature/DOC-5524
```

**Generate review summary:**
```bash
gds ../DOC-5524
```

## Usage Guide

### Prerequisites

Make sure you are on the `main` branch in your repository directory before running the review script.

### Step 1: Prepare Review Environment

```bash
gdr feature/DOC-5524
cd ../DOC-5524
```

This will:
- Fetch the latest branch from origin
- Create a worktree at `../DOC-5524/`
- Generate a diff against `origin/main`
- Copy all configuration files to `CONTEXT/`

### Step 2: Review the Code

1. **View the diff:**
   ```bash
   cat CONTEXT/03__DIFF.md
   ```

2. **Review using your AI assistant or code review tool:**
   - Read `CONTEXT/DIFF.md` to see what changed
   - Read `CONTEXT/INSTRUCTIONS.md` for review workflow
   - Add inline comments directly to source files
   - Include severity levels (🔴 Critical, 🟠 Major, 🟡 Minor, 🟢 Nitpick) and defect categories

3. **Use standard git commands** (it's a git worktree):
   ```bash
   git status
   git log
   git diff
   ```

### Step 3: Generate Summary Report

After adding review comments to source files:

```bash
# From within the worktree:
gds .

# Or from the main repo:
gds ../DOC-5524
```

This generates `CONTEXT/REVIEW_SUMMARY.md` with:
- ✅ Executive summary with merge readiness assessment
- 📊 Issues grouped by severity (Critical, Major, Minor, Nitpick)
- 📋 Issues grouped by defect category
- 📁 Top files with most issues
- 📝 Detailed issue list organized by file
- 💡 Actionable recommendations

### Step 4: Review the Summary

```bash
cat CONTEXT/REVIEW_SUMMARY.md
```

## Project Structure

```
git-diff-analyzer/
├── bin/
│   ├── git-diff-review.sh           # Main review setup script
│   └── git-diff-summary.sh          # Summary report generator
├── config/
│   ├── required/                    # Required configuration files
│   │   ├── 00__INSTRUCTIONS.md      # Review workflow instructions
│   │   ├── 01__CODING_STANDARDS.md  # Coding standards for reviews
│   │   └── 02__DIFF_STANDARDS.md    # Review guidelines and defect categories
│   └── optional/                    # Optional team-specific context
│       └── README.md                # Instructions for optional files
└── README.md                        # This file
```

### Worktree Output Structure

```
../<branch-name>/
├── CONTEXT/
│   ├── 00__INSTRUCTIONS.md          # Copied from config/required/
│   ├── 01__CODING_STANDARDS.md      # Copied from config/required/
│   ├── 02__DIFF_STANDARDS.md        # Copied from config/required/
│   ├── 03__DIFF.md                  # Git diff against origin/main
│   ├── [optional files...]          # Copied from config/optional/
│   └── REVIEW_SUMMARY.md            # Generated after running gds
└── [your branch files...]
```

## Configuration

### Required Configuration

Files in `config/required/` are essential for the tool to function:

- **00__INSTRUCTIONS.md** - Defines the review workflow and comment format
- **01__CODING_STANDARDS.md** - Defines coding standards used during review
- **02__DIFF_STANDARDS.md** - Defines review guidelines, defect categories, and severity levels

These files are automatically copied to the `CONTEXT/` folder and are required for the review process.

### Optional Configuration

Files in `config/optional/` allow teams to add their own context:

- Team-specific coding conventions
- Architecture documentation
- API guidelines
- Security checklists
- Any other context that helps with code reviews

**Example optional files:**
- `TEAM_STANDARDS.md` - Team-specific conventions
- `ARCHITECTURE.md` - System architecture overview
- `API_GUIDELINES.md` - API design patterns
- `SECURITY_CHECKLIST.md` - Security review checklist

All files in `config/optional/` (except `README.md`) are automatically copied to the `CONTEXT/` folder.

### Customizing Standards

Edit the files in `config/required/` to customize:
- Coding standards (`01__CODING_STANDARDS.md`)
- Review guidelines and defect categories (`02__DIFF_STANDARDS.md`)
- Review workflow (`00__INSTRUCTIONS.md`)

## How It Works

### `git-diff-review.sh` (gdr)

1. Fetches the branch from origin
2. Creates a worktree (or updates existing) at `../<branch-name>/`
3. Creates a `CONTEXT/` folder in the worktree root
4. Copies required config files from `config/required/` to `CONTEXT/`
5. Copies optional config files from `config/optional/` to `CONTEXT/`
6. Generates a diff against `origin/main` and saves it as `CONTEXT/03__DIFF.md`

### `git-diff-summary.sh` (gds)

1. Scans all source files in the worktree for review comments
2. Parses comments to extract severity, category, and issue details
3. Generates statistics on issues by severity and category
4. Creates a markdown report with executive summary, detailed issue list, and recommendations

## Troubleshooting

### "Branch does not exist"

Make sure the branch name is correct and exists on the remote:

```bash
git fetch origin
git branch -r | grep <branch-name>
```

### "No differences found"

The branch may already be merged into `origin/main`, or there may be no changes. Check the diff manually:

```bash
git diff origin/main origin/<branch-name>
```

### "Required config directory not found"

Ensure that `config/required/` exists and contains the required files:
- `00__INSTRUCTIONS.md`
- `01__CODING_STANDARDS.md`
- `02__DIFF_STANDARDS.md`

### Worktree already exists

If a worktree already exists for the branch, the script will update it to match the latest remote state. To remove an existing worktree:

```bash
git worktree remove <worktree-path>
```

## Aliases Reference

| Alias | Command | Description |
|-------|---------|-------------|
| `gdr` | `git-diff-review.sh` | Prepare a branch for review |
| `gds` | `git-diff-summary.sh` | Generate review summary report |

## License

[Add your license here]

## Contributing

[Add contribution guidelines here]

