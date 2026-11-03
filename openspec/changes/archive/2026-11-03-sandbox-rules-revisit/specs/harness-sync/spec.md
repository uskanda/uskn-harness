## ADDED Requirements

### Requirement: sandbox の接続先の追加
`uskn-harness sandbox-allow-host <host>` は、sandboxの接続先にホストを足さなければならない（MUST）。足す先は、端末別設定の `sandbox.network.allowedDomains` である。
端末別設定の置き場は `~/.config/uskn-harness/settings.json` である。
既にあるホストは足さない。端末別設定が無ければ作る。
続けて、ユーザー層の設定の手順だけをsyncと同じ規則で実行し、liveに反映する。
`<host>` が空のときと、`*` を含むときは、何も変えずに終了コード2で終える。
URLの形（`https://` で始まる、または `/` を含む）のときも、何も変えずに終了コード2で終える。

#### Scenario: 自前の GitLab を足す
- **WHEN** `uskn-harness sandbox-allow-host <gl.example.test>` を実行する
- **THEN** 端末別設定とliveの `sandbox.network.allowedDomains` に `<gl.example.test>` がある

#### Scenario: すべてのホストを足そうとする
- **WHEN** `uskn-harness sandbox-allow-host '*'` を実行する
- **THEN** 端末別設定は変わらず、終了コードは2

#### Scenario: URL を渡す
- **WHEN** `uskn-harness sandbox-allow-host https://gl.example.test/api` を実行する
- **THEN** 端末別設定は変わらず、出力にホストの名前だけを渡すことが含まれ、終了コードは2

### Requirement: sandbox の接続先の一覧と削除
`uskn-harness sandbox-allow-host --list` は、liveの `sandbox.network.allowedDomains` を1行ずつ出さなければならない（MUST）。
各行には、設定断片の要素か端末別設定の要素かを示す。
`uskn-harness sandbox-allow-host --remove <host>` は、端末別設定からホストを消し、liveに反映しなければならない（MUST）。
設定断片の要素は `--remove` で消してはならない（MUST NOT）。消そうとしたときは、設定断片を直すPRが要ることを出力し、終了コード2で終える。

#### Scenario: 端末で足したものを外す
- **WHEN** `<gl.example.test>` を足した後に `uskn-harness sandbox-allow-host --remove <gl.example.test>` を実行する
- **THEN** 端末別設定とliveの `sandbox.network.allowedDomains` から `<gl.example.test>` が消える
