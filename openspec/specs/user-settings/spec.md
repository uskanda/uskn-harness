# user-settings Specification

## Purpose
ユーザー層の `~/.claude/settings.json` を、ハーネスの設定断片と端末別設定からsyncが作る規則。
端末で変えた値を共有の設定へ書き戻さず、ハーネスが入れて要らなくなったものだけをliveから消す。

## Requirements

### Requirement: 設定断片の置き場
ハーネスは設定断片を `templates/user/` の5つのファイルに、JSONのオブジェクトとして置かなければならない（MUST）。
共通の設定断片は `settings.json` である。
環境の種類別の設定断片は、`settings-admin.json` と `settings-confined.json` である。
OS別の設定断片は、`settings-linux.json` と `settings-darwin.json` である。
`make verify` のbatsは、5つのファイルがJSONのオブジェクトとして読めることを確かめる。

#### Scenario: 読めない設定断片
- **WHEN** 設定断片の末尾のかっこを消して `make verify` を実行する
- **THEN** batsが失敗し、ファイルの名前が出る

#### Scenario: 読めない OS 別の設定断片
- **WHEN** `templates/user/settings-linux.json` の末尾のかっこを消して `make verify` を実行する
- **THEN** batsが失敗し、`settings-linux.json` の名前が出る

### Requirement: 設定断片に入れないキー
5つの設定断片は、どれも `hooks` と `modelSettings` を持ってはならない（MUST NOT）。
hookはプラグインが配り、モデルごとのeffortは端末に残さないため。
`make verify` のbatsがこの形を確かめる。

#### Scenario: hooks を足す
- **WHEN** 設定断片に `hooks` を足して `make verify` を実行する
- **THEN** batsが失敗し、キーの名前が出る

#### Scenario: 閉じた環境用に hooks を足す
- **WHEN** `templates/user/settings-confined.json` に `hooks` を足して `make verify` を実行する
- **THEN** batsが失敗し、ファイルとキーの名前が出る

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
- **THEN** 合成は、分ける前の `templates/user/settings.json` と同じキーと、同じ配列の要素を持つ

### Requirement: live へのマージ
syncは合成をliveの `~/.claude/settings.json` へマージしなければならない（MUST）。
オブジェクトはキーごとに再帰的にマージし、それ以外の値は合成の値で置き換える。
合成に無いキーは、liveの値をそのまま残す。
liveが無いときは、合成をそのまま書いて `created` と報告する。
書き換えたときは `updated`、変わらないときは `ok` と報告する。
置き場は `CLAUDE_CONFIG_DIR` があればその下、無ければ `~/.claude` の下。

#### Scenario: Claude Code が書いたキー
- **WHEN** liveが、設定断片に無いキー `feedbackSurveyState` を持つ
- **THEN** sync後もそのキーと値は残る

#### Scenario: ハーネスが持つキーを端末で変えた
- **WHEN** 設定断片の `theme` が `auto` で、liveの `theme` が `dark`
- **THEN** sync後のliveの `theme` は `auto` で、`updated` と報告される

#### Scenario: 2 回目
- **WHEN** syncの直後に、何も変えずにsyncを再実行する
- **THEN** liveは書き換えられず、`ok` と報告される

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

### Requirement: 3 方向の片付け
適用記録にあって合成に無いものを、syncはliveから消さなければならない（MUST）。
キーは値を問わずパスで消す。集合として扱う配列では、要素ごとに消す。
空になったオブジェクトは、親から消す。
適用記録に無いもの、つまりハーネスが入れていないものには触らない（MUST NOT）。

#### Scenario: 設定断片から allow を消した
- **WHEN** 適用記録の `permissions.allow` に `Bash(snap list *)` があり、新しい設定断片には無い
- **THEN** sync後のliveの `permissions.allow` に `Bash(snap list *)` は無い

#### Scenario: 端末で足した allow は残る
- **WHEN** liveの `permissions.allow` に `Bash(make *)` があり、適用記録と合成のどちらにも無い
- **THEN** sync後も `Bash(make *)` は残る

#### Scenario: 設定断片からキーを消した
- **WHEN** 適用記録に `tui` があり、新しい設定断片には無い
- **THEN** sync後のliveに `tui` は無い

### Requirement: 適用記録の更新
liveへの書き込みのあと、syncは合成を適用記録 `~/.local/state/uskn-harness/settings-applied.json` に書かなければならない（MUST）。
置き場は `USKN_STATE_DIR`、`XDG_STATE_HOME` の順に従い、hookの状態ディレクトリと同じ親の下に置く。
適用記録は `sessions/` の外にあり、古いセッションの状態の削除の対象にならない。

#### Scenario: 初めての sync の後
- **WHEN** 適用記録の無い端末でsyncを実行する
- **THEN** 適用記録ができ、中身は合成と同じ

### Requirement: 初回の適用記録
適用記録が無いとき、syncは `templates/user/settings-seed.json` を適用記録とみなさなければならない（MUST）。
このファイルは、dotfilesが最後に配った `dot_claude/settings.json.tmpl` の写しである。
dotfilesが入れて今のハーネスが持たないものを、初回のsyncが3方向の片付けで消すため。

#### Scenario: dotfiles から移る端末
- **WHEN** liveの `hooks` に、dotfilesの入れた `Notification` があり、適用記録は無い
- **THEN** sync後のliveに `hooks` は無い

#### Scenario: 端末別設定に移した allow
- **WHEN** liveの `permissions.allow` に `Bash(sudo pvs)` があり、端末別設定にも `Bash(sudo pvs)` がある
- **THEN** sync後も `Bash(sudo pvs)` は残る

#### Scenario: 端末別設定に移していない allow
- **WHEN** liveの `permissions.allow` に `Bash(sudo pvs)` があり、端末別設定には無い
- **THEN** sync後のliveに `Bash(sudo pvs)` は無い

### Requirement: effort を端末に残さない
syncはliveの `modelSettings` の各モデルから `effortLevel` を消さなければならない（MUST）。
`effortLevel` を消して空になったモデルの項目は消し、空になった `modelSettings` も消す。
`maxEffortLevel` など、`effortLevel` 以外のキーは残す。
Claude Codeの `/effort` がこの場所に書くため、消さないと次のセッションへ値が引き継がれる。

#### Scenario: /effort で変えた後
- **WHEN** liveが `{"modelSettings": {"claude-opus-5-5": {"effortLevel": "low"}}}` を持つ
- **THEN** sync後のliveに `modelSettings` は無く、top-levelの `effortLevel` は設定断片の値

#### Scenario: effort 以外の項目
- **WHEN** liveの `modelSettings` のあるモデルが `effortLevel` と `maxEffortLevel` を持つ
- **THEN** sync後、そのモデルの項目には `maxEffortLevel` だけが残る

### Requirement: 共有の設定へ書き戻さない
syncはliveの値を、設定断片、端末別設定、ハーネスのcheckoutのどれにも書いてはならない（MUST NOT）。

#### Scenario: 端末で値を変えてから sync
- **WHEN** 端末で `/model` と `/effort` を使ってから、syncを実行する
- **THEN** ハーネスのcheckoutは変更の無いままで、端末別設定の中身も変わらない

### Requirement: 読めない JSON
liveか端末別設定がJSONのオブジェクトとして読めないとき、syncはliveと適用記録を変更してはならない（MUST NOT）。
その項目は `conflict` と報告し、読めないファイルの名前を含める。終了コードは0のまま。

#### Scenario: 読めない端末別設定
- **WHEN** 端末別設定の中身がJSONとして読めない
- **THEN** liveと適用記録は変わらず、`conflict` に端末別設定の名前が含まれる

### Requirement: dry-run での設定
`--dry-run` のとき、syncはliveと適用記録を変更してはならない（MUST NOT）。
代わりに、足すキー、変えるキー、消すキーのパスを1行ずつ出力する。

#### Scenario: 片付けの予定
- **WHEN** 初回のsyncの前に `sync --dry-run` を実行する
- **THEN** `hooks` を消す予定が出力され、liveは変わらない

### Requirement: 道具だけの導入では設定に触れない
`sync --tools` のとき、syncはliveの設定と適用記録に触れてはならない（MUST NOT）。

#### Scenario: CI の runner
- **WHEN** `sync --tools` を実行する
- **THEN** `~/.claude/settings.json` と適用記録は作られない

### Requirement: 取り除くときの設定
`sync --remove` のとき、syncは適用記録にあるものをliveから消し、適用記録を消さなければならない（MUST）。
消し方は3方向の片付けと同じで、合成を空とみなす。適用記録に無いものには触らない。

#### Scenario: ハーネスを外す
- **WHEN** liveに設定断片の `model` と、端末で足した `Bash(make *)` がある状態で `sync --remove` を実行する
- **THEN** liveから `model` が消え、`Bash(make *)` は残り、適用記録は無くなる

### Requirement: 設定断片の sandbox
共通の設定断片は、`sandbox.enabled` を `true` にしなければならない（MUST）。
管理者の環境用の設定断片は、sandboxの2つの値を持たなければならない（MUST）。
`sandbox.failIfUnavailable` は `false`、`sandbox.allowUnsandboxedCommands` は `true` である。
`failIfUnavailable` は、`bwrap` の無い端末でもClaude Codeを起動できるようにするため。
`allowUnsandboxedCommands` は、sandboxが拒否したコマンドを、auto modeのclassifierの判定で再実行できるようにするため。
閉じた環境用の設定断片も、sandboxの2つの値を持たなければならない（MUST）。
`sandbox.failIfUnavailable` は `true`、`sandbox.allowUnsandboxedCommands` は `false` である。
最低線が同じ値を固定していても、ユーザー層の設定だけを読んで意図が分かるようにするため。
`make verify` のbatsがこの5つの値を確かめる。

#### Scenario: sandbox を切った設定断片
- **WHEN** 設定断片の `sandbox.enabled` を `false` にして `make verify` を実行する
- **THEN** batsが失敗し、キーの名前が出る

#### Scenario: 新しい端末の sync
- **WHEN** sandboxの設定の無い端末でsyncを実行する
- **THEN** liveの `sandbox.enabled` は `true` になる

#### Scenario: 閉じた環境用に外へ出す値を書く
- **WHEN** 閉じた環境用の設定断片で、`sandbox.allowUnsandboxedCommands` を `true` にして `make verify` を実行する
- **THEN** batsが失敗し、キーの名前が出る

### Requirement: sandbox の外で動かすコマンド
管理者の環境用の設定断片の `sandbox.excludedCommands` は、11個の道具に当たるパターン `<tool> *` を持たなければならない（MUST）。
11個とは、`git`、`gh`、`glab`、`docker`、`mise`、`claude`、`uskn-harness`、`uskn-loop`、`chezmoi`、`ssh`、`scp` である。
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
- **WHEN** 管理者の環境の端末のセッションで、`uskn-loop run` の実装役のように `claude -p` を起動する
- **THEN** 起動した `claude -p` は外側のsandboxの外で動き、自分の設定のsandboxだけに従う

#### Scenario: 閉じた環境の合成
- **WHEN** 閉じた環境で、端末別設定の無いまま合成を求める
- **THEN** 合成は `sandbox.excludedCommands` を持たない

### Requirement: sandbox で書けるキャッシュ
共通の設定断片の `sandbox.filesystem.allowWrite` は、3つのディレクトリを持たなければならない（MUST）。
`~/.cache`、`~/.npm`、`~/.local/state` の3つである。
管理者の環境用の設定断片の `sandbox.filesystem.allowWrite` は、2つのディレクトリを持たなければならない（MUST）。
`~/.local/share/mise` と `~/.local/share/pnpm` の2つである。
閉じた環境の合成は、`~/.local/share/mise` と `~/.local/share/pnpm` を持ってはならない（MUST NOT）。hookが動かす道具を、エージェントが差し替えられないようにするため。
共通の設定断片の `sandbox.filesystem.denyWrite` は、ハーネスの状態ディレクトリ `~/.local/state/uskn-harness` を持たなければならない（MUST）。
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

#### Scenario: 閉じた環境の mise の置き場
- **WHEN** 閉じた環境の端末のセッションで、`touch ~/.local/share/mise/x` を実行する
- **THEN** sandboxが書き込みを拒否する

### Requirement: 外部への接続の許可
管理者の環境用の設定断片の `permissions.allow` は `WebFetch(domain:*)` を持たなければならない（MUST）。
管理者の環境のユーザーは、調査などでの外部への接続を、ドメインごとに許可しない。
sandboxは、このルールをBashの接続先にも全ホストの許可として使う。
ただし、この端末のIPに解決されるホストへの接続は、このルールでは通らない。そのホストは、ユーザーが `/sandbox-allow-host` で端末別設定の `sandbox.network.allowedDomains` に足す。
共通の設定断片と、閉じた環境用の設定断片は、`WebFetch(domain:*)` を持ってはならない（MUST NOT）。閉じた環境の接続先は、最低線が決めるため。
設定断片の `sandbox.network.allowedDomains` には、端末ごとのホストを書いてはならない（MUST NOT）。

#### Scenario: 調査での取得
- **WHEN** 管理者の環境のsync後の端末のセッションで、WebFetchが初めてのドメインの文書を取得する
- **THEN** 確認を求められずに取得する

#### Scenario: Bash からの push
- **WHEN** 管理者の環境の端末のセッションで、ルートの中から `git push` をgithub.comへ実行する
- **THEN** sandboxによるネットワークの拒否が出ずに終わる

#### Scenario: 接続先を足した後の全ホスト
- **WHEN** 管理者の環境の端末別設定の `sandbox.network.allowedDomains` に1つのホストを足してsyncする。その後のセッションで、sandboxの中から `curl -sI https://github.com` を実行する
- **THEN** 接続は拒否されない

#### Scenario: 閉じた環境の合成
- **WHEN** 閉じた環境で合成を求める
- **THEN** 合成の `permissions.allow` に `WebFetch(domain:*)` は無い

### Requirement: Unixソケットの許可
管理者の環境用の設定断片は、`sandbox.network.allowAllUnixSockets` を `true` にしなければならない（MUST）。
D-Busを使う `systemctl --user`、`journalctl`、`secret-tool` と、Unixソケットで待つテストを、sandboxの中で動かすため。
Linuxには、ソケットのパスを選んで許可する設定が無い。
共通の設定断片と、閉じた環境用の設定断片は、`sandbox.network.allowAllUnixSockets` を持ってはならない（MUST NOT）。
`make verify` のbatsがこれらの値を確かめる。

#### Scenario: ソケットを禁じた設定断片
- **WHEN** 管理者の環境用の設定断片の `sandbox.network.allowAllUnixSockets` を消して `make verify` を実行する
- **THEN** batsが失敗し、キーの名前が出る

#### Scenario: ユーザーのsystemd
- **WHEN** 管理者の環境のsync後のLinuxの端末のセッションで、sandboxの中から `systemctl --user is-system-running` を実行する
- **THEN** `Failed to connect to bus` で失敗しない

### Requirement: 閉じた環境で持ち込まない端末別設定のキー
閉じた環境の間、syncは、端末別設定のうちsandboxを緩めるキーを外してから重ねなければならない（MUST）。
外すのは次のとおり。

- `sandbox.excludedCommands` と `sandbox.allowUnsandboxedCommands`
- `sandbox.network.allowedDomains` と `sandbox.network.allowAllUnixSockets`
- 値が `false` の `sandbox.failIfUnavailable` と `sandbox.enabled`
- `sandbox.filesystem.allowWrite` の要素
- `permissions.allow` のうち、`WebFetch` だけの要素と、`WebFetch(domain:` で始まり `*` を含む要素
- `permissions` の下の `defaultMode`

syncは外したキーのパスを `warn` の1行で報告し、終了コードは0のままにする。端末別設定のファイルは変えない。

#### Scenario: 端末別設定に外へ出すコマンドがある
- **WHEN** 閉じた環境で、端末別設定の `sandbox.excludedCommands` に `terraform *` がある状態でsyncを実行する
- **THEN** liveの `sandbox.excludedCommands` に `terraform *` は無く、`warn` にそのパスが含まれ、端末別設定は変わらない

#### Scenario: 外さないキー
- **WHEN** 閉じた環境で、端末別設定の `model` が `sonnet` の状態でsyncを実行する
- **THEN** liveの `model` は `sonnet`

### Requirement: 閉じた環境の書く許可
閉じた環境用の設定断片の `permissions.allow` は、`Edit` と `Write` を持たなければならない（MUST）。
`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` のある `claude -p` では、権限モードがdefaultに戻り、許可の無いファイルの編集は確認を待って止まるため。
`make verify` のbatsがこの2つの要素を確かめる。

#### Scenario: 許可を消した設定断片
- **WHEN** `templates/user/settings-confined.json` の `permissions.allow` から `Write` を消して `make verify` を実行する
- **THEN** batsが失敗し、`Write` の名前が出る

### Requirement: 閉じた環境で持たないキー
閉じた環境の合成は、`remoteControlAtStartup` と、値が `auto` の、`permissions` の下の `defaultMode` を持ってはならない（MUST NOT）。
この2つは、管理者の環境用の設定断片に置く。
`make verify` のbatsが、端末別設定の無い閉じた環境の合成を求めて確かめる。

#### Scenario: 閉じた環境の合成
- **WHEN** 閉じた環境で、端末別設定の無いまま合成を求める
- **THEN** 合成に `remoteControlAtStartup` は無く、`permissions` の下に `defaultMode` は無い

#### Scenario: 管理者の環境の合成
- **WHEN** 管理者の環境で合成を求める
- **THEN** 合成の `permissions` の下の `defaultMode` は `auto` で、`remoteControlAtStartup` は `true`

### Requirement: OS別の許可
Linuxだけで意味を持つ許可は、`settings-linux.json` に置かなければならない（MUST）。
共通の設定断片と環境の種類別の設定断片は、それらを持ってはならない（MUST NOT）。
対象は次の6つである。

- `Bash(apt-cache *)`、`Bash(systemctl is-enabled *)`、`Bash(systemctl is-active *)`、`Bash(lscpu)`
- `Read(//sys/devices/system/cpu/**)`、`Read(//usr/lib/**)`

`make verify` のbatsが、この6つの置き場を確かめる。

#### Scenario: macOS の合成
- **WHEN** macOSの端末で合成を求める
- **THEN** 合成の `permissions.allow` に `Bash(apt-cache *)` と `Bash(lscpu)` は無い

#### Scenario: Linux の合成
- **WHEN** Linuxの端末で合成を求める
- **THEN** 合成の `permissions.allow` に6つの要素がある

### Requirement: 合成の出力
`uskn-harness print-settings` は、syncが求める合成を、JSONで標準出力に出さなければならない（MUST）。
閉じた環境では、持ち込まないキーを外した後の合成を出す。
liveとのマージと、effortの消去は含めない。
ファイルシステムに書いてはならない（MUST NOT）。
端末別設定が読めないときは、理由を標準エラーに出し、終了コード1で終える。

#### Scenario: 閉じた環境の設定を出す
- **WHEN** 閉じた環境のcheckoutで `uskn-harness print-settings` を実行する
- **THEN** 出力は閉じた環境の合成で、`~/.claude/settings.json` と適用記録は実行の前後で変わらない

#### Scenario: 読めない端末別設定
- **WHEN** 端末別設定の中身がJSONとして読めない状態で `print-settings` を実行する
- **THEN** 標準出力は空で、標準エラーに端末別設定の名前が出て、終了コードは1
