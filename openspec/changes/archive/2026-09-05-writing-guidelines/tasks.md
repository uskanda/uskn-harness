## 1. textlint hook（TDD）

- [x] 1.1 `textlint-check.bats` を書き、RED を確認する。見るのは日本語 `.md` での指摘の返し方と、指摘なしの無出力
- [x] 1.2 同じ bats に無視の条件を足す。英語 `.md` と `.ts`、textlint 無し、`USKN_SKIP_TEXTLINT=1`、repo の `.textlintrc.json` の優先
- [x] 1.3 `textlint-check.sh` を実装して GREEN にする。shellcheck の警告はゼロ
- [x] 1.4 `hooks.json` に PostToolUse（timeout 30）を足し、`claude plugin validate --strict` を通す

## 2. installer（TDD）

- [x] 2.1 `uskn-harness.bats` に足して RED を確認する。見るのは stub ログの `npm install -g`、版が一致するときの省略、`doctor` の warn
- [x] 2.2 `deps.json` の `clis` を `package` / `version` / `bin` / `bundle` / `global` に揃える
- [x] 2.3 `ensure_npm_globals` と doctor の版確認を実装して GREEN にする

## 3. スキルと設定

- [x] 3.1 `skills/ja-writing/textlintrc.json` と `SKILL.md` を書く。SKILL.md には暫定基準、textlint の手順、指摘の直し方、voice の使い方を入れる
- [x] 3.2 `skills/en-writing/SKILL.md` を書く。適用範囲、`agent-style rules`、`review --audit-only`、humanizer と voice を入れる
- [x] 3.3 `assets/voice/README.md` を書き、`ja/` と `en/` の置き方を示す
- [x] 3.4 `templates/user/CLAUDE.md` に Writing 節を足す

## 4. 既存文書とセンサー

- [x] 4.1 `Makefile` に `verify-textlint` を足す。対象は README、docs/adr、openspec/specs、進行中の change。textlint が無ければスキップ
- [x] 4.2 README、ADR、main specs、進行中の change の textlint 指摘を直す
- [x] 4.3 このマシンで `uskn-harness sync` と `doctor` を実行し、textlint と agent-style が入ることを確認する
- [x] 4.4 README と `docs/proposal-2026-09.md` §15 に実装メモを書き、`make verify` を通してからコミットする
