## Why

ja-writingはPRとMRの本文を敬体と定めているが、textlintの設定は本文と箇条書きに「である調」を強制している。
そのため、`pr` と `spec-pr` が本文をlintすると、敬体で正しく書いても `no-mix-dearu-desumasu` の指摘が必ず出る。
`add-loop-run` の実装中に `spec-pr` で仕様PRを作ったときに見つかった。

## What Changes

- 敬体用の設定 `skills/ja-writing/textlintrc.desumasu.json` を足す。今の設定の写しで、`no-mix-dearu-desumasu` だけを、本文と箇条書きに敬体を求める値にする
- 2つの設定が文体の規則以外で一致することを、batsで確かめる
- textlintのhookは、名前が `<body>.pr.md` の形で終わるMarkdownに敬体の設定を使う。リポジトリに自前の `.textlintrc*` があっても同じとする
- `pr` と `spec-pr` は、PRとMRの本文を `<body>.pr.md` の形の一時ファイルに書き、敬体の設定でlintする
- ja-writingのスキルに、2つの設定の使い分けと確認のコマンドを書く
- 仕様、ADR、設計、コミットメッセージは、今の常体の設定のまま検査する

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

- `ja-writing-skill`: textlintの設定に敬体用の設定を加え、PRとMRの本文はそれで検査する
- `textlint-hook`: 名前が `<body>.pr.md` の形のMarkdownには、ハーネスの敬体の設定を使う
- `git-workflow-skills`: `pr` はPRとMRの本文を敬体の設定で確認する
- `spec-pr-skill`: `spec-pr` は仕様PRの本文を敬体の設定で確認する

## Impact

- 新規：`skills/ja-writing/textlintrc.desumasu.json`。ja-writingのスキルのディレクトリごと `uskn-harness sync` が配る
- 変更：textlintのhookの本体 `plugins/uskn-harness/hooks/scripts/textlint-check.sh`
- 変更：hookのテスト `plugins/uskn-harness/hooks/tests/textlint-check.bats`
- 変更：`skills/git/pr/SKILL.md`、`skills/spec-pr/SKILL.md`、`skills/ja-writing/SKILL.md`
- 変更：`bin/tests/ja-writing-rules.bats`
- 依存：textlintのプリセットは今のピンのままで、新しいパッケージは無い
