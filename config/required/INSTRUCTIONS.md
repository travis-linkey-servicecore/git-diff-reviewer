# Agent Instructions: Code Review Workflow

## Overview

When the CONTEXT folder is provided to you, you are being asked to review code changes and add **inline comments directly to the source code files**. This is a code review workflow where suggestions are embedded as comments in the actual code files.

## Critical Instructions

### ⚠️ DO NOT CREATE A REVIEW.md FILE

**You must NOT create any REVIEW.md, REVIEW.txt, or similar summary files.** All feedback must be added directly as comments in the source code files themselves.

### ✅ What You Should Do

1. **Read the DIFF.md file** in the CONTEXT folder to understand what code has changed
2. **Read the configuration files** (CODING_STANDARDS.md and DIFF_STANDARDS.md) to understand the review criteria
3. **Locate the source code files** that were changed (they are in the worktree, outside the CONTEXT folder)
4. **Add inline comments directly above the problematic code lines** in the actual source files
5. **Only review code that appears in the DIFF.md** - do not suggest changes to unchanged code

### Workflow Steps

1. **Read DIFF.md** - This contains the git diff showing what changed
2. **Identify changed files** - From the diff, determine which source files were modified
3. **Read the source files** - Open the actual source code files (not in CONTEXT folder, but in the worktree root)
4. **Add comments** - For each issue or suggestion, add a comment directly above the relevant line(s) in the source file
5. **Format comments** - Use clear, actionable comments that explain:
   - What the issue is
   - Why it's a problem
   - What should be changed (if applicable)
   - Reference to relevant coding standards when appropriate

### Comment Format

Add comments directly in the source code files using this format:

```typescript
// TODO: [Severity] [Issue Title]
// Issue: [Brief description of the problem]
// Suggestion: [What should be changed]
// Reference: [Relevant standard from CODING_STANDARDS.md if applicable]
const problematicCode = doSomething();
```

Or for simpler suggestions:

```typescript
// Consider: [Brief suggestion or improvement]
const code = doSomething();
```

### Scope Limitations

- **ONLY review code that appears in DIFF.md** - Do not suggest changes to code that wasn't modified
- **Focus on changed lines and their immediate context** - Don't audit the entire file
- **Add comments, don't modify code** - You are in a worktree, so comments are safe, but don't change the actual code logic

### File Locations

- **CONTEXT folder** contains:
  - `DIFF.md` - The git diff to review
  - `CODING_STANDARDS.md` - Coding standards to apply
  - `DIFF_STANDARDS.md` - Review guidelines
  - `INSTRUCTIONS.md` - This file

- **Source code files** are in the worktree root (parent directory of CONTEXT)
  - Navigate to the files mentioned in DIFF.md
  - These are the actual source files where you should add comments

### Example

If DIFF.md shows changes to `src/services/user.ts`, you should:

1. Read `CONTEXT/DIFF.md` to see what changed
2. Open `src/services/user.ts` (in the worktree root, not in CONTEXT)
3. Find the changed lines
4. Add comments directly above problematic code:

```typescript
// TODO: 🟡 Missing Error Handling
// Issue: This function doesn't handle the case where fetchUser() returns null
// Suggestion: Add null check before accessing user properties
// Reference: CODING_STANDARDS.md - "Treat async and errors as first-class"
const user = await fetchUser(id);
return user.email; // Potential null reference error
```

### Remember

- ✅ Add comments directly to source files
- ✅ Only review code in DIFF.md
- ✅ Reference coding standards when relevant
- ✅ Be specific and actionable
- ❌ DO NOT create REVIEW.md or any summary files
- ❌ DO NOT modify the actual code logic
- ❌ DO NOT review unchanged code

