## MODIFIED Requirements

### Requirement: プラグインの中身
`plugins/uskn-notify/` は、`.claude-plugin/plugin.json`、`hooks/hooks.json`、`bin/` を持たなければならない（MUST）。
`bin/` には次の7つのコマンドを置く。

- `claude-notify-hook`、`claude-notify`
- `claude-notify-telegram-bot`
- `claude-notify-speak` と、そのPowerShell版 `plugins/uskn-notify/bin/claude-notify-speak.ps1`
- `install-voicevox-engine` と、そのPowerShell版 `plugins/uskn-notify/bin/install-voicevox-engine.ps1`

送信の振る舞いは `telegram-notify-send`、受信と発話の振る舞いは `telegram-voice-receiver` が定める。

#### Scenario: symlink で読み込む
- **WHEN** `~/.claude/skills/uskn-notify` が `plugins/uskn-notify` へのsymlinkである
- **THEN** `claude plugin list` に `uskn-notify@skills-dir` が現れる

#### Scenario: 削除したコマンド
- **WHEN** `plugins/uskn-notify/bin/` を一覧する
- **THEN** `claude-notify-nag`、`claude-notify-daemon`、`claude-notify-ntfy-sub`、`claude-notify.ps1` は無い

### Requirement: コマンドの公開
syncは `plugins/uskn-notify/bin/` の各コマンドについて、`~/.local/bin/<name>` をそのコマンドへのsymlinkにしなければならない（MUST）。
同じ名前の実ファイルがあるときは上書きせず、`conflict` と報告する。終了コードは0のまま。
既にそのコマンドを指すsymlinkなら `ok` と報告する。

#### Scenario: 新しい WSL 端末
- **WHEN** 何も入っていないWSL端末でsyncを実行する
- **THEN** `~/.local/bin` に `claude-notify` と `claude-notify-hook` がsymlinkとして並ぶ。送信先を設定すれば `claude-notify` で投稿できる

#### Scenario: dotfiles のコピーが残っている
- **WHEN** `~/.local/bin/claude-notify` がdotfilesの置いた実ファイルとして存在する
- **THEN** ファイルはそのまま残り、`conflict` と報告される

### Requirement: 通知の秘密に触れない
syncは `~/.config/claude-notify/config.env` を作ってはならず、変更してはならない（MUST NOT）。
このファイルはユーザーが持ち、通知のコマンドが読む。
ファイルが無いとき、通知のコマンドは何も投稿せず、発話もしない。

#### Scenario: 秘密の無い端末
- **WHEN** `~/.config/claude-notify/config.env` が無い端末でsyncを実行する
- **THEN** ファイルは作られない。`claude-notify` は何も投稿せずに終了コード0で終わる

### Requirement: opt-in の常駐はユーザーが入れる
syncは、受信の常駐プロセスとVOICEVOX ENGINEを新しく入れてはならない（MUST NOT）。
これらはユーザーがコマンドを実行して入れる。
コマンドは `claude-notify-telegram-bot install` と `install-voicevox-engine` の2つ。

#### Scenario: 新しい macOS 端末
- **WHEN** LaunchAgentの無いmacOS端末でsyncを実行する
- **THEN** `~/Library/LaunchAgents` に通知のplistは作られない

### Requirement: シェルの検査
`make verify` は、`plugins/uskn-notify/bin/` のbashのスクリプトにshellcheckをかけなければならない（MUST）。
shebangがbashでないファイル（Pythonの `claude-notify-telegram-bot` とPowerShellの2つ）は対象から外す。

#### Scenario: 構文の誤り
- **WHEN** `claude-notify-hook` に閉じていない引用符を入れて `make verify` を実行する
- **THEN** shellcheckが失敗し、`make verify` も失敗する

#### Scenario: Python のコマンド
- **WHEN** `make verify` を実行する
- **THEN** `claude-notify-telegram-bot` はshellcheckに渡されない

## ADDED Requirements

### Requirement: 受信の常駐プロセスの LaunchAgent の入れ直し
入れ直しの対象は、LaunchAgent `com.claude.notify-telegram-bot` と、そのコマンド `claude-notify-telegram-bot` の1組である。
macOSでこのLaunchAgentのplistがあり、コマンドの中身が前回入れたときと違うとき、syncはコマンドの `install` を実行しなければならない（MUST）。
前回入れたときのコマンドの中身は、状態としてハッシュで残す。ハッシュが無いときは、違うものとして扱う。
入れ直したときは `updated`、中身が同じときは `ok` と報告する。

#### Scenario: コマンドが更新された
- **WHEN** plistがあり、記録したハッシュが今のコマンドの中身と違う
- **THEN** syncは `claude-notify-telegram-bot install` を実行し、ハッシュを記録して `updated` と報告する

#### Scenario: ハッシュの記録が無い
- **WHEN** plistがあり、ハッシュの記録が無い
- **THEN** syncはコマンドの `install` を実行し、ハッシュを記録して `updated` と報告する

#### Scenario: 変わっていない
- **WHEN** plistがあり、記録したハッシュが今の `claude-notify-telegram-bot` と同じ
- **THEN** `install` は実行されず、`ok` と報告される

#### Scenario: Linux
- **WHEN** Linuxでsyncを実行する
- **THEN** LaunchAgentの手順は実行されず、出力にも現れない

### Requirement: 古い LaunchAgent の片付け
古いLaunchAgentは、`com.claude.notify-daemon` と `com.claude.notify-ntfy-sub` の2つである。
macOSで古いLaunchAgentのplistがあるとき、syncはそのLaunchAgentを止めてplistを消し、`removed` と報告しなければならない（MUST）。
ハッシュの記録も消す。

#### Scenario: 前の構成から移る macOS 端末
- **WHEN** `~/Library/LaunchAgents/com.claude.notify-daemon.plist` がある端末でsyncを実行する
- **THEN** plistは消え、そのLaunchAgentは動いておらず、出力に `removed` がある

#### Scenario: 2 回目の sync
- **WHEN** 片付けの済んだ端末でもう一度syncを実行する
- **THEN** 古いLaunchAgentについての出力は無い

### Requirement: 消えたコマンドの symlink の片付け
消えたコマンドのsymlinkとは、`~/.local/bin` のsymlinkのうち、`plugins/uskn-notify/bin/` の下の存在しないファイルを指すものである。
syncは、消えたコマンドのsymlinkを消し、`removed` と報告しなければならない（MUST）。
実ファイルと、ハーネスの外を指すsymlinkには触らない。

#### Scenario: 削除したコマンド
- **WHEN** `~/.local/bin/claude-notify-nag` が、今は無い `plugins/uskn-notify/bin/claude-notify-nag` を指すsymlinkである
- **THEN** syncの後、そのsymlinkは無い

#### Scenario: 別の場所を指す、宛先の無い symlink
- **WHEN** `~/.local/bin/foo` が、ハーネスの外の存在しないファイルを指すsymlinkである
- **THEN** syncの後も、そのsymlinkは残る

### Requirement: checkout からの直接の実行
checkoutのパスから直接実行されたとき、通知のコマンドは、`~/.local/bin` のsymlinkから実行されたときと同じ振る舞いをしなければならない（MUST）。
コマンドは、隣のコマンドを自分のファイルの場所から探す。

#### Scenario: Windows ネイティブの hook
- **WHEN** `~/.local/bin` に通知のコマンドが無いWindowsで、hookがcheckoutの `claude-notify-hook done` を実行する
- **THEN** 種類 `done` のメッセージが1通投稿される

#### Scenario: Windows ネイティブの常駐
- **WHEN** Windowsでcheckoutの `claude-notify-telegram-bot install` を実行する
- **THEN** ログイン時の登録はcheckoutのパスを指し、発話には同じディレクトリのPowerShell版のコマンドが使われる

## REMOVED Requirements

### Requirement: 既存の LaunchAgent の入れ直し
**Reason**: 入れ直しの対象だった2つのLaunchAgentと、そのコマンドを削除する。対象は `com.claude.notify-daemon` と `com.claude.notify-ntfy-sub` である。
**Migration**: 入れ直しは、要件 `受信の常駐プロセスの LaunchAgent の入れ直し` が受け持つ。古い2つのLaunchAgentは、要件 `古い LaunchAgent の片付け` に従ってsyncが外す。
