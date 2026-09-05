# write-guard Specification

## Purpose
ファイル編集ツールがプロジェクトルートの外に書くのを止める。誤爆を避けるため、作業に必要な場所は許可リストで通す。

## Requirements

### Requirement: ルート外の拒否
プロジェクトルートは `CLAUDE_PROJECT_DIR`、無ければ `cwd` のgitルート、それも無ければ `cwd`。
対象パス（`file_path` または `notebook_path`）の実体がその外にあるとき、hookは `permissionDecision: deny` と理由を返さなければならない（MUST）。
理由には `/allow-repo <path>` で解除できる旨を書く。
ルート内と許可リスト内は何も出力しない。
許可リストは `/tmp`、`$TMPDIR`、`~/.ai-sessions`、`~/.claude/projects/*/memory`、ハーネスの状態ディレクトリ、`$CLAUDE_PLUGIN_DATA`。

#### Scenario: 他のリポジトリ
- **WHEN** ルートが `~/repos/a` のセッションで `~/repos/b/x.md` をWriteする
- **THEN** 拒否され、理由に `/allow-repo` が含まれる

#### Scenario: scratchpad
- **WHEN** `/tmp/claude-1000/.../scratchpad/x` をWriteする
- **THEN** 何も出力しない

#### Scenario: symlink 経由のルート内
- **WHEN** ルートへのsymlinkを通したパスをEditする
- **THEN** 実体がルート内なので何も出力しない

### Requirement: セッション限定の解除
`sessions/<session_id>/allow` に列挙されたパス配下は許可しなければならない（MUST）。他のセッションの解除は効かない。

#### Scenario: 解除後
- **WHEN** `~/repos/b` がallowに書かれている
- **THEN** `~/repos/b/x.md` へのWriteは何も出力しない

### Requirement: 失敗しても止めない
入力が読めない、パスが無いといった場合は何も出力せず終了コード0で終わる（MUST）。

#### Scenario: 壊れた入力
- **WHEN** stdinがJSONでない
- **THEN** 出力は空
