## 1. テンプレート

- [x] 1.1 `templates/repo/DESIGN.md` を Google 形式で書く。`designmd lint` のエラーが 0 であることを確認する
- [x] 1.2 `templates/repo/PRODUCT.md` を Impeccable の節構成で書く

## 2. installer と検証

- [x] 2.1 `uskn-harness.bats` に足して RED を確認する。見るのは stub ログの impeccable、frontend-design、`@google/design.md` の導入
- [x] 2.2 `deps.json` を更新して GREEN にする。impeccable は skills へ、designmd は clis へ移し、frontend-design に install を足す
- [x] 2.3 `Makefile` に `verify-design` を足す。designmd が無ければスキップ

## 3. スキルと導線

- [x] 3.1 `skills/ui-guidelines/SKILL.md` を書き、frontmatter 検査を通す
- [x] 3.2 `templates/user/CLAUDE.md` に UI の 1 行を足す
- [x] 3.3 このマシンで `uskn-harness sync` を実行し、impeccable、frontend-design、designmd が入ることを確認する
- [x] 3.4 README を更新し、`make verify` を通してからコミットする
