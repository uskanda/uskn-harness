## 1. onboard-check（TDD）

- [x] 1.1 `uskn-harness.bats` に `onboard-check` の RED を書く。未導入の repo で全項目が warn、導入済みで ok、終了コードは常に 0
- [x] 1.2 書き込みをしないことと、UI 判定（`package.json` の依存）の RED を書く
- [x] 1.3 `onboard-check` を実装して GREEN にする。shellcheck の警告はゼロ

## 2. テンプレートとスキル

- [x] 2.1 `templates/repo/CLAUDE.md` を書く。`@AGENTS.md` と Claude 固有の数行だけ
- [x] 2.2 `templates/repo/Makefile` を書く。各チェックは道具が無ければスキップする
- [x] 2.3 `skills/onboard-harness/SKILL.md` を書き、frontmatter 検査を通す

## 3. 「上限」の明記

- [x] 3.1 `AGENTS.md` の Hard constraints を「置けるものの上限」に直す
- [x] 3.2 ADR-0001 §1 の原則 3 を同じ趣旨に直す

## 4. プロダクト repo への draft PR

- [x] 4.1 `docs/handoffs/2026-09-05-monolith.md` を書く。置くもの、verify、AGENTS.md の圧縮候補、DESIGN.md の作り方
- [x] 4.2 `docs/handoffs/2026-09-05-uskn75-kb.md` を書く。指示ファイルの移動と verify
- [x] 4.3 monolith へ draft PR を出す。base は `master`、ブランチは `harness/onboard`
- [x] 4.4 uskn75-kb へ draft PR を出す。base は `main`、ブランチは `harness/onboard`
- [x] 4.5 uskn75-kb の origin が 7 コミット遅れていたので、指示ファイルの移動を PR から外し、手順書に移した

## 5. 仕上げ

- [x] 5.1 `Makefile` の textlint 対象に `docs/handoffs/` を足す
- [ ] 5.2 README を更新し、`make verify` を通してからコミットする
