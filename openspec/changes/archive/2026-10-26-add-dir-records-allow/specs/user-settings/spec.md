## MODIFIED Requirements

### Requirement: sandbox の外で動かすコマンド
設定断片の `sandbox.excludedCommands` は、2つのコマンドに当たるパターンを持たなければならない（MUST）。
2つとは、`uskn-harness` と `chezmoi` である。
2つは、`~/.claude` と `$HOME` へ書くため、sandboxの中では動かない。
`chezmoi` は、sandboxの外でもbash-guardの拒否の対象のままである。
同じく、`.git/config` に書くgitの下位コマンド（`push`、`switch`、`checkout`、`branch`、`config`、`remote`）に当たるパターンも持つ。
sandboxの中では、作業ディレクトリのリポジトリの `.git/config` に書けないため。
許可ファイルは `DirectoryAdded` のhookがsandboxの外で書くので、`allow-repo.sh` のパターンは持たない。

#### Scenario: allow-repo の実行
- **WHEN** sandboxの有効な端末のセッションで、ユーザーが `/add-dir <path>` を実行する
- **THEN** `DirectoryAdded` のhookが、許可ファイルに1行追加する

#### Scenario: 上流を設定する push
- **WHEN** sandboxの有効な端末のセッションで、新しいブランチを `git push -u origin HEAD` でpushする
- **THEN** pushが通り、`.git/config` に上流が記録される

#### Scenario: セッションからの sync
- **WHEN** sandboxの有効な端末のセッションで、`uskn-harness sync --dry-run` を実行する
- **THEN** sandboxによる書き込みの拒否が出ずに、予定が出力される
