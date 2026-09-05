## ADDED Requirements

### Requirement: npm global CLI の版の確認
`doctor` は `deps.json` の `clis` の各項目について、入っている版がピンと一致すれば `ok`、無いか異なれば `warn` を報告しなければならない（MUST）。

#### Scenario: 版の不一致
- **WHEN** textlint 15.0.0 が入っていて `deps.json` は 15.8.0 を指す
- **THEN** `warn` に両方の版が含まれる
