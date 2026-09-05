## Context

- `openspec schema fork spec-driven uskn` はプロジェクト内 `openspec/schemas/` に複製する。ユーザー層の `~/.local/share/openspec/schemas/` も解決対象なので、複製をハーネスの `schemas/uskn/` に移し、`sync` が symlink する（検証済み: `Source: user`）
- change ディレクトリの `.openspec.yaml` は作成時の schema 名を持つ。config を変えても既存 change は変わらない
- PreToolUse hook は `tool_input.file_path` を受け取る。相対パスは `cwd` 基準
- ユーザー層の `openspec-propose` スキルは `openspec new change` から始まるため、そのまま呼ぶと grilling を飛ばす。`spec` は自分で同じループ（`status --json` → `instructions <artifact> --json` → 書く）を回す

## Goals / Non-Goals

**Goals:**
- grilling を飛ばして成果物を作れないことを、schema と hook の二重で担保する
- `/spec` を仕様決定の唯一の入口にし、`/opsx:propose` は互換のために残す

**Non-Goals:**
- grilling スキル自体の改変（mattpocock/skills を参照のまま）
- 既存 change（Phase 0〜1 のもの）の schema 差し替え。すべて archive 済み

## Decisions

1. **schema の正本は `schemas/uskn/`、`openspec/schemas/` には置かない**。プロジェクト内に置くとプロダクト repo にも同じ複製が要る。ユーザー層 1 か所なら `sync` の更新だけで全 repo に効く
2. **`grilling` は `requires: []` の独立アーティファクト、`proposal.requires: [grilling]`**。specs / design / tasks の依存は変えない
3. **guard の判定はパスだけで行う**。対象: `openspec/changes/<name>/(proposal|design|tasks)\.md` と `openspec/changes/<name>/specs/…`。除外: `<name>` が `archive`、`grilling.md` 自身。`grilling.md` の存在確認は `cwd` から解決した絶対パスで行う。内容は見ない（空ファイルでも通す。内容の質は schema の instruction とレビューで担保）
4. **guard は deny のみ、`allow` は返さない**。判断を返さなければ通常の許可フローに流れるので、対象外では何も出力しない
5. **`spec` の引数**: 空なら何を作るか尋ねる。kebab-case 名または説明文。`--step` フラグ。既存 change 名なら継続。名前は説明文から導く（例: 「ユーザー認証を追加」→ `add-user-auth`）
6. **`spec` は grilling スキルを Skill ツールで呼ぶ**。インタビューの進め方は grilling に任せ、`spec` は「終了条件（frontier 空 + 確認）」「記録の書き方」「その後のループ」だけを持つ。記録は会話中に出した質問番号と回答から表を作る
7. **hooks.json は `Write|Edit|MultiEdit|NotebookEdit` を matcher にする**。将来の cross-repo ガードも同じ matcher で別スクリプトを並べる

## Risks / Trade-offs

- [schema 機能は experimental。openspec の更新で `schema.yaml` の形式が変わる] → `make verify` の `openspec schema validate uskn` で検知。`deps.json` の version をピン
- [`grilling.md` が空でも guard を通る] → 内容は schema の instruction と `spec` スキルが担保。形式監査は Phase 3 の textlint / lint で追加余地
- [`cwd` がサブディレクトリだと相対パスの解決を誤る] → `git rev-parse --show-toplevel` でルートを取り、`openspec/` を探す

## Migration Plan

1. schema と `sync` の変更を入れ、`openspec schema which uskn` を確認（済み）
2. hook と `spec` スキルを追加。既存の 4 change には `grilling.md` を置いた
3. 問題があれば hooks.json から guard の行を外す（schema のブロックは残る）
