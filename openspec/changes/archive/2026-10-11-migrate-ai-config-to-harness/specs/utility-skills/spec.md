## Purpose

dotfilesから移した2つのスキル。
cleanupは古いClaude Codeのプロセスを止めてメモリを空け、set-workspace-themeはVS Codeのworkspaceごとにタイトルと配色を決める。

## ADDED Requirements

### Requirement: cleanup の対象
`skills/cleanup/SKILL.md` は、Claude Codeのプロセスを止める手順を持たなければならない（MUST）。
止める対象は、起動から2時間より長く経ったプロセスに限る。スキルを実行しているセッション自身のプロセスは止めない（MUST NOT）。
手順の前後でメモリの使用量を表示し、止めたプロセスの数を報告する。

#### Scenario: 古いプロセスと新しいプロセス
- **WHEN** 3時間前に起動したClaude Codeのプロセスと、10分前に起動したプロセスがある
- **THEN** 3時間前のプロセスだけが止まり、止めた数として1が報告される

### Requirement: cleanup はユーザーが起動する
`skills/cleanup/SKILL.md` は `disable-model-invocation: true` を持たなければならない（MUST）。
プロセスを止める操作なので、モデルの判断では起動しない。

#### Scenario: frontmatter
- **WHEN** `skills/cleanup/SKILL.md` のfrontmatterを読む
- **THEN** `disable-model-invocation` は `true`

### Requirement: set-workspace-theme の書き込み先
`skills/set-workspace-theme/SKILL.md` は、2つの値をworkspaceの設定に書く手順を持たなければならない（MUST）。
値は `window.title` と `workbench.colorTheme`。
書き込み先は、単一フォルダーなら `.vscode/settings.json`、multi-rootなら `.code-workspace` の `settings`。
ユーザー層のVS Codeの設定には書かない（MUST NOT）。

#### Scenario: multi-root の workspace
- **WHEN** multi-rootのworkspaceでスキルを実行する
- **THEN** 値は `.code-workspace` の `settings` に書かれ、各フォルダーの `.vscode/settings.json` は変わらない

### Requirement: set-workspace-theme は提案してから書く
スキルは、タイトルとテーマを提案し、ユーザーの応答を受けてから書き込まなければならない（MUST）。
ユーザーが提案と違う値を答えたときは、その値を書く。

#### Scenario: ユーザーが別のテーマを選ぶ
- **WHEN** スキルが提案したテーマに対し、ユーザーが別のテーマを答える
- **THEN** ユーザーが答えたテーマの `id` が書かれる

### Requirement: set-workspace-theme の補助スクリプト
`skills/set-workspace-theme/` は補助スクリプト `scripts/vscode-workspace-env.py` を持たなければならない（MUST）。
スキルは、`~/.claude/skills/set-workspace-theme/` 起点のパスでこのスクリプトを呼ぶ。
スクリプトは、開いている他のウィンドウのテーマと、色相の離れたテーマの候補をJSONで返す。

#### Scenario: symlink で導入した端末
- **WHEN** `~/.claude/skills/set-workspace-theme` がハーネスへのsymlinkで、スキルが補助スクリプトを実行する
- **THEN** スクリプトはJSONを出力して終了コード0で終わる
