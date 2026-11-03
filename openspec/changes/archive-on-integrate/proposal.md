# Proposal

## Why

実装を終えた変更のarchiveは、ユーザーが `/archive-push` を打つまで行われない。
PR #16と#18はarchiveされないままマージされた。`openspec/changes/` には、doctor-probe-nested-usernsとsandbox-rules-revisitが残っている（issue #19）。
作業を終える操作のたびに、明示の宣言が無い限り、同時にarchiveする制約を加える。

## What Changes

- 統合の操作の前に、そのブランチが手を付けた未archiveの変更をarchiveする。統合の操作とは、`pr` のintegrationモードとcustomモード、統合ブランチか既定ブランチへの直接のpush、`gh pr merge` と `glab mr merge` である
- 判定を1つのコマンド `uskn-archive-check` にまとめる。hook、CI、スキルが同じものを呼ぶ
- `pr` と `push` は、未archiveの変更ごとに `archive-push` を呼んでから進む。`archive-push` から `disable-model-invocation` を外す
- archive保留の宣言として、変更のディレクトリに `.archive-later` を置けるようにする。宣言のある変更は判定から外す
- bash-guardが、未archiveの変更を持ったままの統合の操作を拒否する
- このリポジトリの `make verify` が、GitHub Actionsのdraftでないpull requestで、未archiveの変更を持ち込む差分を失敗にする
- 用語集に「統合の操作」と「archive保留の宣言」を足し、ADR-0014に方針を残す
- mainに残っているdoctor-probe-nested-usernsとsandbox-rules-revisitを、このブランチでarchiveする

対象外は次のとおり。uskn-loopの完了の扱い（変えない）、releaseモード、qaモード、`spec-pr`、製品リポジトリのCI。

## Capabilities

### New Capabilities

- なし

### Modified Capabilities

- `archive-push-skill`: 呼べる者に、統合の操作をするスキルを加える。archive保留の宣言のある変更を選ばない
- `git-workflow-skills`: `pr` と `push` が、統合の操作の前に未archiveの変更をarchiveする
- `bash-guard`: 未archiveの変更を持ったままの統合の操作を拒否する
- `ci-verify`: draftでないpull requestで、未archiveの変更を持ち込む差分を失敗にする
- `claude-plugin-packaging`: `bin/` に `uskn-archive-check` を足す

## Impact

- hook：`plugins/uskn-harness/hooks/scripts/archive-check.sh`（新規）と `bash-guard.sh`
- 短いコマンド：`plugins/uskn-harness/bin/uskn-archive-check`（新規）
- hookのテスト：`plugins/uskn-harness/hooks/tests/` の `archive-check.bats`（新規）、`bash-guard.bats`、`plugin-bin.bats`
- スキル：`skills/archive-push/SKILL.md`、`skills/git/pr/SKILL.md`、`skills/git/push/SKILL.md`
- スキルのテスト：`bin/tests/archive-push-skill.bats`、`bin/tests/skill-archive-on-integrate.bats`（新規）
- 検証：`Makefile` の `verify-archive`（新規）と `bin/tests/makefile.bats`
- 文書：`openspec/glossary.yml`、`README.md`、`docs/loop-engineering-2026-09.md`
- ADR：`docs/adr/0014-archive-on-integrate.md`（新規）
- archive：`openspec/changes/doctor-probe-nested-userns/` と `openspec/changes/sandbox-rules-revisit/`
