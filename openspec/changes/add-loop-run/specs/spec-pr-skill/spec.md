## ADDED Requirements

### Requirement: ループの案内
`spec-pr` は、仕様PRの本文の進め方に、ループでの実装として `uskn-loop run <このPRの番号>` を示さなければならない（MUST）。

#### Scenario: 本文の進め方
- **WHEN** `uskn-loop` が導入された環境で `/spec-pr add-x` を実行する
- **THEN** 仕様PRの本文の進め方に `uskn-loop run` の行がある

#### Scenario: センサー
- **WHEN** `make verify` を実行する
- **THEN** batsのテストが、`spec-pr` の本文の雛形に `uskn-loop run` があることを確かめる
