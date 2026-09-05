## Purpose

ファイル編集ツールがプロジェクトルートの外に書くのを止める。誤爆を避けるため、作業に必要な場所は許可リストで通す。

## ADDED Requirements

### Requirement: ルート外の拒否
対象パス（`file_path` または `notebook_path`）の実体がプロジェクトルート（`CLAUDE_PROJECT_DIR`、無ければ `cwd` の git ルート、無ければ `cwd`）の外にあるとき、hook は `permissionDecision: deny` と、`/allow-repo <path>` で解除できる旨の理由を返さなければならない（MUST）。ルート内、および許可リスト（`/tmp`、`$TMPDIR`、`~/.ai-sessions`、`~/.claude/projects/*/memory`、ハーネスの状態ディレクトリ、`$CLAUDE_PLUGIN_DATA`）内は何も出力しない。

#### Scenario: 他のリポジトリ
- **WHEN** ルートが `~/repos/a` のセッションで `~/repos/b/x.md` を Write する
- **THEN** 拒否され、理由に `/allow-repo` が含まれる

#### Scenario: scratchpad
- **WHEN** `/tmp/claude-1000/.../scratchpad/x` を Write する
- **THEN** 何も出力しない

#### Scenario: symlink 経由のルート内
- **WHEN** ルートへの symlink を通したパスを Edit する
- **THEN** 実体がルート内なので何も出力しない

### Requirement: セッション限定の解除
`sessions/<session_id>/allow` に列挙されたパス配下は許可しなければならない（MUST）。他のセッションの解除は効かない。

#### Scenario: 解除後
- **WHEN** `~/repos/b` が allow に書かれている
- **THEN** `~/repos/b/x.md` への Write は何も出力しない

### Requirement: 失敗しても止めない
入力が読めない、パスが無いといった場合は何も出力せず終了コード 0 で終わる（MUST）。

#### Scenario: 壊れた入力
- **WHEN** stdin が JSON でない
- **THEN** 出力は空
