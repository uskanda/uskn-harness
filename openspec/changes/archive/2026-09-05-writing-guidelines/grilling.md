# grilling 記録: writing-guidelines

本 change の決定はハーネス全体の grilling（`docs/proposal-2026-09.md` §10 第1〜3ラウンド）と共有理解（同 §12）で
確定済み。該当箇所の抜粋。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 文章指針のスタック | 日本語は textlint（preset-ja-technical-writing + preset-ai-writing）と `ja-writing` スキル。英語は agent-style の 21 ルールと humanizer | 第1ラウンド Q11 |
| 適用範囲 | コミット、PR、仕様、ドキュメント、UI 文言 | 第1ラウンド Q11 |
| 外部スキルの扱い | humanizer と agent-style は参照 + ピン（`deps.json`）。改変しない | 第1ラウンド Q3 |
| センサー | PreToolUse ではなく PostToolUse（Write / Edit）で `.md` に textlint を掛ける。hook は bash + jq、テストは bats | §12.3、第2ラウンド Q20 |
| 文体サンプル | 提供する。置き場は `assets/voice/` | 第3ラウンド Q27 |
| 言語の使い分け | スキルと内部文書は英語。チャット、コミット、PR、OpenSpec 成果物は日本語 | 第1ラウンド Q5 |

## 後回しにしたもの

- 文体基準（敬体と常体の使い分け、トーン）。§12.9 のとおりスキル作成時に短い grilling で決める。本 change では既存文書から読み取れる暫定基準をスキルに置き、確定は次の grilling に委ねる
- `assets/voice/` への実物のサンプル投入（private 前提。ユーザーが選ぶ）

## 状態

frontier は空。共有理解は 2026-09-05 に確認済み。
