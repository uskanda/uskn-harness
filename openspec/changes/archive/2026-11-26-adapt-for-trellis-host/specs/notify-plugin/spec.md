# Spec Delta

## MODIFIED Requirements

### Requirement: コマンドの公開
管理者の環境の間、syncは、通知の各コマンドについて `~/.local/bin/<name>` をそのコマンドへのsymlinkにしなければならない（MUST）。
通知のコマンドとは、`plugins/uskn-notify/bin/` の下のファイルである。
同じ名前の実ファイルがあるときは上書きせず、`conflict` と報告する。終了コードは0のまま。
既にそのコマンドを指すsymlinkなら `ok` と報告する。
閉じた環境では、通知のコマンドを置かない（harness-syncの要件「閉じた環境の通知」）。

#### Scenario: 新しい WSL 端末
- **WHEN** 何も入っていないWSL端末でsyncを実行する
- **THEN** `~/.local/bin` に `claude-notify` と `claude-notify.ps1` がsymlinkとして並ぶ。`claude-notify` はWindows側で発話できる

#### Scenario: dotfiles のコピーが残っている
- **WHEN** `~/.local/bin/claude-notify` がdotfilesの置いた実ファイルとして存在する
- **THEN** ファイルはそのまま残り、`conflict` と報告される

### Requirement: 既存の LaunchAgent の入れ直し
管理者の環境のmacOSで、syncは条件を満たすLaunchAgentのコマンドの `install` を実行しなければならない（MUST）。
条件は、通知のLaunchAgentのplistがあり、対応するコマンドの中身が前回入れたときと違うことである。
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

#### Scenario: 閉じた環境の macOS
- **WHEN** 閉じた環境のmacOSで、plistがありハッシュの記録が無い状態でsyncを実行する
- **THEN** `install` は実行されず、LaunchAgentの手順は出力に現れない
