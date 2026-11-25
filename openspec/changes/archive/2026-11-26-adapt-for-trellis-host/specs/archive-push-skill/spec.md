# Spec Delta

## MODIFIED Requirements

### Requirement: pushする
管理者の環境の間、コミットの後、`archive-push` は `push` スキルでpushしなければならない（MUST）。
保護ブランチでの確認やpushの拒否の扱いは `push` スキルに従う。
閉じた環境では、pushの前に止まる（要件「閉じた環境ではコミットで止まる」）。

#### Scenario: 保護されていないブランチ
- **WHEN** 管理者の環境で、現在のブランチが保護ブランチでない
- **THEN** コミットがoriginへpushされ、報告にpushしたブランチとコミットが載る

## ADDED Requirements

### Requirement: 閉じた環境ではコミットで止まる
`archive-push` は、pushの前にプラグインのコマンド `uskn-environment` を実行しなければならない（MUST）。
出力が `confined` のとき、`archive-push` はarchiveとコミットまでを行い、pushしてはならない（MUST NOT）。
報告には、archiveした変更とコミットと、pushは外側が行うことを書く。

#### Scenario: 閉じた環境
- **WHEN** 閉じた環境で `/archive-push add-x` を実行する
- **THEN** archiveのコミットができ、pushは行われず、報告に外側でpushする旨が載る
