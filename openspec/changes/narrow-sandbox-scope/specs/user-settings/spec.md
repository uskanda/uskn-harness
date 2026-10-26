## MODIFIED Requirements

### Requirement: 集合として扱う配列
syncは6つの配列を集合として扱わなければならない（MUST）。
1つ目から4つ目は、`permissions` の下の `allow`、`deny`、`ask`、`additionalDirectories` である。
5つ目と6つ目は、`sandbox.excludedCommands` と `sandbox.filesystem.allowWrite` である。
マージでは、liveの要素を残したまま、合成にあってliveに無い要素を足す。
要素の順序は、liveの要素の後に足した要素が並ぶ。

#### Scenario: 端末で足した allow
- **WHEN** liveの `permissions.allow` に、設定断片に無い `Bash(make *)` がある
- **THEN** sync後も `Bash(make *)` は残り、設定断片の要素も含まれる

#### Scenario: 端末で足した sandbox の外のコマンド
- **WHEN** 端末別設定の `sandbox.excludedCommands` に `terraform *` がある
- **THEN** sync後のliveの `sandbox.excludedCommands` には、`terraform *` と設定断片の要素の両方がある

### Requirement: sandbox の外で動かすコマンド
設定断片の `sandbox.excludedCommands` は、11個の道具に当たるパターン `<tool> *` を持たなければならない（MUST）。
11個とは、`git`、`gh`、`glab`、`docker`、`mise`、`claude`、`uskn-harness`、`uskn-loop`、`chezmoi`、`ssh`、`scp` である。
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
- **WHEN** sandboxの有効な端末のセッションで、`uskn-loop run` の実装役のように `claude -p` を起動する
- **THEN** 起動した `claude -p` は外側のsandboxの外で動き、自分の設定のsandboxだけに従う

### Requirement: sandbox で書けるキャッシュ
設定断片の `sandbox.filesystem.allowWrite` は、キャッシュとツールのデータのディレクトリを持たなければならない（MUST）。
`~/.cache`、`~/.npm`、`~/.local/share/mise`、`~/.local/share/pnpm`、`~/.local/state` の5つである。
設定断片の `sandbox.filesystem.denyWrite` は、ハーネスの状態ディレクトリ `~/.local/state/uskn-harness` を持たなければならない（MUST）。
別のリポジトリと、chezmoiのsource directoryを `allowWrite` に含めてはならない（MUST NOT）。

#### Scenario: npx の取得
- **WHEN** sandboxの有効な端末のセッションで、ルートの中から `npx -y cowsay hi` を実行する
- **THEN** sandboxによる書き込みの拒否が出ずに終わる

#### Scenario: 状態ディレクトリへの書き込み
- **WHEN** sandboxの有効な端末のセッションで、`touch ~/.local/state/uskn-harness/x` を実行する
- **THEN** sandboxが書き込みを拒否する

#### Scenario: ほかの道具の状態
- **WHEN** sandboxの有効な端末のセッションで、`touch ~/.local/state/x` を実行する
- **THEN** 書き込みが通る
