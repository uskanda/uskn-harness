# write-guard Specification

## Purpose
ファイル編集ツールがプロジェクトルートの外に書くのを止める。誤爆を避けるため、作業に必要な場所は許可リストで通す。

## Requirements

### Requirement: ルート外の拒否
プロジェクトルートは `CLAUDE_PROJECT_DIR`、無ければ `cwd` のgitルート、それも無ければ `cwd`。
対象パス（`file_path` または `notebook_path`）の実体がその外にあるとき、hookは `permissionDecision: deny` と理由を返さなければならない（MUST）。
理由には `/allow-repo <path>` で解除できる旨を書く。
ルート内と許可リスト内は何も出力しない。
許可リストは `/tmp`、`$TMPDIR`、`~/.claude/projects/*/memory`、ハーネスの状態ディレクトリ、`$CLAUDE_PLUGIN_DATA`。
状態ディレクトリのうち、セッションの許可ファイル `sessions/<session_id>/allow` は許可リストに含めない。

#### Scenario: 他のリポジトリ
- **WHEN** ルートが `~/repos/a` のセッションで `~/repos/b/x.md` をWriteする
- **THEN** 拒否され、理由に `/allow-repo` が含まれる

#### Scenario: scratchpad
- **WHEN** `/tmp/claude-1000/.../scratchpad/x` をWriteする
- **THEN** 何も出力しない

#### Scenario: symlink 経由のルート内
- **WHEN** ルートへのsymlinkを通したパスをEditする
- **THEN** 実体がルート内なので何も出力しない

#### Scenario: 状態ディレクトリのほかのファイル
- **WHEN** 状態ディレクトリの `sessions/<session_id>/notes` をWriteする
- **THEN** 何も出力しない

#### Scenario: journal の置き場だった場所
- **WHEN** `~/.ai-sessions/x/j.md` をWriteする
- **THEN** ほかのルート外と同じく拒否される

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

### Requirement: 許可ファイルの保護
対象パスの実体が状態ディレクトリの `sessions/<session_id>/allow` のとき、hookは `permissionDecision: deny` を返さなければならない（MUST）。
セッションの許可ファイルに何が書かれていても、この拒否は解除しない。
理由には、許可ファイルを書くのは `/allow-repo` だけで、ユーザーの依頼があるときに限る旨を書く。

#### Scenario: エージェントが自分で許可を足す
- **WHEN** `~/.local/state/uskn-harness/sessions/<session_id>/allow` をWriteする
- **THEN** 拒否され、理由に `/allow-repo` が含まれる

#### Scenario: symlink 経由
- **WHEN** 状態ディレクトリを指すsymlinkを通して許可ファイルをEditする
- **THEN** 実体が許可ファイルなので拒否される

#### Scenario: 状態ディレクトリを許可したあと
- **WHEN** セッションの許可ファイルに状態ディレクトリが書かれている状態で、許可ファイルをWriteする
- **THEN** 拒否される
