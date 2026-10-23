## ADDED Requirements

### Requirement: 設定断片の sandbox
設定断片は、`sandbox.enabled` を `true` にしなければならない（MUST）。
同じく `sandbox.failIfUnavailable` を `false`、`sandbox.allowUnsandboxedCommands` を `true` にする。
`failIfUnavailable` は、`bwrap` の無い端末でもClaude Codeを起動できるようにするため。
`allowUnsandboxedCommands` は、sandboxが拒否したコマンドを、auto modeのclassifierの判定で再実行できるようにするため。
`make verify` のbatsがこの3つの値を確かめる。

#### Scenario: sandbox を切った設定断片
- **WHEN** 設定断片の `sandbox.enabled` を `false` にして `make verify` を実行する
- **THEN** batsが失敗し、キーの名前が出る

#### Scenario: 新しい端末の sync
- **WHEN** sandboxの設定の無い端末でsyncを実行する
- **THEN** liveの `sandbox.enabled` は `true` になる

### Requirement: sandbox の外で動かすコマンド
設定断片の `sandbox.excludedCommands` は、3つのコマンドに当たるパターンを持たなければならない（MUST）。
3つとは、`allow-repo.sh`、`uskn-harness`、`chezmoi` である。
3つは、状態ディレクトリ、`~/.claude`、`$HOME` へ書くため、sandboxの中では動かない。
`chezmoi` は、sandboxの外でもbash-guardの拒否の対象のままである。

#### Scenario: allow-repo の実行
- **WHEN** sandboxの有効な端末で、`/allow-repo` スキルが `allow-repo.sh --session <sid8> <path>` を実行する
- **THEN** 許可ファイルに1行追加される

#### Scenario: セッションからの sync
- **WHEN** sandboxの有効な端末のセッションで、`uskn-harness sync --dry-run` を実行する
- **THEN** sandboxによる書き込みの拒否が出ずに、予定が出力される

### Requirement: sandbox で書けるキャッシュ
設定断片の `sandbox.filesystem.allowWrite` は、`npx`、mise、pipがsandboxの中で動くのに要るキャッシュのディレクトリだけを持たなければならない（MUST）。
候補は `~/.npm`、`~/.cache`、`~/.local/share/mise` で、実機で要ると確かめたものだけを残す。
ハーネスの状態ディレクトリと、別のリポジトリを含めてはならない（MUST NOT）。

#### Scenario: npx の取得
- **WHEN** sandboxの有効な端末のセッションで、ルートの中から `npx -y cowsay hi` を実行する
- **THEN** sandboxによる書き込みの拒否が出ずに終わる

#### Scenario: 状態ディレクトリへの書き込み
- **WHEN** sandboxの有効な端末のセッションで、`touch ~/.local/state/uskn-harness/x` を実行する
- **THEN** sandboxが書き込みを拒否する

### Requirement: 外部への接続の許可
設定断片の `permissions.allow` は `WebFetch(domain:*)` を持たなければならない（MUST）。
ユーザーは、調査などでの外部への接続を、ドメインごとに許可しない。
このルールでsandboxの中のBashが全ホストに接続できないときは、`sandbox.network.allowedDomains` にホストを並べる。
並べるのは、gitのホスティングとパッケージの取得元のホストである。

#### Scenario: 調査での取得
- **WHEN** sync後の端末のセッションで、WebFetchが初めてのドメインの文書を取得する
- **THEN** 確認を求められずに取得する

#### Scenario: Bash からの push
- **WHEN** sandboxの有効な端末のセッションで、ルートの中から `git push` をgithub.comへ実行する
- **THEN** sandboxによるネットワークの拒否が出ずに終わる
