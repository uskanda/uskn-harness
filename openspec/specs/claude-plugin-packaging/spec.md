# claude-plugin-packaging Specification

## Purpose
ハーネスのhookをClaude Codeに配るための最小のプラグイン。skills-dirプラグインとしてsymlinkで読み込まれ、marketplaceを要しない。

## Requirements

### Requirement: プラグインの構成
`plugins/uskn-harness/` は `.claude-plugin/plugin.json` と `hooks/hooks.json` を持たなければならない（MUST）。
`plugin.json` はname `uskn-harness`、version、description、authorを持つ。
hookのコマンドは `${CLAUDE_PLUGIN_ROOT}` 起点の相対パスで自身の `hooks/scripts/` を参照する。
プラグイン外へ向くsymlinkを含んではならない（MUST NOT）。

#### Scenario: symlink で読み込む
- **WHEN** `~/.claude/skills/uskn-harness` が `plugins/uskn-harness` へのsymlinkである
- **THEN** `claude plugin list` に `uskn-harness@skills-dir` がloadedとして現れ、SessionStart hookが登録される

### Requirement: 検証を通る
`claude plugin validate --strict plugins/uskn-harness` が成功しなければならない（MUST）。`make verify` はこの検証を含む。

#### Scenario: CI
- **WHEN** `make verify` を実行する
- **THEN** プラグイン検証が実行され、失敗時はverifyも失敗する

### Requirement: スキルを同梱しない
プラグインは `skills/` を持たず、スキルの配布は `sync` のsymlinkに委ねなければならない（MUST）。

#### Scenario: 名前の衝突を避ける
- **WHEN** `~/.claude/skills/commit` がsymlinkで導入されている
- **THEN** `uskn-harness:commit` のような名前空間付きの重複は現れない

### Requirement: hook の起動条件
`hooks.json` は、対象のファイルが決まっているhookに `if` を付けなければならない（MUST）。
textlint-checkとterms-checkは、Writeに `Write(**/*.md)`、Editに `Edit(**/*.md)` を付ける。
grilling-guardは、Writeに `Write(**/openspec/changes/**)`、Editに `Edit(**/openspec/changes/**)` を付ける。
`if` は1つの規則しか持てないので、ツールごとにmatcherを分け、そのツールの規則を1つずつ書く。
write-guard、bash-guard、SessionStartとStopのhookには `if` を付けない。

#### Scenario: Markdown 以外の編集
- **WHEN** `if` を解するClaude Codeで、作業ディレクトリの `src/a.ts` をEditする
- **THEN** textlint-checkとterms-checkは起動しない

#### Scenario: hooks.json の構成
- **WHEN** `hooks.json` のPostToolUseを読む
- **THEN** textlint-checkとterms-checkは、matcherが `Write` の項目と `Edit` の項目に1つずつある
- **AND** `if` は、`Write` の項目では `Write(**/*.md)`、`Edit` の項目では `Edit(**/*.md)`

### Requirement: if を解さない版での絞り込み
`if` で絞るhookのスクリプトは、同じ条件を自分で確かめなければならない（MUST）。
`if` を解さない版のClaude Codeでは、hookがすべての書き込みで起動するからである。

#### Scenario: 古い版での Markdown 以外の編集
- **WHEN** `src/a.ts` のEditの入力を、textlint-checkとterms-checkのスクリプトに直接渡す
- **THEN** 2つのスクリプトは何も出力せず、終了コード0で終わる

### Requirement: スキル向けの短いコマンド
プラグインは `bin/` に、スキルがBashで呼ぶ補助スクリプトの短いコマンドを持たなければならない（MUST）。
`uskn-repo-context` は `session-start.sh` を、`uskn-terms-check` は `terms-check.sh` を、同じ引数で実行する。
終了コードと出力は、元のスクリプトと同じにする。
プラグインがsymlinkを通して読み込まれていても動く。

#### Scenario: ブランチモデルの取得
- **WHEN** gitリポジトリの中で `uskn-repo-context --plain branches` を実行する
- **THEN** `session-start.sh --plain branches` と同じ4行が出力される

#### Scenario: 用語の検査
- **WHEN** 実在しない名前を含む文書に `uskn-terms-check` を実行する
- **THEN** 指摘が出力され、終了コードは1

### Requirement: スキルは短いコマンドで呼ぶ
スキルは、`session-start.sh` と `terms-check.sh` を `hooks/scripts/` の長いパスで呼んではならない（MUST NOT）。
代わりに `uskn-repo-context` と `uskn-terms-check` を使う。

#### Scenario: スキルの監査
- **WHEN** `skills/` の下の `SKILL.md` を `hooks/scripts/session-start.sh` と `hooks/scripts/terms-check.sh` で検索する
- **THEN** 一致しない
