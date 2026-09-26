## MODIFIED Requirements

### Requirement: 出所の表記
方法論スキルは、ディレクトリにupstreamのMITライセンス全文を置かなければならない（MUST）。
frontmatterには `license: MIT` を持つ。
本文の先頭には出所（obra/superpowersと版）と、変更点の要約を書く。
`deps.json` の `forks` は `mode: vendored` と `ref`、取り込み日を持つ。
`forks` の各項目は、上流と分岐した日と、再取り込みしないことも記録する。

#### Scenario: ライセンスの確認
- **WHEN** `skills/test-driven-development/` を見る
- **THEN** `LICENSE` があり、SKILL.mdのfrontmatterに `license: MIT` がある

#### Scenario: 上流の新しい版
- **WHEN** superpowersの新しい版が出る
- **THEN** `deps.json` の `forks` の記録から、その版で本文を置き換えないと分かる。上流の改善は、ハーネスの本文へ個別に反映する

## ADDED Requirements

### Requirement: 肯定形の指示
方法論スキルの本文は、とるべき手順を肯定形で具体的に書かなければならない（MUST）。
RED、GREEN、REFACTORの手順と例、デバッグの4つの段階、参照ファイルへの導線は本文に残す。

#### Scenario: テストより先に書いたコード
- **WHEN** テストより先に書いたコードがある
- **THEN** `test-driven-development` は、そのコードを下書きとして脇に置き、テストを書いて失敗を見てから実装する手順を示す

#### Scenario: 3回の修正が効かない
- **WHEN** 3つ目の修正でも直らない
- **THEN** `systematic-debugging` は、設計を疑ってユーザーと相談する手順を示す

### Requirement: 強調と言い訳の表を持たない
方法論スキルの本文は、Iron Law、言い訳の表、Red Flagsの一覧、MANDATORYのような大文字の強調を含んではならない（MUST NOT）。
TodoWriteやtodoリストを使う指示も含んではならない（MUST NOT）。

#### Scenario: 検索
- **WHEN** 2つの `SKILL.md` をIron Law、Red Flags、MANDATORY、TodoWriteで検索する
- **THEN** 一致しない
