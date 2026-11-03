## MODIFIED Requirements

### Requirement: 集合として扱う配列
syncは7つの配列を集合として扱わなければならない（MUST）。
1つ目から4つ目は、`permissions` の下の `allow`、`deny`、`ask`、`additionalDirectories` である。
5つ目から7つ目は、`sandbox.excludedCommands`、`sandbox.filesystem.allowWrite`、`sandbox.network.allowedDomains` である。
マージでは、liveの要素を残したまま、合成にあってliveに無い要素を足す。
要素の順序は、liveの要素の後に足した要素が並ぶ。

#### Scenario: 端末で足した allow
- **WHEN** liveの `permissions.allow` に、設定断片に無い `Bash(make *)` がある
- **THEN** sync後も `Bash(make *)` は残り、設定断片の要素も含まれる

#### Scenario: 端末で足した sandbox の外のコマンド
- **WHEN** 端末別設定の `sandbox.excludedCommands` に `terraform *` がある
- **THEN** sync後のliveの `sandbox.excludedCommands` には、`terraform *` と設定断片の要素の両方がある

#### Scenario: 端末で足した接続先
- **WHEN** 端末別設定の `sandbox.network.allowedDomains` に `<gl.example.test>` があり、liveには別の要素 `<pkg.example.test>` がある
- **THEN** sync後のliveの `sandbox.network.allowedDomains` には、`<pkg.example.test>` と `<gl.example.test>` の両方がある

### Requirement: 外部への接続の許可
設定断片の `permissions.allow` は `WebFetch(domain:*)` を持たなければならない（MUST）。
ユーザーは、調査などでの外部への接続を、ドメインごとに許可しない。
sandboxは、このルールをBashの接続先にも全ホストの許可として使う。
ただし、この端末のIPに解決されるホストへの接続は、このルールでは通らない。そのホストは、ユーザーが `/sandbox-allow-host` で端末別設定の `sandbox.network.allowedDomains` に足す。
設定断片の `sandbox.network.allowedDomains` には、端末ごとのホストを書いてはならない（MUST NOT）。

#### Scenario: 調査での取得
- **WHEN** sync後の端末のセッションで、WebFetchが初めてのドメインの文書を取得する
- **THEN** 確認を求められずに取得する

#### Scenario: Bash からの push
- **WHEN** sandboxの有効な端末のセッションで、ルートの中から `git push` をgithub.comへ実行する
- **THEN** sandboxによるネットワークの拒否が出ずに終わる

#### Scenario: 接続先を足した後の全ホスト
- **WHEN** 端末別設定の `sandbox.network.allowedDomains` に1つのホストを足してsyncする。その後のセッションで、sandboxの中から `curl -sI https://github.com` を実行する
- **THEN** 接続は拒否されない

## ADDED Requirements

### Requirement: Unixソケットの許可
設定断片は、`sandbox.network.allowAllUnixSockets` を `true` にしなければならない（MUST）。
D-Busを使う `systemctl --user`、`journalctl`、`secret-tool` と、Unixソケットで待つテストを、sandboxの中で動かすため。
Linuxには、ソケットのパスを選んで許可する設定が無い。
`make verify` のbatsがこの値を確かめる。

#### Scenario: ソケットを禁じた設定断片
- **WHEN** 設定断片の `sandbox.network.allowAllUnixSockets` を消して `make verify` を実行する
- **THEN** batsが失敗し、キーの名前が出る

#### Scenario: ユーザーのsystemd
- **WHEN** sync後のLinuxの端末のセッションで、sandboxの中から `systemctl --user is-system-running` を実行する
- **THEN** `Failed to connect to bus` で失敗しない
