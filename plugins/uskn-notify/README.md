# uskn-notify (Claude Code plugin)

Spoken notifications for Claude Code. When Claude Code asks for confirmation or finishes a turn, the machine in
front of you says so, with the repository name first. It speaks through VOICEVOX when an engine answers on
`localhost:50021`, and through the OS voice otherwise.

Loaded as a skills-directory plugin: `uskn-harness sync` symlinks this directory to `~/.claude/skills/uskn-notify`
and each command in `bin/` to `~/.local/bin/<command>`. The commands came from the dotfiles (`uskanda/dotfiles`
`dot_local/bin/`) unchanged; ADR-0006 records the move.

- `hooks/hooks.json`: Notification runs `claude-notify-hook notification`, UserPromptSubmit runs
  `claude-notify-hook stop`, Stop runs `claude-notify-hook done`. Nothing goes into `~/.claude/settings.json`.
- `claude-notify-hook`: decides what to say from the hook's JSON, then calls `claude-notify` and `claude-notify-nag`
  from its own directory.
- `claude-notify [message]`: speaks the message. macOS uses VOICEVOX, then `say`. WSL and Git Bash hand the text to
  `claude-notify.ps1` on the Windows side (VOICEVOX, then SAPI). Over SSH or in a devcontainer it relays to the
  machine in front of you: the receiver on that machine first, then ntfy, then the terminal bell.
- `claude-notify-nag`: repeats a reminder until you answer, every `CLAUDE_NAG_INTERVAL` seconds (600 by default).
- `claude-notify-daemon`, `claude-notify-ntfy-sub`: the receivers for relayed messages (macOS).
- `install-voicevox-engine`: downloads and starts the VOICEVOX engine (macOS, about 1.8 GB).

## Settings

`~/.config/claude-notify/config.env` holds the relay settings. You write it on each machine; `uskn-harness sync`
never creates or changes it. Without it, the commands speak on the machine they run on and relay nothing. An empty
value turns that relay off.

```sh
CLAUDE_NOTIFY_TOKEN="..."         # shared token for the receiver on the machine in front of you
CLAUDE_NOTIFY_DAEMON_URL=""       # empty: derived from the environment (host.docker.internal, SSH tunnel)
CLAUDE_NTFY_URL=""                # self-hosted ntfy, the fallback relay
CLAUDE_NTFY_TOPIC=""
CLAUDE_NTFY_TOKEN=""
```

The voice reads `VOICEVOX_URL`, `VOICEVOX_SPEAKER`, and `VOICEVOX_QUERY_TIMEOUT` from the environment.

## Opt-in receivers (macOS)

`uskn-harness sync` never installs these. Run the command once on the machine that should speak:

```sh
claude-notify-daemon install      # LaunchAgent com.claude.notify-daemon: receives from SSH and devcontainers
claude-notify-ntfy-sub install    # LaunchAgent com.claude.notify-ntfy-sub: idles until CLAUDE_NTFY_URL is set
install-voicevox-engine           # the VOICEVOX engine on localhost:50021
```

Once a LaunchAgent is installed, `uskn-harness sync` installs it again whenever its command changes, so the running
receiver matches the plugin. The plist names `~/.local/bin/<command>`, not the harness checkout.

## Windows

Native Windows is outside the harness for now. The dotfiles keep a frozen copy of these commands for Windows, and a
later change decides how the harness covers it. WSL is covered: `claude-notify` speaks on the Windows host through
`claude-notify.ps1`, which sync links next to it.

## Checking

```sh
uskn-harness doctor                    # "notify command <name>" lines are ok
claude plugin list                     # uskn-notify@skills-dir is listed
claude-notify "test"                   # speaks on this machine
```
