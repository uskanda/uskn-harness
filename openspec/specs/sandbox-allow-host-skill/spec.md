# sandbox-allow-host-skill Specification

## Purpose
sandboxの中のBashが接続できないホストを、ユーザーがこの端末のsandboxの接続先に足すスキル。
主な対象は、この端末のIPに解決されるホスト（同じ端末で動かすGitLabなど）である。

## Requirements

### Requirement: ユーザーだけが起動する
`sandbox-allow-host` スキルは `disable-model-invocation: true` を持たなければならない（MUST）。
接続先を足すのは守りを緩める判断で、ユーザーだけが行う。
sandboxの中の接続が拒否されたとき、エージェントは、このスキルを打つようユーザーに提案してよい。

#### Scenario: エージェントの提案
- **WHEN** sandboxの中で `curl` が `resolved to one of this host's addresses` で拒否される
- **THEN** エージェントは `/sandbox-allow-host <host>` を打つようユーザーに提案し、自分ではスキルを起動しない

### Requirement: ホストの取り出しと実行
スキルは、引数からホストの名前を取り出さなければならない（MUST）。
引数がURLなら、`https://` などの前置きとパスを除き、ホストの名前だけを使う。
続けて、`uskn-harness sandbox-allow-host <host>` を単独のコマンドとして実行する。
実行の後、liveに反映された一覧を `--list` で示す。変更は新しいセッションから使われることも伝える。
引数が `*` を含むときは、全ホストの許可は `WebFetch(domain:*)` が既に持つことを示し、足さない。

#### Scenario: ホストの名前を渡す
- **WHEN** ユーザーが `/sandbox-allow-host <gl.example.test>` を実行する
- **THEN** スキルは `uskn-harness sandbox-allow-host <gl.example.test>` を実行し、一覧を示す

#### Scenario: URL を渡す
- **WHEN** ユーザーが `/sandbox-allow-host https://gl.example.test/api/v4` を実行する
- **THEN** スキルは、ホストの名前だけを `uskn-harness sandbox-allow-host` に渡す
