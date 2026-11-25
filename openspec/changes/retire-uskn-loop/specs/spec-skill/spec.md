## MODIFIED Requirements

### Requirement: 終了時の案内
成果物を作り終えたとき、`spec` は実装の入口 `/opsx:apply <name>` を案内しなければならない（MUST）。
`spec` は自分から実装を始めてはならない（MUST NOT）。

#### Scenario: 案内の中身
- **WHEN** `/spec add-x` がtasks.mdまで作り終える
- **THEN** 最後の報告に `/opsx:apply add-x` があり、実装はまだ始まっていない
