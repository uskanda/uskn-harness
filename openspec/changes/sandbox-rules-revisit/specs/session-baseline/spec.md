## MODIFIED Requirements

### Requirement: 指紋の記録
`cwd` がgitリポジトリのとき、SessionStart hookは状態ディレクトリに記録しなければならない（MUST）。
場所は `${XDG_STATE_HOME:-~/.local/state}/uskn-harness/sessions/<session_id>/`。
`baseline` には作業ツリーの指紋を書く。指紋はHEADのSHAと、`git status --porcelain`、`git diff HEAD`、未追跡のファイルの中身のハッシュ。
指紋は、仮ファイルを数えてはならない（MUST NOT）。
仮ファイルとして扱うのは、未追跡で大きさが0のファイルのうち、作業ツリーの直下にあって `.` で始まる名前のものと、`.claude/` の直下にあるものである。
verify gateは同じ指紋を使う。
書くのは `baseline` だけで、`project`、`started`、`baseline-head` は書かない。
標準出力には何も出さない。

#### Scenario: 開始時
- **WHEN** gitリポジトリでSessionStartが発火する
- **THEN** `sessions/<session_id>/` に `baseline` だけが作られる

#### Scenario: 非 git
- **WHEN** git管理外のディレクトリで発火する
- **THEN** 何も作らず終了コード0

#### Scenario: 仮ファイルが現れた
- **WHEN** 指紋を記録した後に、作業ツリーの直下に0バイトの `.bashrc` と、`.claude/` の直下に0バイトの `agents` ができる
- **THEN** 指紋は記録したものと変わらない

#### Scenario: 中身のある dotfile
- **WHEN** 指紋を記録した後に、作業ツリーの直下に中身のある `.envrc` を置く
- **THEN** 指紋は変わる

#### Scenario: 深い場所の空のファイル
- **WHEN** 指紋を記録した後に、`docs/.keep` を0バイトで置く
- **THEN** 指紋は変わる
