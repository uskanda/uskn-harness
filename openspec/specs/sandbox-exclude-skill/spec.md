# sandbox-exclude-skill Specification

## Purpose
sandboxの中で動かないよく知られた道具を、ユーザーがこの端末のsandboxの外に出すスキル。
どのリポジトリのセッションからでも、ハーネスのコードを直さずに `sandbox.excludedCommands` へ足せる。

## Requirements

### Requirement: ユーザーだけが起動する
`sandbox-exclude` スキルは `disable-model-invocation: true` を持たなければならない（MUST）。
sandboxの外に出すのは守りを緩める判断で、ユーザーだけが行う。
sandboxの中で道具が失敗したとき、エージェントは、このスキルを打つようユーザーに提案してよい。

#### Scenario: エージェントの提案
- **WHEN** sandboxの中で `terraform plan` が書き込みの拒否で失敗する
- **THEN** エージェントは `/sandbox-exclude terraform` を打つようユーザーに提案し、自分ではスキルを起動しない

### Requirement: パターンの組み立てと実行
スキルは、引数の道具の名前から `<tool> *` の形のパターンを組み立てなければならない（MUST）。
続けて、`uskn-harness sandbox-exclude <pattern>` を単独のコマンドとして実行する。
引数が既にパターンの形（空白と `*` を含む）なら、そのまま使う。
実行の後、liveに反映された一覧を `--list` で示す。変更は新しいセッションから使われることも伝える。
中身を前もって読めない実行（`npm`、`make`、`python` など）を足そうとしたときは、sandboxに残す理由を示し、ユーザーが重ねて求めたときだけ足す。

#### Scenario: 道具の名前を渡す
- **WHEN** ユーザーが `/sandbox-exclude terraform` を実行する
- **THEN** スキルは `uskn-harness sandbox-exclude 'terraform *'` を実行し、一覧を示す

#### Scenario: スクリプトの実行を足そうとする
- **WHEN** ユーザーが `/sandbox-exclude make` を実行する
- **THEN** スキルは、`make` がsandboxに残る理由を示して確認を求める
