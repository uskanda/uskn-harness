# Proposal

## Why

Claude Codeのユーザー層は、dotfilesとハーネスの2か所から配られている。
settings.jsonと読み上げ通知はdotfilesが、スキルとhookはハーネスが配る。
この分担のため、端末で `/effort` を変えた値がdotfilesのテンプレートに取り込まれ、別の端末の値と衝突する。
`permissions.allow` の端末間の和集合も、dotfilesのスキルで手作業として続いている。
読み上げ通知はdotfilesの `.chezmoiignore` がWindows以外へ `dot_local/bin/claude-notify.ps1` を配らないので、新しいWSL端末では鳴らない。
Claude CodeとAI関連の設定の正本をハーネスにまとめ、dotfilesにはハーネスの導入とsyncの呼び出しだけを残す。

## What Changes

- ユーザー層の `~/.claude/settings.json` をハーネスが管理する。syncは設定断片 `templates/user/settings.json` と端末別設定をliveへマージする。前回の適用記録と3方向で比べ、ハーネスが入れて今は要らないものだけを消す
- effortは端末に残さない。設定断片は共通の既定値としてtop-levelの `effortLevel` だけを持つ。syncはliveの `modelSettings` からeffortを消す
- 新しいプラグイン `plugins/uskn-notify/` を作り、dotfilesの読み上げ通知のhook、スクリプト、VOICEVOXのインストーラを移す。通知の秘密は、ユーザーが持つ管理外の `~/.config/claude-notify/config.env` に置く
- syncは `plugins/` の下のプラグインをすべて `~/.claude/skills/<name>` へsymlinkする。通知のコマンドは `~/.local/bin` に公開する。macOSで受信のLaunchAgentが既にある端末では、syncが入れ直す
- dotfilesのスキルのうちcleanupとset-workspace-themeを英訳し、ハーネスのスキルに加える
- dotfilesのbootstrapを、`chezmoi apply` のたびに導入とsyncを行う `run_after_` のスクリプトに置き換える。run_onceの「1回だけ走る」という約束は無くなる（**BREAKING**）
- doctorはliveのsettings.jsonと、設定断片と端末別設定から求めた値とのずれを報告する
- ADR-0006を書き、過去の2つの決定を置き換える。ADR-0001は、chezmoi-merge、sync-claude-settings、set-workspace-theme、cleanupをdotfilesに残すと決めた。ADR-0002は、ハーネスがsettings.jsonに触らないと決めた
- dotfiles側の撤去と配線は、このchangeのtasksとしてdotfilesのmasterへ直接コミットする
- dotfilesはLinux、macOS、WSLでClaude Codeのユーザー層を配らなくなる（**BREAKING**）。WindowsネイティブのためのAI設定は、dotfilesに凍結して残す

対象外は次のとおり。ハーネスのWindowsネイティブ対応、ローカルLLMのスクリプト、opencodeの設定、Fusion MCP、Telegram経由の通知。

## Capabilities

### New Capabilities

- `user-settings`: ユーザー層の `~/.claude/settings.json` を、設定断片、端末別設定、適用記録の3つからsyncが作る規則。マージ、3方向の片付け、effortの消去、初回の扱い
- `notify-plugin`: 読み上げ通知のプラグインuskn-notify。hookの配線、通知のコマンドの公開、秘密の置き場、受信のLaunchAgentの入れ直し
- `utility-skills`: dotfilesから移す2つのスキル、cleanupとset-workspace-theme

### Modified Capabilities

- `harness-sync`: プラグインのsymlinkを `plugins/` の下のすべてに広げる。スキルの予約名をプラグインの名前全体にする。`--remove` で設定と通知のコマンドも取り除く
- `harness-doctor`: 検査項目にユーザー層の設定と通知のプラグインを足す。鮮度警告の設定は、dotfilesではなくsyncが書く
- `machine-bootstrap`: run_onceを、`chezmoi apply` のたびに導入とsyncを行う `run_after_` のスクリプトに置き換える
- `claude-plugin-packaging`: 構成と検証の要件を、`plugins/` の下の各プラグインに当てはめる

## Impact

ハーネスで変わるものは次のとおり。

- `bin/uskn-harness` のsyncとdoctor
- `templates/user/` の設定断片と初回用の写し、`templates/chezmoi/` のbootstrap
- `plugins/uskn-notify/` と、`skills/` に加える2つのスキル
- `Makefile` のshellcheckとプラグイン検証の対象、`bin/tests/`
- `docs/adr/`、`docs/setup-new-machine.md`、`README.md`、用語集

dotfilesで変わるものは次のとおり。

- `dot_claude/` を削除する
- `dot_local/bin/` の通知のスクリプトと `dot_config/claude-notify/` を、Windowsだけに配る
- `.chezmoiignore`、bootstrapと片付けのスクリプト、`setup` の通知の節
- プロジェクト層の `.claude/` を新しく置く
- `README.md`、`CLAUDE.md`、windows-voicevox.md、進行中のtelegramのchange

順序は、ハーネスのPRをマージしてからdotfiles側をコミットする。
逆にすると、dotfilesが古い通知のスクリプトを消した後も、liveの設定のhookがそのスクリプトを指したまま残る。
