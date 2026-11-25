# Spec Delta

## MODIFIED Requirements

### Requirement: draftのPRかMRを作る
管理者の環境の間、repo-contextのplatformがgithubのとき、`spec-pr` は統合ブランチ向けのdraft PRを作らなければならない（MUST）。
管理者の環境の間、repo-contextのplatformがgitlabのとき、`spec-pr` は統合ブランチ向けのdraft MRを作らなければならない（MUST）。
`spec-pr` は仕様PRに自動マージを設定してはならない（MUST NOT）。
閉じた環境での扱いは、要件「閉じた環境ではコミットで止まる」が決める。

#### Scenario: GitHub
- **WHEN** 管理者の環境で、GitHubのリポジトリで `/spec-pr add-x` を実行する
- **THEN** `change/add-x` から統合ブランチへのdraft PRができ、自動マージは設定されていない

#### Scenario: GitLab
- **WHEN** 管理者の環境で、GitLabのリポジトリで `/spec-pr add-x` を実行する
- **THEN** `change/add-x` から統合ブランチへのdraft MRができ、マージ時の自動マージは設定されていない

## ADDED Requirements

### Requirement: 閉じた環境ではコミットで止まる
`spec-pr` は、pushの前にプラグインのコマンド `uskn-environment` を実行しなければならない（MUST）。
出力が `confined` のとき、`spec-pr` は `change/<name>` のコミットまでを行い、pushとPRかMRの作成をしてはならない（MUST NOT）。
報告には、ブランチとコミットと、pushとPRは外側が行うことを書き、元のブランチに戻る。

#### Scenario: 閉じた環境
- **WHEN** 閉じた環境で `/spec-pr add-x` を実行する
- **THEN** `change/add-x` にコミットができ、pushとPRの作成は行われず、元のブランチに戻る
