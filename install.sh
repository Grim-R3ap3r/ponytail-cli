#!/usr/bin/env bash
# ponytail installer
# curl -fsSL https://raw.githubusercontent.com/Grim-R3ap3r/ponytail-cli/main/install.sh | bash
set -euo pipefail

REPO="Grim-R3ap3r/ponytail-cli"
BRANCH="main"
INSTALL_DIR="${PONYTAIL_INSTALL_DIR:-$HOME/.local/bin}"
SHARE_DIR="${PONYTAIL_SHARE_DIR:-$HOME/.local/share/ponytail}"

printf '\n  \033[1mponytail\033[0m installer\n\n'

mkdir -p "$INSTALL_DIR" "$SHARE_DIR/skills/ponytail-review"

curl -fsSL "https://raw.githubusercontent.com/$REPO/$BRANCH/ponytail" \
  -o "$INSTALL_DIR/ponytail"
chmod +x "$INSTALL_DIR/ponytail"

curl -fsSL "https://raw.githubusercontent.com/$REPO/$BRANCH/skills/ponytail-review/SKILL.md" \
  -o "$SHARE_DIR/skills/ponytail-review/SKILL.md"

printf '  \033[1;32m✓\033[0m  Installed  %s/ponytail\n' "$INSTALL_DIR"
printf '  \033[1;32m✓\033[0m  Skill      %s/skills/ponytail-review/SKILL.md\n\n' "$SHARE_DIR"

if ! echo "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
  printf '  Add to your PATH in ~/.zshrc:\n\n'
  printf '    \033[1mexport PATH="$HOME/.local/bin:$PATH"\033[0m\n\n'
fi

printf '  Set your AI API key in ~/.zshrc:\n\n'
printf '    \033[1mexport CURSOR_API_KEY="your-cursor-api-key"\033[0m\n'
printf '    # or\n'
printf '    \033[1mexport ANTHROPIC_API_KEY="your-anthropic-api-key"\033[0m\n\n'
printf '  Then verify:\n\n'
printf '    \033[1mponytail setup\033[0m\n\n'
