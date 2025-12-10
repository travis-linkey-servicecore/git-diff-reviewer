# Optional Configuration Files

This directory is for additional configuration files that you want to include in the review context.

## Usage

Any files you place in this directory will be automatically copied to the `CONTEXT/` folder when running `git-diff-review.sh`. This allows you to add:

- Additional coding standards specific to your project
- Team-specific review guidelines
- Domain-specific context files
- Architecture documentation
- API documentation
- Any other context that helps with code reviews

## Examples

- `TEAM_STANDARDS.md` - Team-specific coding conventions
- `ARCHITECTURE.md` - System architecture overview
- `API_GUIDELINES.md` - API design patterns
- `SECURITY_CHECKLIST.md` - Security review checklist

## Note

Files in this directory are optional and won't break functionality if missing. The required configuration files are in `config/required/`.

