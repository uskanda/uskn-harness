## 1. テスト（TDD）

- [x] 1.1 `bin/tests/archive-push-skill.bats` を書く。`skills/archive-push/SKILL.md` のfrontmatterを確かめる。確かめるのは `name: archive-push` と `disable-model-invocation: true` の2つ。走らせて失敗を確認する

## 2. 実装

- [x] 2.1 `skills/archive-push/SKILL.md` を `writing-for-agents` に従って英語で書く。本文はdesignの順番に沿う。コミット範囲の確認、未完了の項目の分類、1回目の検証、項目の更新、`openspec-archive-change` の呼び出しと答え、2回目の検証、`commit` への指示、`push`、報告の順である。designに挙げた3つの実例も載せる。1.1と `make verify-skills` が通ることを確認する

## 3. 文書

- [x] 3.1 `AGENTS.md` の「How work happens here」の手順4に、`/archive-push` がarchiveからpushまでを1回で行う旨を足す。terms checkが通ることを確認する
- [x] 3.2 `templates/user/CLAUDE.md` の「Deciding what to build」に、`/archive-push <change>` の1行を足す
- [x] 3.3 `README.md` の機能の表の「仕様づくり」の行に `skills/archive-push/` を足す。textlintとterms checkが通ることを確認する

## 4. 検証

- [x] 4.1 `openspec validate add-archive-push-skill --strict` と `make verify` が通ることを確認する
- [x] 4.2 `uskn-harness sync --dry-run` の計画に `archive-push` のリンクが出ることを確認する
