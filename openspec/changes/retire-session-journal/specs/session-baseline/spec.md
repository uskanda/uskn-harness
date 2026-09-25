## MODIFIED Requirements

### Requirement: 指紋の記録
`cwd` がgitリポジトリのとき、SessionStart hookは状態ディレクトリに記録しなければならない（MUST）。
場所は `${XDG_STATE_HOME:-~/.local/state}/uskn-harness/sessions/<session_id>/`。
`baseline` には作業ツリーの指紋を書く。指紋はHEADのSHAと、`git status --porcelain`、`git diff HEAD` のハッシュ。
書くのは `baseline` だけで、`project`、`started`、`baseline-head` は書かない。
標準出力には何も出さない。

#### Scenario: 開始時
- **WHEN** gitリポジトリでSessionStartが発火する
- **THEN** `sessions/<session_id>/` に `baseline` だけが作られる

#### Scenario: 非 git
- **WHEN** git管理外のディレクトリで発火する
- **THEN** 何も作らず終了コード0
