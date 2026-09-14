## 1. session-start.sh

- [x] 1.1 `session-start.bats` に保護ブランチの宣言のテストを足し、`bats` で新しいテストが失敗することを確かめる。対象は `none`、パターンの空白の除去、宣言無し、`--json` の2つのキー、jqの無い環境、`--plain branches` の4行
- [x] 1.2 `session-start.sh` で `protected` キーを読み、`<repo-context>` と `--json` に出す。1.1のテストと既存のテストがすべて通ることを `bats` で確かめる

## 2. スキルとテンプレート

- [x] 2.1 `skills/git/push/SKILL.md` の手順3の先頭に、`<repo-context>` の宣言で判定する段を足し、報告の根拠に加える。本文を読み、宣言がある場合にツール呼び出しの指示が無いことを確かめる
- [x] 2.2 `templates/repo/AGENTS.md` の `## Branch model` の例と説明に `protected` を加える。テンプレートの例を `session-start.sh --json` に通して `protected` が読めることを確かめる
- [x] 2.3 `skills/onboard-harness/SKILL.md` の手順3と `templates/user/CLAUDE.md` の説明に保護ブランチの宣言を加え、差分で確かめる

## 3. このリポジトリと検証

- [x] 3.1 `gh api` でこのリポジトリの `main` の保護状態を確かめ、`AGENTS.md` に `## Branch model` と `protected` を書く。`session-start.sh` の出力に宣言が出ることを確かめる
- [x] 3.2 `make verify` が通ることを確かめる
