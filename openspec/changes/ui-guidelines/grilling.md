# grilling 記録: ui-guidelines

本 change の決定はハーネス全体の grilling（`docs/proposal-2026-09.md` §10 第1〜2ラウンド）と共有理解（同 §12）で
確定済み。該当箇所の抜粋。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| UI 指針のスタック | Google DESIGN.md + Impeccable + Expo 公式 skills | 第1ラウンド Q10 |
| DESIGN.md の形式 | Google 形式（YAML トークン + 根拠の prose）を正本。Impeccable は `init` を使わずコマンド（audit / critique / polish など）だけ使う。RN / Expo は Expo 公式 skills と DESIGN.md の prose で補う | 第2ラウンド Q21 |
| フォールバック | Anthropic frontend-design | §12.7 |
| 外部スキルの扱い | Impeccable、expo/skills、frontend-design は参照 + ピン（`deps.json`）。改変しない | 第1ラウンド Q3 |
| プロダクト repo に置くもの | `DESIGN.md` と `PRODUCT.md`（`AGENTS.md`、`CLAUDE.md`、`openspec/` と合わせて 5 点）。それ以外は installer 経由 | §12.1 |

## 後回しにしたもの

- Expo 公式 skills のプロジェクト導入は Phase 4（`onboard-harness`）で行う。本 change は手順を `ui-guidelines` に書くだけ
- Impeccable の `document` / `extract` が生成する独自形式の DESIGN.md との整合。本 change では「使わないコマンド」として扱う

## 状態

frontier は空。共有理解は 2026-09-05 に確認済み。
