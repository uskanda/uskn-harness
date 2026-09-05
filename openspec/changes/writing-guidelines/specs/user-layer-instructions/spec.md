## ADDED Requirements

### Requirement: Writing 節
ユーザー層の `CLAUDE.md` は、文章の指針への導線を含まなければならない（MUST）。
日本語の文章は `ja-writing`、人が読む英語の文章は `en-writing` に従う。
Markdown を書いたあとに出る textlint の指摘は、直してから終える。

#### Scenario: hook の指摘
- **WHEN** textlint hook が指摘を返す
- **THEN** エージェントは指摘を直してから作業を終えたと報告する
