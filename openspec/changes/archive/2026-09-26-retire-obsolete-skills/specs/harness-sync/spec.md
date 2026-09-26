## RENAMED Requirements

- FROM: `### Requirement: OpenSpec のユーザー層スキル`
- TO: `### Requirement: OpenSpec のユーザー層コマンド`

## MODIFIED Requirements

### Requirement: OpenSpec のユーザー層コマンド
`sync` はopenspecがClaude Code向けに生成するコマンド（`/opsx:*`）を、一時ディレクトリで作らなければならない（MUST）。
生成の間だけ、`XDG_CONFIG_HOME` を別の一時ディレクトリに差し替える。そこに置く `openspec/config.json` はprofileを `core`、deliveryを `commands` とする。
ユーザー全体のOpenSpecの設定（`~/.config/openspec/config.json`）は変えない（MUST NOT）。
生成物の `.claude/commands/opsx/` は `~/.claude/commands/opsx/` にコピーする。
コピー先にはハーネス管理の印として `.uskn-harness-managed` ファイルを置く。
OpenSpecのスキル（`openspec-*`）はユーザー層にコピーしない（MUST NOT）。
コピー先に印の無い同名ディレクトリがあれば、上書きせず警告する。

#### Scenario: バージョン更新
- **WHEN** openspecのversionが上がり、生成されるコマンドの内容が変わった状態で `sync` を実行する
- **THEN** `~/.claude/commands/opsx/` が新しい内容に置き換わり、`updated` と報告される

#### Scenario: ユーザー全体の設定
- **WHEN** `~/.config/openspec/config.json` がdeliveryを持たない状態で `sync` を実行する
- **THEN** 実行の前後でファイルの内容は同じ。プロダクトリポジトリの `openspec update` は、これまでどおりその設定に従う

#### Scenario: スキルは作らない
- **WHEN** `~/.claude/skills` に `openspec-*` が無い状態で `sync` を実行する
- **THEN** `~/.claude/commands/opsx/` に6つのコマンドが置かれ、`~/.claude/skills/openspec-*` は作られない

## ADDED Requirements

### Requirement: OpenSpec の旧スキルの削除
`sync` は、`~/.claude/skills/openspec-*` のうち `.uskn-harness-managed` を持つディレクトリを削除しなければならない（MUST）。
印の無いディレクトリには触らない。
`--dry-run` のときは予定を出力するだけで、削除しない。

#### Scenario: 以前の sync が入れたスキル
- **WHEN** `~/.claude/skills/openspec-propose` が印を持つディレクトリとして存在する
- **THEN** `sync` はそれを削除し、`removed` と報告する

#### Scenario: 印の無いスキル
- **WHEN** `~/.claude/skills/openspec-explore` が印の無いディレクトリとして存在する
- **THEN** ディレクトリはそのまま残る

### Requirement: 実体の無い symlink の削除
`sync` は、`~/.claude/skills` の下のsymlinkのうち、ハーネスの `skills/` の下を指し、指す先が存在しないものを削除しなければならない（MUST）。
ハーネスの外を指すsymlink、指す先が存在するsymlink、実ディレクトリには触らない（MUST NOT）。
名前がハーネスの現存するスキルと同じsymlinkは削除せず、張り直す。
`--dry-run` のときは予定を出力するだけで、削除しない。`sync --remove` も同じ規則でこのsymlinkを削除する。

#### Scenario: ハーネスから削除したスキル
- **WHEN** `~/.claude/skills/nessun-dorma` が、もう存在しない `skills/git/nessun-dorma` を指している
- **THEN** `sync` はsymlinkを削除し、`removed` と報告する

#### Scenario: ハーネスの外を指す実体の無い symlink
- **WHEN** `~/.claude/skills/mine` が、存在しないハーネス外のパスを指している
- **THEN** symlinkはそのまま残る

#### Scenario: 移動したスキル
- **WHEN** `~/.claude/skills/pr` が、存在しない `skills/old-location/pr` を指している
- **THEN** symlinkは削除されず、`skills/git/pr` へ張り直されて `updated` と報告される
