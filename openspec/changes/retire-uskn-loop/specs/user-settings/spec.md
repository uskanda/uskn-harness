## MODIFIED Requirements

### Requirement: sandbox の外で動かすコマンド
設定断片の `sandbox.excludedCommands` は、10個の道具に当たるパターン `<tool> *` を持たなければならない（MUST）。
10個とは、`git`、`gh`、`glab`、`docker`、`mise`、`claude`、`uskn-harness`、`chezmoi`、`ssh`、`scp` である。
これらは効果がコマンドの形から決まる道具であり、bash-guardとauto modeのclassifierが判断する。
`npm`、`pnpm`、`npx`、`make`、`python`、`node`、`curl` のような、中身を前もって読めない実行のパターンを持ってはならない（MUST NOT）。
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

#### Scenario: 入れ子の claude
- **WHEN** sandboxの有効な端末のセッションで、Bashから `claude -p` を起動する
- **THEN** 起動した `claude -p` は外側のsandboxの外で動き、自分の設定のsandboxだけに従う

#### Scenario: 廃止したループのパターン
- **WHEN** 適用記録の `sandbox.excludedCommands` に `uskn-loop *` がある端末で `sync` を実行する
- **THEN** liveの `sandbox.excludedCommands` から `uskn-loop *` が消える
