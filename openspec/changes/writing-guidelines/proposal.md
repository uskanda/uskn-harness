## Why

ADR-0001 §11 は文章の指針を決めた。日本語は textlint と `ja-writing`、英語は agent-style と humanizer。
一方で指針そのものも、計算的センサーもまだ無い。
Phase 3 の最初の change として、日本語と英語の書き方をスキルにする。
あわせて、Markdown を書くたびに textlint が走る hook を足す。

## What Changes

- `ja-writing` スキルを追加する。日本語の暫定的な文体基準、textlint の使い方、典型的な指摘の直し方、`assets/voice/` の使い方を書く。textlint の設定は harness 側（`skills/ja-writing/textlintrc.json`）に置き、プロダクト repo には置かない
- `en-writing` スキルを追加する。英語の文章に agent-style の 21 ルールと humanizer を当てる手順を書く。使うコマンドは `agent-style rules` と `agent-style review --audit-only`
- 適用範囲は人が読む英語の文章に限る。エージェント向け文書は `writing-for-agents` に任せる
- PostToolUse hook `textlint-check.sh` を追加する。Write / Edit / MultiEdit で書かれた `.md` に日本語が含まれるとき textlint を実行し、指摘があれば `additionalContext` で返す。textlint が無い、`.md` でない、日本語が無い、`USKN_SKIP_TEXTLINT=1` のときは何もしない
- `uskn-harness sync` が textlint とプリセット、agent-style を `deps.json` のピンで global に入れ、`doctor` が版を確認する
- `make verify` に `verify-textlint` を足す（README、ADR、main specs、進行中の change）。既存文書の指摘を直す
- `assets/voice/` に README を置き、サンプルの置き方を書く
- ユーザー層 `CLAUDE.md` に Writing 節を足す

## Capabilities

### New Capabilities
- `ja-writing-skill`: 日本語文章の指針スキルと textlint 設定の所在
- `en-writing-skill`: 英語文章の指針スキル（agent-style と humanizer への導線）
- `textlint-hook`: Markdown 書き込み後の textlint センサー

### Modified Capabilities
- `harness-sync`: npm global の CLI（textlint、プリセット、agent-style）をピンで入れる
- `harness-doctor`: 同 CLI の版を報告する
- `user-layer-instructions`: Writing 節（日本語は ja-writing、英語は en-writing、hook の指摘は直してから終える）

## Impact

- 新規: `skills/ja-writing/`（SKILL.md と textlintrc.json）、`skills/en-writing/SKILL.md`、`assets/voice/README.md`
- 新規: `plugins/uskn-harness/hooks/scripts/textlint-check.sh` と、その bats
- 変更: `bin/uskn-harness` と bats、`deps.json`、`Makefile`、`plugins/uskn-harness/hooks/hooks.json`
- 変更: `templates/user/CLAUDE.md`、README、既存の日本語文書（textlint の指摘の修正）
- 実行時間: textlint は 1 ファイル 1〜2 秒。hook の timeout は 30 秒
