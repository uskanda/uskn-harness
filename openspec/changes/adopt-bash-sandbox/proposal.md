# Proposal

## Why

bash-guardは、プロジェクトのルートの外へ書くBashのコマンドに警告を出す。警告の判定は、コマンドの文字列からの推測である。
`$` で始まる語、スクリプトの中の書き込み、`make` などが間接に書く場合を見逃し、見つけても警告するだけで止めない。
Claude Codeのsandboxを使うと、Bashの書き込み先をOSのレベルで作業ディレクトリと追加したディレクトリに限れる。
推測による警告は、sandboxによる制限で置き換える（issue #5）。

## What Changes

- 設定断片 `templates/user/settings.json` に `sandbox` を足し、全端末でsandboxを有効にする。`failIfUnavailable` は `false`、`allowUnsandboxedCommands` は `true` にする
- `sandbox.excludedCommands` に `allow-repo.sh`、`uskn-harness`、`chezmoi` を並べ、sandboxの外で動かす
- `sandbox.filesystem.allowWrite` に、キャッシュの `~/.npm`、`~/.cache`、`~/.local/share/mise` を足す
- 設定断片の `permissions.allow` に `WebFetch(domain:*)` を足し、調査などでの外部への接続を、ドメインごとの確認なしに通す。Bashの接続先も全ホストにならなければ、`sandbox.network.allowedDomains` にホストの一覧を足す
- bash-guardのwarnパターン（ルートの外への書き込みの警告）を削除する（**BREAKING**）。denyパターンと、許可ファイルとverify gateの状態ファイルの保護は残す
- `uskn-harness doctor` が、sandboxを有効にしたLinuxとWSL2の端末で、`bwrap` か `socat` が無いときに `warn` を出す。syncはどちらもインストールしない
- `/allow-repo` は、許可を記録した後に、続けて `/add-dir <path>` を打つようユーザーに案内する。sandboxの中のBashがそのパスへ書けるようにするため
- ADR-0009を書き、sandboxを採用した理由と捨てた案を残す

対象外は次のとおり。

- `/allow-repo` と `/add-dir` を1つにまとめること（issue #6）
- `allowUnsandboxedCommands: false` による、sandboxの外での再実行の禁止
- WindowsネイティブでのBashの制限

## Capabilities

### New Capabilities

- なし

### Modified Capabilities

- `bash-guard`: warnパターンの要件を削除する。Purposeを、拒否だけを受け持つhookに書き直す
- `user-settings`: 設定断片が持つ `sandbox` の値と、`permissions.allow` の `WebFetch(domain:*)` を足す
- `harness-doctor`: sandboxの依存の検査を足す
- `allow-repo-skill`: 許可の後の `/add-dir` の案内を足す

## Impact

- `templates/user/settings.json` と、そのbats
- `plugins/uskn-harness/hooks/scripts/bash-guard.sh` と `plugins/uskn-harness/hooks/tests/bash-guard.bats`
- `bin/uskn-harness` のdoctorと、そのbats
- `skills/allow-repo/SKILL.md`
- `docs/adr/0009-bash-sandbox.md`、`docs/setup-new-machine.md`、`README.md`、`openspec/known-names.txt`
- 各端末：Linuxの端末には、ユーザーが `bubblewrap` と `socat` を入れる。`bwrap` の無い端末では、Bashは今までどおり制限なしで動く
- `uskn-loop` の実装役と監査役のセッションもsandboxの中で動く。作業はルートの中のworktreeで行うため、影響は無い見込みである
