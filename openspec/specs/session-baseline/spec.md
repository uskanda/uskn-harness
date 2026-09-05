# session-baseline Specification

## Purpose
セッション開始時点の作業ツリーの状態を記録し、後続の hook（verify gate、journal）が「このセッションで何が変わったか」を判定できるようにする。

## Requirements

### Requirement: 指紋の記録
`cwd` が git リポジトリのとき、SessionStart hook は状態ディレクトリに記録しなければならない（MUST）。
場所は `${XDG_STATE_HOME:-~/.local/state}/uskn-harness/sessions/<session_id>/`。
`baseline` には作業ツリーの指紋を書く。指紋は HEAD の SHA と、`git status --porcelain`、`git diff HEAD` のハッシュ。
`project` にはリポジトリのルート、`started` には ISO 8601 の開始時刻を書く。
標準出力には何も出さない。

#### Scenario: 開始時
- **WHEN** git リポジトリで SessionStart が発火する
- **THEN** `sessions/<session_id>/` に `baseline`、`project`、`started` が作られる

#### Scenario: 非 git
- **WHEN** git 管理外のディレクトリで発火する
- **THEN** 何も作らず終了コード 0

### Requirement: 既存の記録は上書きしない
同じ session_id の `baseline` が既にあるとき（resume や compact による再発火）、上書きしてはならない（MUST NOT）。

#### Scenario: compact 後
- **WHEN** 同じ session_id で 2 回目の SessionStart が発火する
- **THEN** `baseline` の内容は最初のまま
