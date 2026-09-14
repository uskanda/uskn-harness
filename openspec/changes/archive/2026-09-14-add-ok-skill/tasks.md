## 1. テスト（TDD）

- [x] 1.1 `bin/tests/ok-skill.bats` を書く。`skills/ok/SKILL.md` のfrontmatterに `name: ok` と `disable-model-invocation: true` があることを確かめる。走らせて失敗を確認する

## 2. 実装

- [x] 2.1 `skills/ok/SKILL.md` を `writing-for-agents` に従って英語で書く。承諾の範囲、上書きの扱いと曖昧なときの質問、名指しされた次の入力の実行、候補が複数のとき、呼べないスキルのとき、対象が無いときを含め、designに挙げた3つの実例を載せる。1.1と `make verify-skills` が通ることを確認する

## 3. 文書

- [x] 3.1 `templates/user/CLAUDE.md` の「Deciding what to build」に、提案は `/ok` で承諾でき、上書きを書き添えられる旨を1行足す
- [x] 3.2 `README.md` の機能の表の該当する行に `skills/ok/` を足す。textlintとterms checkが通ることを確認する

## 4. 検証

- [x] 4.1 `openspec validate add-ok-skill --strict` と `make verify` が通ることを確認する
- [x] 4.2 `uskn-harness sync --dry-run` の計画に `ok` のリンクが出ることを確認する
