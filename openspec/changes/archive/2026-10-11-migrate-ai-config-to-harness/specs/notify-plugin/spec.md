## Purpose

読み上げ通知のプラグインuskn-notify。
Claude Codeが確認を求めたときとturnが終わったときに、手元の端末で読み上げるhookとコマンドを配る。

## ADDED Requirements

### Requirement: プラグインの中身
`plugins/uskn-notify/` は、`.claude-plugin/plugin.json`、`hooks/hooks.json`、`bin/` を持たなければならない（MUST）。
`bin/` には次の7つのコマンドを置く。

- `claude-notify`、`claude-notify.ps1`、`claude-notify-hook`、`claude-notify-nag`
- `claude-notify-daemon`、`claude-notify-ntfy-sub`
- `install-voicevox-engine`

コマンドの振る舞いは、dotfilesが配っていたものと同じにする。

#### Scenario: symlink で読み込む
- **WHEN** `~/.claude/skills/uskn-notify` が `plugins/uskn-notify` へのsymlinkである
- **THEN** `claude plugin list` に `uskn-notify@skills-dir` が現れる

### Requirement: hook の配線
`hooks/hooks.json` は、3つのイベントに `claude-notify-hook` を登録しなければならない（MUST）。
Notificationには引数 `notification`、UserPromptSubmitには `stop`、Stopには `done` を渡す。
コマンドのパスは `${CLAUDE_PLUGIN_ROOT}` を起点にする。

#### Scenario: turn が終わる
- **WHEN** プラグインを読み込んだClaude Codeのturnが終わる
- **THEN** `claude-notify-hook done` が1回だけ実行される。ユーザー層のsettings.jsonにhookは無い

### Requirement: コマンドの公開
syncは `plugins/uskn-notify/bin/` の各コマンドについて、`~/.local/bin/<name>` をそのコマンドへのsymlinkにしなければならない（MUST）。
同じ名前の実ファイルがあるときは上書きせず、`conflict` と報告する。終了コードは0のまま。
既にそのコマンドを指すsymlinkなら `ok` と報告する。

#### Scenario: 新しい WSL 端末
- **WHEN** 何も入っていないWSL端末でsyncを実行する
- **THEN** `~/.local/bin` に `claude-notify` と `claude-notify.ps1` がsymlinkとして並ぶ。`claude-notify` はWindows側で発話できる

#### Scenario: dotfiles のコピーが残っている
- **WHEN** `~/.local/bin/claude-notify` がdotfilesの置いた実ファイルとして存在する
- **THEN** ファイルはそのまま残り、`conflict` と報告される

### Requirement: 通知の秘密に触れない
syncは `~/.config/claude-notify/config.env` を作ってはならず、変更してはならない（MUST NOT）。
このファイルはユーザーが持ち、通知のコマンドが読む。
ファイルが無いとき、通知のコマンドはリモートへ転送せず、手元で発話する。

#### Scenario: 秘密の無い端末
- **WHEN** `~/.config/claude-notify/config.env` が無い端末でsyncを実行する
- **THEN** ファイルは作られない。`claude-notify` は手元の発話を試みる

### Requirement: opt-in の常駐はユーザーが入れる
syncは、受信の常駐プロセス、ntfyの購読、VOICEVOX ENGINEを新しく入れてはならない（MUST NOT）。
これらはユーザーがコマンドを実行して入れる。
コマンドは `claude-notify-daemon install`、`claude-notify-ntfy-sub install`、`install-voicevox-engine` の3つ。

#### Scenario: 新しい macOS 端末
- **WHEN** LaunchAgentの無いmacOS端末でsyncを実行する
- **THEN** `~/Library/LaunchAgents` に通知のplistは作られない

### Requirement: 既存の LaunchAgent の入れ直し
macOSで通知のLaunchAgentのplistがあり、対応するコマンドの中身が前回入れたときと違うとき、syncはそのコマンドの `install` を実行しなければならない（MUST）。
対象は `com.claude.notify-daemon` と `com.claude.notify-ntfy-sub` の2つ。
前回入れたときのコマンドの中身は、状態としてハッシュで残す。ハッシュが無いときは、違うものとして扱う。
入れ直したときは `updated`、中身が同じときは `ok` と報告する。

#### Scenario: dotfiles から移る macOS 端末
- **WHEN** `~/Library/LaunchAgents/com.claude.notify-daemon.plist` があり、ハッシュの記録が無い
- **THEN** syncは `claude-notify-daemon install` を実行し、ハッシュを記録して `updated` と報告する

#### Scenario: 変わっていない
- **WHEN** plistがあり、記録したハッシュが今の `claude-notify-daemon` と同じ
- **THEN** `install` は実行されず、`ok` と報告される

#### Scenario: Linux
- **WHEN** Linuxでsyncを実行する
- **THEN** LaunchAgentの手順は実行されず、出力にも現れない

### Requirement: 取り除くときのコマンド
`sync --remove` のとき、syncは `~/.local/bin` の下のsymlinkのうち、`plugins/uskn-notify/bin/` を指すものを消さなければならない（MUST）。
実ファイルとハーネスの外を指すsymlinkには触らない。LaunchAgentは外さない。

#### Scenario: ハーネスを外す
- **WHEN** 通知のコマンドのsymlinkが `~/.local/bin` にある状態で `sync --remove` を実行する
- **THEN** symlinkは消え、`~/.local/bin` の他のファイルは残る

### Requirement: シェルの検査
`make verify` は、`plugins/uskn-notify/bin/` のbashのスクリプトにshellcheckをかけなければならない（MUST）。
shebangがbashでないファイル（Pythonの `claude-notify-daemon` とPowerShellの `claude-notify.ps1`）は対象から外す。

#### Scenario: 構文の誤り
- **WHEN** `claude-notify-hook` に閉じていない引用符を入れて `make verify` を実行する
- **THEN** shellcheckが失敗し、`make verify` も失敗する

#### Scenario: Python のコマンド
- **WHEN** `make verify` を実行する
- **THEN** `claude-notify-daemon` はshellcheckに渡されない
