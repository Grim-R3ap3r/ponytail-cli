<p align="center">
  <img
    src="https://github.com/user-attachments/assets/9fa73253-2db0-4748-b54a-80a7f0133c7d"
    alt="image"
    width="463"
  />
</p>

AI-powered PR review CLI. Three review passes in one command — **bugs**, **regression risk**, and **over-engineering**.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Grim-R3ap3r/ponytail-cli/main/install.sh | bash
```

Or manually:

```bash
curl -fsSL https://raw.githubusercontent.com/Grim-R3ap3r/ponytail-cli/main/ponytail -o ~/.local/bin/ponytail
chmod +x ~/.local/bin/ponytail
```

## Setup

Add your API key to `~/.zshrc`:

```bash
# Cursor SDK (preferred)
export CURSOR_API_KEY="your-cursor-api-key"

# or Anthropic API (fallback)
export ANTHROPIC_API_KEY="your-anthropic-api-key"
```

Ensure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Verify everything works:

```bash
ponytail setup
```

## Usage

```bash
ponytail <PR>                              # review a PR (all passes)
ponytail review <PR> --pass bugs           # only bug pass
ponytail 42 --repo owner/repo --dry-run    # dry run against a specific repo
ponytail setup                             # check dependencies & config
```

### Review Passes

| Pass | What it catches |
|------|----------------|
| **bugs** | Logic errors, nil dereferences, swallowed errors, type mismatches |
| **regression** | Breaking API changes, removed fallbacks, changed error codes |
| **ponytail** | Over-engineering via the `/ponytail-review` skill (`skills/ponytail-review/SKILL.md`) |

### Options

| Flag | Description |
|------|-------------|
| `--repo OWNER/REPO` | Target repository (auto-detected if inside a git repo) |
| `--pass TYPE` | `bugs`, `regression`, `ponytail`, or `all` (default: `all`) |
| `--dry-run` | Print findings to terminal without posting to GitHub |

### Environment Variables

| Variable | Description |
|----------|-------------|
| `CURSOR_API_KEY` | Cursor SDK API key (preferred engine) |
| `ANTHROPIC_API_KEY` | Anthropic API key (curl fallback) |
| `CURSOR_MODEL` | Cursor SDK model for ponytail/verify (default: `auto`) |
| `CURSOR_MODEL_REVIEW` | Cursor SDK model for bugs/regression (default: `auto`) |
| `ANTHROPIC_MODEL` | Anthropic model for ponytail/verify (default: `claude-sonnet-4-20250514`) |
| `ANTHROPIC_MODEL_REVIEW` | Anthropic model for bugs/regression (default: `claude-opus-4-6`) |
| `CONFIDENCE_THRESHOLD` | Minimum confidence (1-10) to post a finding (default: `7`) |
| `PONYTAIL_MIN_ADDED` | Skip the over-engineering pass when added lines are below this (default: `80`) |
| `MAX_CONTEXT_FILES` | Max changed files to fetch full contents for (default: `20`) |
| `MAX_INLINE_COMMENTS` | Hard cap on posted inline comments (default: `8`) |

Posted comments render as:

```markdown
**[regression]** · warning · confidence 8

Remove fallback default timeout.

**Impact:** worker jobs time out under load.

**Evidence:**
- `worker/job.go:22 - still sleeps with old 30s assumption`
```

## Requirements

- [gh](https://cli.github.com/) — authenticated (`gh auth login`)
- [jq](https://jqlang.github.io/jq/) — JSON processing
- curl
- One of: `CURSOR_API_KEY` or `ANTHROPIC_API_KEY`
- Node.js + `@cursor/sdk` (only if using Cursor engine)

## How it works

1. Fetches the PR diff + metadata, and full contents of changed files
2. Builds a RIGHT-side hunk map for attachable lines
3. Runs review passes with confidence + evidence filters
4. Verifies evidence pinpoints exist in known files / hunks
5. Snaps comment lines onto real diff lines (or defers to summary)
6. Posts inline comments + a summary review

## License

MIT
