# ponytail

AI-powered PR review CLI. Three review passes in one command — **bugs**, **regression risk**, and **over-engineering**.

```
   ╭─╮ ponytail  v2.2.0
   ╰─╯ lazy senior reviews

  Commands
  review a PR                  ponytail <PR>
  check your environment       ponytail setup
  preview (no GitHub post)     --dry-run

  Try next
  first-time check             ponytail setup
  safe preview                 ponytail 162 --dry-run
```

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
| `CURSOR_MODEL` | Model for Cursor SDK (default: `claude-sonnet-4`) |
| `CURSOR_MODEL_REVIEW` | Model for bugs/regression passes — use a stronger model here (default: same as `CURSOR_MODEL`) |
| `ANTHROPIC_MODEL` | Model for Anthropic (default: `claude-sonnet-4-20250514`) |
| `ANTHROPIC_MODEL_REVIEW` | Model for bugs/regression passes via Anthropic (default: same as `ANTHROPIC_MODEL`) |
| `CONFIDENCE_THRESHOLD` | Minimum confidence (1-10) to post a finding (default: `7`) |
| `PONYTAIL_MIN_ADDED` | Skip the over-engineering pass when added lines are below this (default: `80`) |
| `MAX_CONTEXT_FILES` | Max changed files to fetch full contents for (default: `20`) |
| `MAX_INLINE_COMMENTS` | Hard cap on posted inline comments (default: `8`) |

## v2.2 — verified evidence + reliable line attach

- **Evidence existence check:** every `path:line` in `evidence[]` must exist in fetched file contents (line ≤ file length) or on a real diff hunk line. Hallucinated pinpoints are dropped before posting.
- **Hunk line snap:** builds a map of valid RIGHT-side diff lines from `@@` hunks. If the model's line is slightly off, snaps to the nearest attachable line (within 25). If none exists, the finding goes in the **summary review** (with full evidence) instead of silently failing.
- GitHub attach failures also fall back to the summary — authors always see the pinpoint.

## v2.1 — evidence-backed comments

Targets [partner-api#1780](https://github.com/Orange-Health/partner-api/pull/1780)-style FUD (*"any code depending on X will break"* with zero call sites).

Every finding requires `evidence[]`, `impact`, and `severity`. Hard filters drop speculative wording and regressions without a consumer outside the changed file.

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
