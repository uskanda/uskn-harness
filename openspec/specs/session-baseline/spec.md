# session-baseline Specification

## Purpose
セッション開始時点の作業ツリーの状態を記録し、後続のhook（verify gate、journal）が「このセッションで何が変わったか」を判定できるようにする。

## Requirements

### Requirement: 指紋の記録
`cwd` がgitリポジトリのとき、SessionStart hookは状態ディレクトリに記録しなければならない（MUST）。
場所は `${XDG_STATE_HOME:-~/.local/state}/uskn-harness/sessions/<session_id>/`。
`baseline` には作業ツリーの指紋を書く。指紋はHEADのSHAと、`git status --porcelain`、`git diff HEAD` のハッシュ。
`project` にはリポジトリのルート、`started` にはISO 8601の開始時刻を書く。
標準出力には何も出さない。

#### Scenario: 開始時
- **WHEN** gitリポジトリでSessionStartが発火する
- **THEN** `sessions/<session_id>/` に `baseline`、`project`、`started` が作られる

#### Scenario: 非 git
- **WHEN** git管理外のディレクトリで発火する
- **THEN** 何も作らず終了コード0

### Requirement: 既存の記録は上書きしない
同じsession_idの `baseline` が既にあるとき（resumeやcompactによる再発火）、上書きしてはならない（MUST NOT）。

#### Scenario: compact 後
- **WHEN** 同じsession_idで2回目のSessionStartが発火する
- **THEN** `baseline` の内容は最初のまま
