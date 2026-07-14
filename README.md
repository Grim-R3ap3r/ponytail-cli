# ponytail

AI-powered PR review CLI. Three review passes in one command — **bugs**, **regression risk**, and **over-engineering**.

```
  ╭───────────────────────────────────╮
  │  ponytail  ·  PR review CLI       │
  ╰───────────────────────────────────╯

  PR #162  Orange-Health/sorting-hat
  feat/email-propogate → main
  commit a1b2c3d4e5f6  diff 4KB  engine cursor

  ▸ bugs            2 finding(s)
  ▸ regression      1 finding(s)
  ▸ ponytail        clean

  ┌────────────────────────────────────┐
  │  Pass                    Findings  │
  ├────────────────────────────────────┤
  │  Bugs / correctness            2  │
  │  Regression risk               1  │
  │  Over-engineering              0  │
  ├────────────────────────────────────┤
  │  Total                         3  │
  └────────────────────────────────────┘
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
| **ponytail** | Over-engineering, YAGNI violations, stdlib reimplementations |

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
| `ANTHROPIC_MODEL` | Model for Anthropic (default: `claude-sonnet-4-20250514`) |

## Requirements

- [gh](https://cli.github.com/) — authenticated (`gh auth login`)
- [jq](https://jqlang.github.io/jq/) — JSON processing
- curl
- One of: `CURSOR_API_KEY` or `ANTHROPIC_API_KEY`
- Node.js + `@cursor/sdk` (only if using Cursor engine)

## How it works

1. Fetches the PR diff via `gh pr diff` (compares against the PR's base branch — `main`, `master`, or whatever the PR targets)
2. Runs three AI review passes against the diff
3. Deduplicates findings across passes
4. Posts inline review comments on the PR
5. Posts a summary table as a PR review comment

## License

MIT
