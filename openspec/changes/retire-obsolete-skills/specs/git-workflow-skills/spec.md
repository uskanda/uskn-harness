## MODIFIED Requirements

### Requirement: スキルの集合と命名
システムは次の9スキルを提供しなければならない（MUST）。
`commit` `push` `pr` `sync-base` `switch-base` `rebase` `cleanup-merged` `fix-ci` `release`。
加えて `mr` `mr-main` `mr-qa` `merge-develop` `switch-develop-branch` をエイリアスとして提供する。
エイリアスは対応するスキルを呼ぶだけで、モデルからの自動起動を無効にする。

#### Scenario: エイリアスの起動
- **WHEN** ユーザーが `/mr-qa` を実行する
- **THEN** `pr` スキルが対象 `qa` で実行され、エイリアス自身は追加の手順を持たない

#### Scenario: 削除したスキル
- **WHEN** `skills/git/` の下を一覧する
- **THEN** `pre-merge` と `nessun-dorma` は無い。CIと同じ確認は `verify`、長時間の自律作業はClaude Codeの `/goal` が受け持つ
