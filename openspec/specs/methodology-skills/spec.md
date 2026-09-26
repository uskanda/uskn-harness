# methodology-skills Specification

## Purpose
superpowersからforkした2つの方法論スキル（TDD、系統的デバッグ）の外形と、ハーネスへの適合点。

## Requirements

### Requirement: 出所の表記
forkした各スキルは、ディレクトリにupstreamのMITライセンス全文を置かなければならない（MUST）。
frontmatterには `license: MIT` を持つ。
本文の先頭には出所（obra/superpowersと版）と、変更点の要約を書く。
`deps.json` の `forks` は `mode: vendored` と `ref`、取り込み日を持つ。

#### Scenario: ライセンスの確認
- **WHEN** `skills/test-driven-development/` を見る
- **THEN** `LICENSE` があり、SKILL.mdのfrontmatterに `license: MIT` がある

### Requirement: ハーネスのスキル名で参照
forkしたスキルどうしの参照は `superpowers:` プレフィックスを持ってはならない（MUST NOT）。
参照はハーネスのスキル名で書く。例は `test-driven-development`、`systematic-debugging`、`verify`、`writing-for-agents`。

#### Scenario: systematic-debugging から TDD へ
- **WHEN** systematic-debuggingのPhase 4で失敗するテストを書く
- **THEN** 参照先は `test-driven-development` スキル

#### Scenario: 修正の確認
- **WHEN** systematic-debuggingのPhase 4で、修正が効いたと言う前に確認する
- **THEN** 参照先は `verify` スキル
