# Proposal

## Why

change `adopt-bash-sandbox` の後、ルートの外で作業するとき、ユーザーは `/allow-repo <path>` と `/add-dir <path>` の2つを打つ。
`/allow-repo` はwrite-guardとbash-guardが読む許可ファイルに記録し、`/add-dir` はsandboxの中のBashの書き込み先を足す。
Claude Codeの `DirectoryAdded` のhookを使うと、`/add-dir` だけで許可ファイルにも記録できる（issue #6）。

## What Changes

- 新しいhookが `DirectoryAdded` で、追加されたディレクトリをセッションの許可ファイルに記録する。記録したパスを `systemMessage` で知らせる
- `/allow-repo` スキルを削除する（**BREAKING**）。`allow-repo.sh` は、許可ファイルへの記録と `--list` のために残す
- write-guardとbash-guardの拒否の理由を、ユーザーが `/add-dir <path>` を実行する案内に変える
- 設定断片の `sandbox.excludedCommands` から `allow-repo.sh` のパターンを外す
- ADR-0010を書き、ADR-0009の決定7を差し替える

## Capabilities

### New Capabilities

- `directory-added-hook`: `DirectoryAdded` で許可ファイルに記録するhook

### Modified Capabilities

- `allow-repo-skill`: スキルの要件をすべて削除する
- `write-guard`: 拒否の理由の案内を `/add-dir` に変える
- `bash-guard`: chezmoiの拒否の解除と、許可ファイルの保護の理由を `/add-dir` に変える
- `claude-plugin-packaging`: `DirectoryAdded` のhookの配線を足す
- `user-settings`: `excludedCommands` から `allow-repo.sh` を外す

## Impact

- `plugins/uskn-harness/hooks/hooks.json`、新しいhookのスクリプトとbats
- `plugins/uskn-harness/hooks/scripts/write-guard.sh`、`bash-guard.sh`、`allow-repo.sh` の説明
- `skills/allow-repo/` と `bin/tests/allow-repo-skill.bats` の削除
- `templates/user/settings.json`、`bin/tests/user-settings.bats`
- `docs/adr/`、`README.md`、`docs/setup-new-machine.md`、`templates/user/CLAUDE.md`、`AGENTS.md` の `/allow-repo` の記述
- このchangeは `adopt-bash-sandbox` の後にarchiveする。`user-settings` のdeltaが、`adopt-bash-sandbox` で足す要件を変えるため
