# Tasks

## 1. verify スキル

- [x] 1.1 `bin/tests/verify-skill.bats` を先に書く。`skills/verify/SKILL.md` が、commitの直前に呼ばれたときの節を持つこと、その節が `verify-fast` を名指しすること、その結果を完了の根拠にしないと書くことを確かめる。走らせて失敗することを確かめる
- [x] 1.2 `skills/verify/SKILL.md` に、design.mdのD1とD2のとおりにcommitの直前の節を足す。1.1と `bin/tests/skill-*.bats` が通ることを確かめる

## 2. 文書

- [x] 2.1 `README.md` のverifyの説明に、Claude Code（2.1.286以降）がcommitの直前にこのスキルを呼び、`verify-fast` を走らせることを書く。textlintとterms-checkが通ることを確かめる

## 3. 統合

- [x] 3.1 `openspec validate verify-before-commit --strict` と `make verify VERIFY_STRICT=1` が通ることを確かめる
- [ ] 3.2 PRをmainへマージする
