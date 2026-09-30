## 1. テスト（TDD）

- [ ] 1.1 `bin/tests/spec-pr-skill.bats` を書く。`skills/spec-pr/SKILL.md` のfrontmatterで2点を確かめる。`name: spec-pr` であることと、`disable-model-invocation: true` が無いことである。走らせて失敗を確認する

## 2. 実装

- [ ] 2.1 `skills/spec-pr/SKILL.md` を `writing-for-agents` に従って英語で書く。手順の順番はdesignのDecisionsのとおりで、確認をすべてブランチの作成より前に置く。designに挙げた2つの実例も載せる。1.1、`bin/tests/skill-invocation.bats`、`make verify-skills` が通ることを確認する
- [ ] 2.2 `skills/spec/SKILL.md` の終了の節に2行を足す。`/opsx:apply <name>` と並べて `/spec-pr <name>` を案内する行と、`spec-pr` を自分から呼ばない旨の行である。`bin/tests/skill-*.bats` が通ることを確認する

## 3. 文書

- [ ] 3.1 `README.md` の機能の表の「仕様づくり」の行に `skills/spec-pr/` を足す。textlintとterms checkが通ることを確認する

## 4. 検証

- [ ] 4.1 `openspec validate add-spec-pr --strict` と `make verify` が通ることを確認する
- [ ] 4.2 `uskn-harness sync --dry-run` の計画に `spec-pr` のリンクが出ることを確認する
- [ ] 4.3 `/spec-pr add-loop-run` をユーザーが実行し、draft PRのブランチ、コミットの範囲、本文、自動マージが無いことを確かめる
