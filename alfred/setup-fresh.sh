#!/usr/bin/env bash
# Fresh Linux Mint / Ubuntu machine -> Alfred running 24/7 on Telegram.
#
#   curl -fsSL https://raw.githubusercontent.com/scottcarsten/moltbot/main/alfred/setup-fresh.sh | bash
#
# Builds Moltbot from this fork (pinned, not whatever upstream ships today),
# then hands off to `moltbot onboard`, which asks for your Anthropic API key
# and Telegram bot token. Finishes by running alfred/apply.sh.
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/scottcarsten/moltbot.git}"
SRC_DIR="${SRC_DIR:-$HOME/moltbot}"
BIN_DIR="$HOME/.local/bin"

export COREPACK_ENABLE_DOWNLOAD_PROMPT=0

say() { printf '\n==> %s\n' "$*"; }

# Everything runs inside main() so `curl | bash` reads the whole script
# before any command can consume stdin.
main() {

if [ "$(id -u)" -eq 0 ]; then
  echo "error: run as your normal user, not root (sudo is used where needed)" >&2
  exit 1
fi

say "Installing system packages (git, curl, build tools)"
sudo apt-get update
sudo apt-get install -y git curl ca-certificates build-essential unzip

NODE_MAJOR="$(node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/' || echo 0)"
if [ "${NODE_MAJOR:-0}" -lt 22 ]; then
  say "Installing Node.js 22"
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi
sudo corepack enable

if ! command -v bun >/dev/null 2>&1; then
  say "Installing Bun (used by the build scripts)"
  curl -fsSL https://bun.sh/install | bash
fi
export PATH="$HOME/.bun/bin:$PATH"

say "Getting the source"
if [ -d "$SRC_DIR/.git" ]; then
  git -C "$SRC_DIR" pull --ff-only
else
  git clone "$REPO_URL" "$SRC_DIR"
fi
cd "$SRC_DIR"

say "Building Moltbot (takes a few minutes)"
# Same steps as the repo's Dockerfile.
pnpm install --frozen-lockfile
CLAWDBOT_A2UI_SKIP_MISSING=1 pnpm build
CLAWDBOT_PREFER_PNPM=1 pnpm ui:install
CLAWDBOT_PREFER_PNPM=1 pnpm ui:build

say "Putting 'moltbot' on your PATH"
mkdir -p "$BIN_DIR"
ln -sf "$SRC_DIR/moltbot.mjs" "$BIN_DIR/moltbot"
export PATH="$BIN_DIR:$PATH"
grep -q '.local/bin' "$HOME/.bashrc" 2>/dev/null \
  || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"

say "Keeping Alfred alive when you're logged out and the lid is closed"
sudo loginctl enable-linger "$USER"
sudo mkdir -p /etc/systemd/logind.conf.d
printf '[Login]\nHandleLidSwitch=ignore\nHandleLidSwitchExternalPower=ignore\n' \
  | sudo tee /etc/systemd/logind.conf.d/alfred-lid.conf >/dev/null

say "Your turn: onboarding"
cat <<'EOF'
Moltbot will now ask a few questions. Have these ready:
  - Anthropic API key   (console.anthropic.com -> API Keys; starts with sk-ant-api)
  - Telegram bot token  (@BotFather -> /mybots -> Alfred_digital__butler -> API Token)
Pick Anthropic as the model provider and Telegram as the channel.
EOF
moltbot onboard --install-daemon </dev/tty

say "Making him Alfred"
"$SRC_DIR/alfred/apply.sh"

say "All set"
echo "Lid-close setting takes effect after a reboot. Then message Alfred on Telegram."
}

main "$@"
