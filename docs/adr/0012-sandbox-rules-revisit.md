# ADR-0012: sandboxの中で失敗すると分かっている形は、実行の前に止めるか、sandboxの中で動くようにする

- 状態：採用（2026-11-01）。ADR-0011の決定6を差し替え、ADR-0009の決定5を補う
- 決定者：uskanda（change `sandbox-rules-revisit` のgrilling。第1ラウンドのQ1からQ5、第2ラウンドのQ6とQ7）
- 関連：ADR-0009、ADR-0011

## 文脈

ADR-0011の後も、sandboxの中で失敗し、sandboxの外で再実行するコマンドが多かった。
2026-10-26から2026-10-31までに、sandboxの中のBashは4887回、`dangerouslyDisableSandbox: true` の呼び出しは846回あった。
sandboxが原因と分かる失敗は、多い順に次のとおりである。

- Unixソケットの禁止：D-Bus経由の `systemctl --user`、`journalctl`、`secret-tool`、ソケットで待つテスト
- sandboxが保護パスに置く0バイトのファイルの読み取り：`grep -r` などが `.bash_profile` を開く
- ルートの外への書き込み
- `.git/config` への書き込み：gitが先頭に無い複合コマンド
- この端末のIPに解決されるホスト

一度失敗した後は、sandboxの中で動く `sed -i` まで、sandboxの外で動かし続けていた。
また、sandboxが置く0バイトのファイル（仮ファイル）を、verify gateの指紋と `verify-fast` の範囲が変更と数えていた。
仮ファイルはコマンドの実行中だけ現れ、名前の一覧は文書に無く、Claude Codeの版で変わる。

## 決定

1. 設定断片で `sandbox.network.allowAllUnixSockets` を `true` にし、全端末でUnixソケットを許す。パスを選ぶ `allowUnixSockets` は、Linuxでは読まれない
2. この端末のIPに解決されるホストは、ユーザーが `/sandbox-allow-host <host>` を打って足す。スキルは `uskn-harness sandbox-allow-host` で端末別設定の `sandbox.network.allowedDomains` に足し、syncはこの配列を集合として扱う。設定断片にはホストを書かない
3. sandboxの外に出す道具が複合コマンドの途中にあり、sandboxの中で失敗すると分かっているとき、bash-guardは拒否し、単独で実行し直すよう促す。gitでは、`.git/config` に書くかネットワークを使う10個の下位コマンドが対象である。`push`、`fetch`、`pull`、`clone`、`switch`、`checkout`、`branch`、`config`、`remote`、`submodule` の10個である。ほかに、`glab`、`docker`、`ssh`、`scp`、`claude` が対象である。gitの下位コマンドの前に `-C`、`-c`、`--git-dir`、`--work-tree`、`--config-env`、`--exec-path` が付くと、`excludedCommands` は当たらない。これも先頭にないものと同じに扱う。liveの `excludedCommands` に当たる道具だけを拒否する。ほかの外の道具は、今までどおり知らせるだけにする
4. `dangerouslyDisableSandbox: true` の呼び出しのたびに、bash-guardは、sandboxを外すのはsandboxの制限による失敗を見たときだけだと知らせる
5. 仮ファイルは形で見分ける。作業ツリーの直下の `.<name>` か、`.claude/<name>` で、大きさが0の未追跡のファイルである。作業ツリーの指紋と `verify-fast` の範囲は、これを数えない。判定は `lib/common.sh` の1つの関数に置く
6. ユーザー層の指示に、仮ファイルはsandboxのもので、commitや削除をしないことを1行で書く

決定2は、ADR-0009の決定5を補う。空でない `allowedDomains` があっても、`WebFetch(domain:*)` による全ホストの許可は狭まらない（2026-11-01に入れ子の `claude -p` で確認）。

## 検討した代替案

| 案 | 退けた理由 |
|---|---|
| `allowUnixSockets` で `docker.sock` などのパスだけを許す | Linuxでは読まれない |
| bash-guardが `updatedInput` で、先頭の `cd <dir> &&` を外して書き換える | 実行される文字列を、エージェントの知らないうちに変えることになる。パイプやかっこには使えない |
| 途中に出てくる外の道具をすべて拒否する | `gh pr view | jq` のように、sandboxの中で動く形まで止まる |
| 仮ファイルを、決まった名前の一覧で見分ける | Claude Codeの版で名前が変わる。文書の一覧にも無い `.gitmodules` と `.ripgreprc` が現れた |
| 仮ファイルを、グローバルなgitignoreで無視させる | `.mcp.json` などを新しく足すときに、`git status` に出なくなる |
| sandboxの外での再実行を、設定で禁じる | sandboxが原因の失敗を、ユーザーの許可の上で外で動かす逃げ道がなくなる |

## 結果

- 良い点：D-Busとソケットを使うコマンド、この端末のホストへの接続が、sandboxの中で動く。途中にgitがある複合コマンドは、実行の前に止まり、単独のコマンドに直される。仮ファイルでverify gateが走らなくなる
- 引き受けるコスト：sandboxの中のコードは、`docker.sock` やD-Busを通じてsandboxを抜けられる。sandboxが止めるのは、スクリプトの間接の書き込みが意図せずルートの外に及ぶことで、わざと抜けるコードは対象でない。httpsの `fetch` や `clone` は複合コマンドでもsandboxの中で動くが、拒否される。直下の0バイトの `.nojekyll` などを足しても、verify gateは走らない
- 後回し：製品リポジトリの検証が、sandboxの中で仮ファイルを開いて失敗すること。その製品の側で直す
