# Alfred

Kit that turns Moltbot into **Alfred**, a digital butler you talk to on Telegram (`@Alfred_digital__butler`).

## Fresh machine (Linux Mint / Ubuntu)

Logged in as your normal user, open a terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/scottcarsten/moltbot/main/alfred/setup-fresh.sh | bash
```

It installs Node 22 + build tools, builds Moltbot from this fork, keeps it running when you log out or close the lid, then starts `moltbot onboard`. Have these ready:

- **Anthropic API key**: console.anthropic.com → API Keys (starts with `sk-ant-api`)
- **Telegram bot token**: @BotFather → `/mybots` → Alfred_digital__butler → API Token

Choose **Anthropic** as the provider and **Telegram** as the channel. The script then runs `apply.sh` (below). Reboot once so the lid setting takes effect, then message Alfred.

## Existing install

```bash
./alfred/apply.sh
```

Then in Telegram, send `/reset` once and ask: *"Alfred, who are you and who am I?"*

## What apply.sh changes

| Problem | Fix |
|---|---|
| Alfred called *you* "Alfred" | Agent identity set to Alfred 🎩; `IDENTITY.md` / `USER.md` seeded in the workspace from `*.template.md` (old copies backed up as `*.bak-<timestamp>`); first-run `BOOTSTRAP.md` retired |
| Should answer to "Alfred" | `groupChat.mentionPatterns` = `\b@?alfred\b` (case-insensitive). DMs always get a reply. In groups he replies when someone says "Alfred" |
| `permission denied ... docker.sock` | If Docker isn't reachable as your user, the sandbox is turned off; the script prints how to re-enable it |
| Pairing prompt | Your Telegram ID `8686303310` added to `channels.telegram.allowFrom` (override with `TELEGRAM_USER_ID=... ./alfred/apply.sh`) |

Safe to re-run. It doesn't touch model or API-key settings.

## Protect against bad updates

Before running updates, take a snapshot with **Timeshift** (built into Mint). If an update breaks boot, pick the snapshot from the Timeshift boot menu to roll back.
