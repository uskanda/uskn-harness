## 1. テスト（TDD）

- [x] 1.1 `grilling-guard.bats` の拒否のテストに、理由へ `no-grilling` が含まれることの確認を足す。走らせて失敗を確認する

## 2. 実装

- [x] 2.1 `grilling-guard.sh` の拒否理由に、ユーザーの指示があればno-grillingスキルで省略できる旨を足す。1.1とshellcheckが通ることを確認する
- [x] 2.2 `skills/no-grilling/SKILL.md` を `writing-for-agents` に従って英語で書く。確認の取り方、省略記録の形、既存の `grilling.md` を上書きしないこと、`spec` の手順4と5への参照、簡単な改修の例、省略記録の実例を含める。`make verify-skills` が通ることを確認する

## 3. 文書

- [x] 3.1 `AGENTS.md` の「How work happens here」の最初の項目に、ユーザーの指示でno-grillingを使える旨を1行足す。terms checkが通ることを確認する
- [x] 3.2 `templates/user/CLAUDE.md` の「Deciding what to build」に同じ旨を1行足す
- [x] 3.3 `README.md` の機能の表の「仕様づくり」の行に `skills/no-grilling/` を足す。textlintが通ることを確認する

## 4. 検証

- [x] 4.1 `openspec validate add-no-grilling-skill --strict` と `make verify` が通ることを確認する
- [x] 4.2 `uskn-harness sync --dry-run` の計画に `no-grilling` のリンクが出ることを確認する
