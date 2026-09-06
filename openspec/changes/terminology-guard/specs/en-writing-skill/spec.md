## ADDED Requirements

### Requirement: 名前と用語の規約
スキルは日本語と同じ名前の出所の規約を含まなければならない（MUST）。
英語の文章でも、実在しない名前と新しい略語を作らない。用語集は言語を問わず `openspec/glossary.yml`。

#### Scenario: 英語の文書
- **WHEN** 英語のREADMEやリリースノートを書く
- **THEN** 名前の出所は3つに限られ、実在検査の対象になる
