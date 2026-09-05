## Why

ADR-0001 の実装フェーズ 4 は `onboard-harness` とプロダクト repo への導入。
ハーネスは揃ったが、プロダクト repo 側に何を置き、何を置かないかの手順がまだ無い。
monolith と uskn75-kb は性質が違う。片方は Expo アプリ、もう片方は UI とビルドを持たない資料 repo で、
「5 点セット」をそのまま当てると噛み合わない。

## What Changes

- `onboard-harness` スキルを追加する。プロダクト repo を読み、置くべきものを判定し、テンプレートから配置し、AGENTS.md を製品固有の事実だけに圧縮する手順を持つ
- `uskn-harness onboard-check <dir>` を追加する。読み取り専用で、5 点の有無、`schema: uskn`、検証規約、ユーザー層スキルとの重複を報告する
- `templates/repo/CLAUDE.md` と `templates/repo/Makefile` を追加する。プロダクト repo に置く最小の Claude 向け指示と verify ターゲット
- 5 点セットが「置けるものの上限」であって義務ではないことを、`AGENTS.md` と ADR-0001 §12.1 に明記する
- monolith と uskn75-kb 向けの手順書を `docs/handoffs/` に書き、同じ内容を持つ draft PR を各 repo に出す

## Capabilities

### New Capabilities
- `onboard-skill`: プロダクト repo にハーネスを導入する手順
- `onboard-check`: 導入状態を読み取り専用で点検するコマンド
- `repo-templates`: プロダクト repo に置く CLAUDE.md と verify ターゲットのテンプレート

### Modified Capabilities
- `design-templates`: DESIGN.md と PRODUCT.md は UI を持つプロダクトにだけ置く

## Impact

- 新規: `skills/onboard-harness/SKILL.md`、`templates/repo/CLAUDE.md`、`templates/repo/Makefile`
- 新規: `docs/handoffs/` に手順書 2 件
- 変更: `bin/uskn-harness` と bats、`AGENTS.md`、`docs/adr/0001-harness-architecture.md`
- 外部: monolith と uskn75-kb に draft PR を 1 本ずつ。マージはユーザーが他作業の目処を見て判断する
