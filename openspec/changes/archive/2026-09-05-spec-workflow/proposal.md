## Why

仕様決定の前に grilling を通すことはハーネスの必須要件だが、現状はユーザー層の指示（推論的）だけで担保されている。OpenSpec の schema と hook で計算的に担保し、`/spec` 1 つで「grilling → 記録 → 成果物生成」まで通る入口を作る。

## What Changes

- OpenSpec schema `uskn`（`spec-driven` のフォーク）に `grilling` アーティファクトを追加し、proposal の前提にする。正本は `schemas/uskn/`、`sync` が `~/.local/share/openspec/schemas/uskn` へ symlink する
- このリポジトリの `openspec/config.yaml` と `templates/repo/openspec/config.yaml` は `schema: uskn` を選ぶ
- `spec` スキルを新設する。grilling を実行し、共有理解の確認後に change を作り、`grilling.md` を記録してから proposal / specs / design / tasks を生成する。`--step` で成果物ごとに確認を挟む
- PreToolUse hook `grilling-guard.sh` を追加する。`openspec/changes/<name>/` 配下の proposal / design / tasks / specs への書き込みを、`grilling.md` が無ければ拒否する
- `make verify` に `openspec schema validate uskn` を加える
- ユーザー層の指示（`templates/user/CLAUDE.md`）を `/spec` 前提の文言に更新する

## Capabilities

### New Capabilities
- `uskn-schema`: grilling を必須とする OpenSpec ワークフローの契約と、ユーザー層での提供
- `spec-skill`: `/spec` の外形的な振る舞い（インタビュー先行、記録、生成、`--step`）
- `grilling-guard`: grilling 記録の無い change への成果物書き込みを止める hook

### Modified Capabilities
- `harness-sync`: schema の symlink を導入・削除する要件を追加
- `harness-doctor`: schema の symlink を検査する要件を追加

## Impact

- 新規: `schemas/uskn/`, `skills/spec/`, `plugins/uskn-harness/hooks/scripts/grilling-guard.sh`, 同 tests, `templates/repo/openspec/config.yaml`
- 変更: `bin/uskn-harness`, `bin/tests`, `plugins/uskn-harness/hooks/hooks.json`, `Makefile`, `openspec/config.yaml`, `templates/user/CLAUDE.md`
- 依存: openspec 1.12（schema 機能は experimental）
