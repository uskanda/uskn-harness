## ADDED Requirements

### Requirement: commit の直前の確認
commitの直前に呼ばれたとき、`verify` スキルは、Makefileに `verify-fast` があればそれを走らせなければならない（MUST）。
`verify-fast` が無いときは、検証規約を走らせる。
失敗したときは、commitをせずに、修正ループに従って直す。
Claude Code（2.1.286以降）は、ユーザー層の `verify` をcommitの直前に実行させるため。

#### Scenario: verify-fast のあるリポジトリ
- **WHEN** Makefileに `verify-fast` のあるリポジトリで、commitの直前に `verify` スキルが呼ばれる
- **THEN** `make verify-fast` が走り、`make verify` は走らない

#### Scenario: verify-fast の無いリポジトリ
- **WHEN** Makefileに `verify` だけがあるリポジトリで、commitの直前に `verify` スキルが呼ばれる
- **THEN** `make verify` が走る

### Requirement: commit の直前の結果は完了の根拠にしない
エージェントは、commitの直前に走らせた `verify-fast` の結果を、完了の根拠にしてはならない（MUST NOT）。
`verify-fast` は変わったファイルに関わる検査だけを走らせるため。

#### Scenario: commit の後の完了の報告
- **WHEN** commitの直前に `make verify-fast` だけを走らせ、続けて作業を終えたと言おうとする
- **THEN** エージェントは、同じターンで検証規約を走らせてから、その結果を先に示して報告する
