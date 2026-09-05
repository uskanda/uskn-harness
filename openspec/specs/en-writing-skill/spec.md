# en-writing-skill Specification

## Purpose
人が読む英語の文章にagent-styleの21ルールとhumanizerを当てる手順を置くスキル。エージェント向け文書は対象外。

## Requirements

### Requirement: 適用範囲
`en-writing` スキルは、人が読む英語の文章を対象としなければならない（MUST）。
対象は英語プロジェクトのREADMEやPR、UI文言、エラーメッセージ、英語のドキュメント。
エージェント向け文書は `writing-for-agents` に委ねると明記する。
対象外はSKILL.md、AGENTS.md、hookのコメントなど。

#### Scenario: SKILL.md を書く
- **WHEN** エージェントがスキルを書く
- **THEN** `en-writing` ではなく `writing-for-agents` に従う

### Requirement: ルールとセンサー
スキルはagent-styleの21ルールの読み方（`agent-style rules`）を含まなければならない（MUST）。
決定的な監査（`agent-style review --audit-only <file>`）の実行と、結果の扱いも含める。
監査で出た指摘は直してから終える。

#### Scenario: 英語 README の推敲
- **WHEN** 英語のREADMEを書き終えた
- **THEN** `agent-style review --audit-only README.md` を実行し、指摘を直してから報告する

### Requirement: humanizer との併用
スキルは、AIらしい文体を除く最終パスとして `humanizer` スキルを呼ぶ手順を含まなければならない（MUST）。
`assets/voice/en/` にサンプルがあれば、humanizerの文体サンプルとして渡す。

#### Scenario: サンプルあり
- **WHEN** `assets/voice/en/` にサンプルがある
- **THEN** humanizerにサンプルを渡し、その文体に合わせる
