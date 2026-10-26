# Proposal

## Why

ADR-0009でsandboxを入れた後、実際の作業で6つの制約に当たった。gitの上流の設定、キャッシュへの書き込み、この端末自身のIPに解決されるホストへの接続、入れ子の `claude -p` などである。
sandboxが役に立つのは、中身を前もって読めない実行（スクリプト、ビルド、テスト）が、間接にルートの外へ書くのを止めるときである。
効果がコマンドの形で決まるよく知られた道具は、bash-guardとauto modeのclassifierが判断できる。
sandboxに残すのを前者だけに絞り、制約を減らしつつ、間接の書き込みを止める利点を残す。

## What Changes

- 設定断片の `sandbox.excludedCommands` の既定値を、11個の道具にする。`git`、`gh`、`glab`、`docker`、`mise`、`claude`、`uskn-harness`、`uskn-loop`、`chezmoi`、`ssh`、`scp` である。gitの6つの下位コマンドは `git *` にまとめる
- 設定断片の `sandbox.filesystem.allowWrite` を、キャッシュとツールのデータのディレクトリに広げる。`denyWrite` でハーネスの状態ディレクトリを禁止する
- syncは、`sandbox.excludedCommands` と `sandbox.filesystem.allowWrite` を集合として扱う。端末で足した要素が、次のsyncで消えなくなる
- 新しい下位コマンド `uskn-harness sandbox-exclude` が、端末別設定の `sandbox.excludedCommands` にパターンを足し、外し、一覧を出す
- 新しいスキル `sandbox-exclude` は、ユーザーだけが起動でき、その下位コマンドを呼ぶ
- bash-guardは、sandboxの外に出す道具がコマンドの途中にあるとき、`additionalContext` で単独での実行を促す。一覧はliveの設定から読む
- terms-checkは、名前の実在を通常のファイルとディレクトリだけで数え、sandboxが被せる空のファイルに惑わされなくなる
- ADR-0011を書き、ADR-0009の決定3と4を差し替える

## Capabilities

### New Capabilities

- `sandbox-exclude-skill`: sandboxの外で動かすコマンドを、ユーザーが端末に足すスキル

### Modified Capabilities

- `user-settings`: sandboxの外に出す道具の既定値、書ける範囲、集合として扱う配列
- `bash-guard`: 途中に出てくる外の道具を知らせる
- `terminology-guard`: 名前の実在の数え方
- `harness-sync`: `sandbox-exclude` の下位コマンド

## Impact

- 設定断片：`templates/user/settings.json`、`bin/tests/user-settings.bats`
- sync：`bin/uskn-harness`、`bin/tests/uskn-harness.bats`
- `plugins/uskn-harness/hooks/scripts/bash-guard.sh`、`terms-check.sh` と、それぞれのbats
- `skills/sandbox-exclude/SKILL.md` とそのbats
- ADR：`<docs/adr/0011-narrow-sandbox-scope.md>`、`docs/adr/0009-bash-sandbox.md`
- 文書：`docs/setup-new-machine.md`、`README.md`
- このchangeは、`adopt-bash-sandbox` と `add-dir-records-allow` のarchiveの後にarchiveする。この順にするのは、`user-settings` のdeltaが2つの足す要件を変えるため
