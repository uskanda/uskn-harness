# grilling 記録: spec-workflow

本 change の決定は Phase 2 の grilling（`docs/proposal-2026-09.md` §14 第6ラウンド）と、ハーネス全体の
grilling（同 §10）で確定済み。該当箇所の抜粋。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 仕様決定の必須ゲート | grilling を通してから OpenSpec の成果物を作る | 第1ラウンド Q6 |
| ゲートの構成 | uskn schema で `grilling` を proposal の前提にし、PreToolUse Write/Edit で `grilling.md` 無しの成果物書き込みを deny | 第6ラウンド Q44 |
| `spec` スキルの流れ | grilling → `openspec new change` → grilling.md → 一括生成。`--step` で段階生成 | 第3ラウンド Q25 |
| schema の配置 | `schemas/uskn/` を正本に `sync` が `~/.local/share/openspec/schemas/uskn` へ symlink。repo は `config.yaml` の `schema: uskn` | 第2ラウンド Q16、第6ラウンド前提 |
| grilling.md の形式 | 決定 / 選択 / 出典の表 + 後回し + frontier 空の確認 | 第6ラウンド前提 |

## 後回しにしたもの

- OpenSpec profile の expanded 化（`openspec config profile`）は導入時の手作業。自動化は要望が出てから

## 状態

frontier は空。共有理解は 2026-09-05 に確認済み。
