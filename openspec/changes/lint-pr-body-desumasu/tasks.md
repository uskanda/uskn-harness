## 1. 敬体の設定

- [ ] 1.1 `bin/tests/ja-writing-rules.bats` に3つのテストを足し、失敗を確認する。1つ目は、`skills/ja-writing/textlintrc.desumasu.json` の `no-mix-dearu-desumasu` が本文と箇条書きに `"ですます"` を持つことである。2つ目は、2つの設定がその規則のほかは一致することである。3つ目は、敬体で書いたPR本文の例が、敬体の設定で文体の指摘を受けないことである
- [ ] 1.2 `skills/ja-writing/textlintrc.desumasu.json` を作る。1.1のテストが通ることを確認する

## 2. hook

- [ ] 2.1 `plugins/uskn-harness/hooks/tests/textlint-check.bats` にテストを足し、失敗を確認する。`<body>.pr.md` の形のファイルでは、リポジトリの `.textlintrc.json` があっても `--config` で敬体の設定が渡ることを確かめる
- [ ] 2.2 `plugins/uskn-harness/hooks/scripts/textlint-check.sh` を直し、2.1のテストと、普通の `.md` についての既存のテストが通ることを確認する

## 3. スキル

- [ ] 3.1 `bin/tests/ja-writing-rules.bats` にテストを足し、失敗を確認する。`skills/git/pr/SKILL.md` と `skills/spec-pr/SKILL.md` が、敬体の設定と `<body>.pr.md` の形の一時ファイルを使うことを確かめる
- [ ] 3.2 `skills/git/pr/SKILL.md` の「Japanese body」の節を直す。本文を `<body>.pr.md` の形の一時ファイルに書き、敬体の設定でlintする。3.1の `pr` についてのテストが通ることを確認する
- [ ] 3.3 `skills/spec-pr/SKILL.md` の手順4を直す。本文の一時ファイルとlintの写しを `<body>.pr.md` の形の名前にし、敬体の設定でlintする。3.1のテストが通ることを確認する
- [ ] 3.4 `skills/ja-writing/SKILL.md` の「Register」と「Check」の節に、2つの設定の使い分けと、PRとMRの本文を検査するコマンドを書く。`bin/tests/skill-*.bats` が通ることを確認する

## 4. 結合の確認

- [ ] 4.1 `openspec validate lint-pr-body-desumasu --strict` と `make verify` が通ることを確認する
