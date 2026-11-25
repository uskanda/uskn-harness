# Spec Delta

## ADDED Requirements

### Requirement: 閉じた環境では push の手前で止まる
`push`、`pr`、`release` は、リモートへ書く手順の前に、プラグインのコマンド `uskn-environment` を実行しなければならない（MUST）。
リモートへ書く手順とは、push、タグのpush、PRかMRの作成である。
出力が `confined` のとき、スキルはリモートへ書いてはならない（MUST NOT）。
そこまでの結果（ブランチ、コミット）と、pushとPRは外側が行うことを報告して終える。
`commit` はこの確認をせず、閉じた環境でもコミットする。

#### Scenario: 閉じた環境の pr
- **WHEN** 閉じた環境で、ユーザーが `/pr` を実行する
- **THEN** `git push` と `gh pr create` は実行されず、報告にブランチとコミットと、外側でpushする旨が載る

#### Scenario: 閉じた環境の commit
- **WHEN** 閉じた環境で、ユーザーが `/commit` を実行する
- **THEN** コミットが作られる
