# ponytail

AI-powered PR review CLI. Three review passes in one command — **bugs**, **regression risk**, and **over-engineering**.

```
   ╭─╮ ponytail  v2.0.0
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

## v2.0 — what changed

v2.0 is a quality-focused rewrite. The v1 review of [PR #167](https://github.com/Orange-Health/sorting-hat/pull/167) posted 5 comments — all 5 were dismissed by the PR author as false positives. Root cause: the model was reviewing a naked diff with zero codebase context, making unverifiable claims.

### Fixes

1. **Full file context** — fetches complete file contents (up to 8 files, 50KB each) alongside the diff. The model can now verify "is this variable used once?" or "do callers use positional init?" instead of guessing.
2. **Confidence scoring** — every finding includes a confidence score (1-10). Findings below the threshold (default 7) are silently dropped.
3. **Verification pass** — after the review passes generate findings, a second AI call receives the findings + full file context and prunes false positives.
4. **Anti-hallucination guardrails** — explicit prompt rules: "do not claim X unless you can verify it in the provided context", "returning [] for a clean PR is correct", etc.
5. **PR description included** — the model sees the PR title and body, understanding author intent before flagging.
6. **Per-pass model support** — use a stronger model (e.g. Opus) for bugs/regression while keeping a faster model for the ponytail pass.
7. **Small-diff skip** — the over-engineering pass is skipped for PRs under 80 added lines, where it produces noise instead of signal.

## Requirements

- [gh](https://cli.github.com/) — authenticated (`gh auth login`)
- [jq](https://jqlang.github.io/jq/) — JSON processing
- curl
- One of: `CURSOR_API_KEY` or `ANTHROPIC_API_KEY`
- Node.js + `@cursor/sdk` (only if using Cursor engine)

## How it works

1. Fetches the PR diff via `gh pr diff` and PR metadata (title, body)
2. Fetches full file contents for changed files via `gh api`
3. Runs three AI review passes with full context (diff + files + PR description)
4. Filters findings by confidence score
5. Runs a verification pass to prune false positives
6. Deduplicates findings across passes
7. Posts inline review comments on the PR
8. Posts a summary table as a PR review comment

## License

MIT
