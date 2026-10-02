#!/usr/bin/env bash
# Turn an existing Moltbot install into "Alfred":
#   - names the agent Alfred (and makes "Alfred" a group-chat trigger word)
#   - seeds the workspace with Alfred's IDENTITY.md / USER.md
#   - fixes the "permission denied ... docker.sock" sandbox error
#   - restarts the gateway
# Safe to re-run. Existing workspace files are backed up first.
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TELEGRAM_USER_ID="${TELEGRAM_USER_ID:-8686303310}"

if ! command -v moltbot >/dev/null 2>&1; then
  echo "error: 'moltbot' CLI not found on PATH" >&2
  exit 1
fi

say() { printf '\n==> %s\n' "$*"; }

say "Naming the agent Alfred"
if ! moltbot config get 'agents.list[0].id' >/dev/null 2>&1; then
  moltbot config set 'agents.list[0].id' main
  moltbot config set 'agents.list[0].default' true --json
fi
moltbot config set 'agents.list[0].name' Alfred
moltbot config set 'agents.list[0].identity' \
  '{ name: "Alfred", theme: "digital butler", emoji: "🎩" }' --json
# Case-insensitive; matches "Alfred", "alfred", "@Alfred" in group chats.
moltbot config set 'agents.list[0].groupChat.mentionPatterns' '["\\b@?alfred\\b"]' --json

say "Allowing your Telegram account (${TELEGRAM_USER_ID})"
moltbot config set 'channels.telegram.allowFrom' "[\"${TELEGRAM_USER_ID}\"]" --json

say "Fixing the Docker sandbox error"
if docker info >/dev/null 2>&1; then
  echo "Docker is reachable as $(whoami); keeping the sandbox on."
else
  moltbot config set 'agents.defaults.sandbox.mode' off
  echo "Docker isn't reachable as $(whoami), so the sandbox is now off."
  echo "To turn it back on later:"
  echo "  sudo usermod -aG docker $(whoami)   # then log out and back in"
  echo "  moltbot config set agents.defaults.sandbox.mode non-main"
fi

say "Seeding Alfred's workspace"
WORKSPACE="$(moltbot config get 'agents.list[0].workspace' 2>/dev/null | tail -n1 \
  || moltbot config get agents.defaults.workspace 2>/dev/null | tail -n1 \
  || echo "~/clawd")"
[ -n "$WORKSPACE" ] || WORKSPACE="~/clawd"
WORKSPACE="${WORKSPACE/#\~/$HOME}"
mkdir -p "$WORKSPACE"
STAMP="$(date +%Y%m%d-%H%M%S)"
for f in IDENTITY.md USER.md; do
  [ -f "$WORKSPACE/$f" ] && cp "$WORKSPACE/$f" "$WORKSPACE/$f.bak-$STAMP"
  cp "$KIT_DIR/$f" "$WORKSPACE/$f"
done
# The first-run ritual is what made him ask "who am I?"; he knows now.
[ -f "$WORKSPACE/BOOTSTRAP.md" ] && mv "$WORKSPACE/BOOTSTRAP.md" "$WORKSPACE/BOOTSTRAP.md.bak-$STAMP"
echo "Workspace: $WORKSPACE"

say "Restarting the gateway"
moltbot gateway restart || echo "Restart it however you normally start it (e.g. 'moltbot gateway')."

say "Done"
echo "In Telegram, send /reset to Alfred once (clears the old conversation where he thought you were Alfred),"
echo "then say: \"Alfred, who are you and who am I?\""
