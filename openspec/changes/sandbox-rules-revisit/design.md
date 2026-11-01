# Design

## Context

動機はproposal.mdのWhyを、調べた事実はgrilling.mdを見ること。

- 設定断片 `templates/user/settings.json` の `sandbox` には、`network` の節が無い。ネットワークは、`permissions.allow` の `WebFetch(domain:*)` で全ホストに通している
- syncの集合の配列は、`bin/uskn-harness` のjqの関数 `is_set` がパスで決める。今は `permissions` の4つと、`sandbox` の2つである
- `uskn-harness sandbox-exclude` は、端末別設定の1つの配列に要素を足し、外し、一覧を出す。足した後は `ensure_user_settings` だけを実行する
- bash-guardは、単純なコマンドごとに、liveの `excludedCommands` に当たる道具を集める。先頭にないものがあれば、`additionalContext` で知らせる
- `tree_fingerprint` は、`git status --porcelain` と未追跡のファイルの中身のハッシュを指紋に含める。`git status --porcelain` は、未追跡のファイルしか無いディレクトリを `?? .claude/` の1行にまとめる
- `Makefile` の `CHANGED` は、`git ls-files --others --exclude-standard` で未追跡のファイルを足す
- `templates/user/CLAUDE.md` は1747バイトで、上限は2000バイトである

## Goals / Non-Goals

**Goals:**

- sandboxの中で失敗すると分かっている形を、実行の前に止めるか、sandboxの中で動くようにする
- 仮ファイルを、ハーネスのどの部分も同じ形で見分ける

**Non-Goals:**

- terms-checkの名前の実在の数え方を変えること。ホストからは仮ファイルが通常のファイルに見えるが、terms-checkが走るのは主にCIとhookで、実害を見ていない
- 製品リポジトリの検証が、sandboxの中で仮ファイルを開いて失敗すること（grilling.mdの後回し）
- sandboxの外での再実行を、設定で禁じること

## Decisions

### D1: Unixソケット

設定断片に `"network": {"allowAllUnixSockets": true}` を足す。`user-settings.bats` が値を確かめる。
macOSでこのキーが何を許すかは、文書に書かれていない。Seatbeltの既定でソケットが通るなら、何も変わらない。
`allowUnixSockets` のパスの一覧は、Linuxでは読まれないので使わない。

### D2: 接続先の下位コマンドとスキル

`bin/uskn-harness` に `sandbox-allow-host` を足す。形は `sandbox-exclude` と同じで、`<host>`、`--list`、`--remove <host>` の3つである。
2つの下位コマンドは、端末別設定の配列を1つ扱う点が同じである。共通の部分は、配列のパスを受け取る関数にまとめる。
入力の拒否だけが下位コマンドごとに違う。`sandbox-allow-host` は、空、`*` を含むもの、`https://` で始まるもの、`/` を含むものを拒否する。
`is_set` の条件に `["sandbox", "network", "allowedDomains"]` を足す。
スキル `skills/sandbox-allow-host/SKILL.md` は、`sandbox-exclude` のスキルと同じ構成にし、英語で書く。`disable-model-invocation: true` を持たせる。

実装の前に、空でない `allowedDomains` が全ホストの許可を狭めないことを確かめる（tasks.mdの1）。
確かめ方は、入れ子の `claude -p --settings <file>` である。`allowedDomains` に1つのホストだけを入れた設定で起動する。そのセッションに、sandboxの中から `curl -sI https://github.com` を実行させる。
拒否されたら作業を止め、ユーザーに戻す。そのときは、D2の作りを決め直す必要がある。

### D3: 途中に出てくる、sandboxの中で動かない道具の拒否

bash-guardは、今の知らせと同じ場所で道具を集めるときに、sandboxの中で失敗する形かどうかも判定する。
判定の一覧は、bash-guardの中に2つの定数として持つ。gitの下位コマンドの10個と、道具の5つである。
liveの `excludedCommands` は、外に出す道具の一覧の正本で、データとして持つ（ADR-0011）。
一方、この2つの定数は、道具がsandboxの中でどう振る舞うかという事実である。設定で変える値ではないため、コードに書く。
拒否するのは、liveの `excludedCommands` にも当たる場合だけである。当たらない道具は単独で実行してもsandboxの中で動くので、単独での実行を促しても直らない。
拒否の理由は1つの文にまとめ、当たった道具を並べる。gitのときは、`git -C <dir>` を使えることも書く。
拒否は、denyパターンの拒否と同じ出力の形（`permissionDecision: deny`）にする。両方に当たるときは、理由をつなげる。

捨てた案は次のとおり。

| 捨てた案 | 理由 |
|---|---|
| `updatedInput` で、先頭の `cd <dir> &&` を外して書き換える | 実行される文字列を、エージェントの知らないうちに変えることになる。パイプやかっこには使えない |
| 途中に出てくる外の道具をすべて拒否する | `gh pr view | jq` のように、sandboxの中で動く形まで止まる（第1ラウンドQ3） |

### D4: sandboxを外した呼び出しの知らせ

bash-guardは、`tool_input.dangerouslyDisableSandbox` を読む。`true` のとき、`additionalContext` に1文を足す。
文は英語で、ほかの知らせと同じ書き方にする。内容は、sandboxを外すのは、そのコマンドがsandboxの制限で失敗したのを見たときだけということである。あわせて、ルートの中の編集と読み取りはsandboxの中で動くことを書く。
D3の知らせと両方に当たるときは、1つの `additionalContext` につなげる。

### D5: 仮ファイルの判定

`lib/common.sh` に、未追跡のファイルから仮ファイルを除いて出す関数を1つ置く。
仮ファイルの形は、パスが `.<name>` か `.claude/<name>` で（`/` をそれ以上含まない）、大きさが0のファイルである。
通常のファイルのほか、`/dev/null` の写しも対象にする。仮ファイルは、sandboxの中からは `/dev/null` の写しに、ホストからは0バイトの通常のファイルに見えるため。
`tree_fingerprint` は、未追跡のファイルをこの関数から得る。`git status --porcelain` には `--untracked-files=no` を付け、未追跡のファイルは中身のハッシュの列だけで数える。
`Makefile` の `CHANGED` も、`git ls-files --others` の代わりに、この関数を `lib/common.sh` の読み込みから呼ぶ。

捨てた案は次のとおり。

| 捨てた案 | 理由 |
|---|---|
| 決まった名前の一覧で見分ける | Claude Codeの版で名前が変わる。文書の一覧にも無い `.gitmodules` と `.ripgreprc` が現れた（第2ラウンドQ7） |
| グローバルなgitignoreで無視させる | 新しく `.mcp.json` などを足すときに `git status` に出なくなる。`~/.gitconfig` はdotfilesが管理している（第1ラウンドQ5） |

### D6: ユーザー層の指示

`templates/user/CLAUDE.md` に、仮ファイルの1行を英語で足す。内容は、`.bashrc` や `.claude/agents` のような0バイトの未追跡のファイルは、sandboxが置いて後で消すもので、commitや削除をしないことである。
2000バイトの上限に収まるよう、200バイト以内にする。

### D7: ADR

ADR-0012を書き、ADR-0011の決定6（途中に出てくる外の道具は知らせるだけ）を差し替える。
ADR-0009の決定5（ネットワークは `WebFetch(domain:*)` で通す）には、`allowedDomains` で端末のホストを足すことを補う。
引き受けるコストに、`docker.sock` とD-Busを通じてsandboxを抜けられることを書く（第2ラウンドQ6）。
grillingでは「ADR-0011の決定2と6」としたが、決定2（外に出す道具の既定値）は変えない。差し替えるのは決定6だけである。

## Risks / Trade-offs

- `docker.sock` やD-Busを通じて、sandboxの中のコードがsandboxを抜ける → 受け入れる。ADR-0012に書く。sandboxが止めるのは、意図しない間接の書き込みである
- 空でない `allowedDomains` が、全ホストの許可を狭める → 実装の最初に確かめ、狭めるなら止めて決め直す
- 指紋の計算を変えると、実行中のセッションの `baseline` と一致しなくなる → 次のStopで1回だけ検証が走るだけで、結果は変わらない
- `fetch` や `clone` は、httpsなら複合コマンドでもsandboxの中で動くが、拒否される → 拒否は実行の前に止まり、単独で実行し直せば通る。失敗してから再実行するより安い
- 直下の0バイトの `.nojekyll` などを足しても、verify gateが走らない → 受け入れる（第2ラウンドQ7）
- sandboxを外すたびに知らせが入り、文脈が少し増える → 1文に抑える

## Migration Plan

各端末で `uskn-harness sync` を実行すると、設定断片とユーザー層の指示が反映される。新しい設定を読むのは、その後に始めたセッションである。
戻すときは、設定断片から `network` の節を消し、syncを実行する。3方向の片付けで、liveからも消える。
