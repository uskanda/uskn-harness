## MODIFIED Requirements

### Requirement: 端末別設定の重ね合わせ
syncは、4段を順に重ねた合成を求めなければならない（MUST）。
1段目は共通の設定断片、2段目は環境の種類の設定断片、3段目はOS別の設定断片、4段目は端末別設定 `~/.config/uskn-harness/settings.json` である。
重ね方は、liveへのマージと同じ規則に従う。
OSは `uname -s` が `Linux` なら `settings-linux.json`、`Darwin` なら `settings-darwin.json` とし、ほかのOSでは3段目を飛ばす。
端末別設定が無いときは4段目を飛ばす。
端末別設定はハーネスのリポジトリに入らず、syncはこのファイルを作らず、変更しない。

#### Scenario: モデルを端末で変える
- **WHEN** 設定断片の `model` が `opus[1m]` で、端末別設定の `model` が `sonnet`
- **THEN** sync後のliveの `model` は `sonnet`

#### Scenario: 端末別設定が無い
- **WHEN** `~/.config/uskn-harness/settings.json` が無い
- **THEN** 合成は3段目までの重ね合わせと同じで、ファイルは作られない

#### Scenario: 管理者の環境の Linux
- **WHEN** 印の無いcheckoutから、Linuxの端末でsyncを実行する
- **THEN** 合成は、共通、`settings-admin.json`、`settings-linux.json`、端末別設定の順に重ねたもの

#### Scenario: 分ける前と同じ合成
- **WHEN** 管理者の環境のLinuxの端末で、端末別設定の無いまま合成を求める
- **THEN** 合成は、分ける前の `templates/user/settings.json` から、廃止した `uskn-loop *` を除いたものと同じキーと、同じ配列の要素を持つ

### Requirement: sandbox の外で動かすコマンド
管理者の環境用の設定断片の `sandbox.excludedCommands` は、10個の道具に当たるパターン `<tool> *` を持たなければならない（MUST）。
10個とは、`git`、`gh`、`glab`、`docker`、`mise`、`claude`、`uskn-harness`、`chezmoi`、`ssh`、`scp` である。
これらは効果がコマンドの形から決まる道具であり、bash-guardとauto modeのclassifierが判断する。
`npm`、`pnpm`、`npx`、`make`、`python`、`node`、`curl` のような、中身を前もって読めない実行のパターンを持ってはならない（MUST NOT）。
許可ファイルは `DirectoryAdded` のhookがsandboxの外で書くので、`allow-repo.sh` のパターンは持たない。
共通の設定断片と、閉じた環境用の設定断片は、`sandbox.excludedCommands` を持ってはならない（MUST NOT）。

#### Scenario: allow-repo の実行
- **WHEN** sandboxの有効な端末のセッションで、ユーザーが `/add-dir <path>` を実行する
- **THEN** `DirectoryAdded` のhookが、許可ファイルに1行追加する

#### Scenario: 上流を設定する push
- **WHEN** 管理者の環境の端末のセッションで、新しいブランチを `git push -u origin HEAD` でpushする
- **THEN** pushが通り、`.git/config` に上流が記録される

#### Scenario: セッションからの sync
- **WHEN** 管理者の環境の端末のセッションで、`uskn-harness sync --dry-run` を実行する
- **THEN** sandboxによる書き込みの拒否が出ずに、予定が出力される

#### Scenario: 入れ子の claude
- **WHEN** 管理者の環境の端末のセッションで、Bashから `claude -p` を起動する
- **THEN** 起動した `claude -p` は外側のsandboxの外で動き、自分の設定のsandboxだけに従う

#### Scenario: 閉じた環境の合成
- **WHEN** 閉じた環境で、端末別設定の無いまま合成を求める
- **THEN** 合成は `sandbox.excludedCommands` を持たない

#### Scenario: 廃止したループのパターン
- **WHEN** 管理者の環境で、適用記録の `sandbox.excludedCommands` に `uskn-loop *` がある端末で `sync` を実行する
- **THEN** liveの `sandbox.excludedCommands` から `uskn-loop *` が消える
