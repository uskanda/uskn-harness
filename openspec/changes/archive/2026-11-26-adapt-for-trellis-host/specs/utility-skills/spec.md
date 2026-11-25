# Spec Delta

## ADDED Requirements

### Requirement: 管理者の環境だけのスキルの印
`cleanup` と `set-workspace-theme` の `SKILL.md` は、frontmatterの `metadata` に印を持たなければならない（MUST）。
印は `uskn-environment: admin` である。
どちらも、画面とプロセスを持つ管理者の環境の端末だけで意味を持つため。
閉じた環境のsyncは、この印を持つスキルを入れない。
`make verify` のbatsがこの値を確かめる。

#### Scenario: frontmatter
- **WHEN** `skills/set-workspace-theme/SKILL.md` のfrontmatterを読む
- **THEN** `metadata` の `uskn-environment` は `admin`

#### Scenario: 印を消す
- **WHEN** `skills/cleanup/SKILL.md` の `metadata` を消して `make verify` を実行する
- **THEN** batsが失敗し、`cleanup` の名前が出る
