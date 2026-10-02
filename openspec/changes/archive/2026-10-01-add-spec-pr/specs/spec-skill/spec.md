## MODIFIED Requirements

### Requirement: 実装に進まない
`spec` は成果物を作り終えたら停止し、実装は `/opsx:apply` に委ねなければならない（MUST）。

#### Scenario: 終了時
- **WHEN** tasks.mdまで作り終える
- **THEN** コードは変更されず、次の入口の案内で終わる

## ADDED Requirements

### Requirement: 終了時の案内
成果物を作り終えたとき、`spec` は実装の入口 `/opsx:apply <name>` と仕様PRの入口 `/spec-pr <name>` の両方を案内しなければならない（MUST）。
`spec` は自分から `spec-pr` を呼んではならない（MUST NOT）。

#### Scenario: 案内の中身
- **WHEN** `/spec add-x` がtasks.mdまで作り終える
- **THEN** 最後の報告に `/opsx:apply add-x` と `/spec-pr add-x` の両方があり、仕様PRはまだ作られていない
