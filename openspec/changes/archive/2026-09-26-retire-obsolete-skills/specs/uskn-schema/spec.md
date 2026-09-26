## ADDED Requirements

### Requirement: 上流の案内文への追従
`uskn` schemaの生成指示は、`deps.json` でピンしたopenspecの版に同梱の `spec-driven` から、案内文の改善を取り込まなければならない（MUST）。
`grilling` 成果物、EARS記法の型、日本語の記録テンプレートなど、`uskn` 独自の部分は残す。
1.13.2の時点で取り込むのは次のとおり。

- proposal：既存のspecを `openspec list --specs` と `openspec show <spec-id> --type spec` で調べてから、能力を決める
- specs：変更する能力のパスを `openspec list --specs` で確かめてから、deltaを書く
- tasks：`- [~]` などの `x` 以外の印は未完了と読む。番号付きの各節は、自分の作業に要るテストと文書を同じ節で作る
- テンプレート：proposal、design、specs、tasksの先頭に、成果物の種類を示す見出しを置く

#### Scenario: proposal の指示
- **WHEN** `uskn` のchangeで `openspec instructions proposal --change <name>` を実行する
- **THEN** 指示に `openspec list --specs` と `--type spec` が含まれる

#### Scenario: tasks の指示
- **WHEN** `uskn` のchangeで `openspec instructions tasks --change <name>` を実行する
- **THEN** 指示に、テストと文書を最後の節にまとめないことが含まれる
