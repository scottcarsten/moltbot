# Alfred

Config kit that turns this Moltbot install into **Alfred**, a digital butler you talk to on Telegram (`@Alfred_digital__butler`).

## Apply

On the machine running the gateway:

```bash
git pull
./alfred/apply.sh
```

Then in Telegram, send `/reset` once and ask: *"Alfred, who are you and who am I?"*

## What it changes

| Problem | Fix |
|---|---|
| Alfred called *you* "Alfred" | Agent identity set to Alfred 🎩; `IDENTITY.md` / `USER.md` seeded in the workspace (old copies backed up as `*.bak-<timestamp>`); first-run `BOOTSTRAP.md` retired |
| Should answer to "Alfred" | `groupChat.mentionPatterns` = `\b@?alfred\b` (case-insensitive). DMs always get a reply. In groups he replies when someone says "Alfred" |
| `permission denied ... docker.sock` | If Docker isn't reachable as your user, the sandbox is turned off; the script prints how to re-enable it |
| Pairing prompt | Your Telegram ID `8686303310` added to `channels.telegram.allowFrom` (override with `TELEGRAM_USER_ID=... ./alfred/apply.sh`) |

Safe to re-run. It doesn't touch model or API-key settings.
