# grilling 記録: sandbox-rules-revisit

ADR-0011の後も、sandboxの中で失敗し、sandboxの外で再実行するコマンドが多い。また、sandboxが作業ディレクトリに作る空のファイルを、変更と誤って数えることがある。この2つを直す。
grillingの前に、2026-10-26から2026-10-31までのtranscriptを集計した。

- sandboxの中のBashは4887回、`dangerouslyDisableSandbox: true` の呼び出しは846回だった。846回のうち546回は、switchboardの1つのセッションに集中していた
- sandboxが原因と分かる失敗は、多い順に次のとおり
  - Unixソケット（39回）：D-Bus経由の `systemctl --user`、`journalctl`、`secret-tool`、ソケットで待つGoのテスト
  - 空のファイルの読み取り（28回）：`grep -r`、ugrep、製品リポジトリの検証が `.bash_profile` を開く
  - ルートの外への書き込み（20回）
  - `.git/config` への書き込み（12回）：gitが先頭に無い複合コマンド
  - この端末のIPに解決されるホスト（8回）
- 一度失敗した後、sandboxの中で動く `sed -i` や `python3 -` まで、sandboxの外で動かし続けていた。要約の後のセッションでも続いていた

調べて分かったことは次のとおり。

- 公式の文書（code.claude.com/docs/en/sandboxing）によると、まだ無い保護パスへの書き込みを禁じるため、sandboxは実行中だけ0バイトのファイルを作り、終わると消す。設定では変えられない
- その0バイトのファイルは、sandboxの中からは `/dev/null` の写しに見え、ホストからは0バイトの通常のファイルに見える。sandboxの中のコマンドが動き続けている間、sandboxの外の `git status` にも11個が未追跡として出た
- `tree_fingerprint` と `Makefile` の `CHANGED` は、未追跡のファイルを数えるので、この0バイトのファイルを変更と数える
- `sandbox.network.allowAllUnixSockets` でUnixソケットを許せる。パスを選んで許す `allowUnixSockets` はmacOSだけである。文書は `docker.sock` を許すとホストを操作できると警告している
- この端末のIPに解決されるホストは、`sandbox.network.allowedDomains` に足すと通る
- `cd` を含む複合コマンドは、全体がsandboxの中で動く。`excludedCommands` は、呼び出しの全部のコマンドが一致するときだけ当たる
- このユーザーは `docker` グループに入っている

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| Unixソケット | 設定断片で `sandbox.network.allowAllUnixSockets: true` にし、全端末で許す | 第1ラウンド Q1 |
| この端末のIPに解決されるホスト | `/sandbox-allow-host <host>` を足す。スキルは `uskn-harness sandbox-allow-host` を呼び、端末別設定の `sandbox.network.allowedDomains` に足す。syncはこの配列を集合として扱う。`/sandbox-exclude` と同じ作りにする | 第1ラウンド Q2 |
| 途中に出てくる外の道具 | sandboxの中で失敗すると分かっているものは、bash-guardが拒否する。対象は、`.git/config` に書くかネットワークを使うgitの下位コマンド（`push`、`fetch`、`pull`、`clone`、`switch`、`checkout`、`branch`、`config`、`remote`、`submodule`）と、sandboxの中で動かない道具（`glab`、`docker`、`ssh`、`scp`、`claude`）である。ほかの道具は今までどおり知らせる | 第1ラウンド Q3 |
| sandboxを外す癖 | `dangerouslyDisableSandbox: true` の呼び出しのたびに、bash-guardが `additionalContext` で、外すのはsandboxの制限による失敗を見たときだけだと知らせる | 第1ラウンド Q4 |
| sandboxの0バイトのファイル | `tree_fingerprint` と `Makefile` の `CHANGED` は数えない。判定は `lib/common.sh` に1つ置く。ユーザー層の指示に、`git status` に出るこの空のファイルはsandboxのものだと1行足す | 第1ラウンド Q5 |
| `docker.sock` の危険 | 受け入れる。sandboxが止めるのは、スクリプトの間接の書き込みが意図せずルートの外に及ぶことで、dockerでわざと抜けるコードは対象でない。ADRの「引き受けるコスト」に書く | 第2ラウンド Q6 |
| 0バイトのファイルの見分け方 | 形で見分ける。リポジトリの直下で `.` から始まる名前と、`.claude/` の直下の名前のうち、0バイトの未追跡のファイルである。直下の0バイトの `.nojekyll` なども数えなくなるが、受け入れる | 第2ラウンド Q7 |
| `allowedDomains` の前提 | 空でない `allowedDomains` が、`WebFetch(domain:*)` による全ホストの許可を狭めないことを、実装の最初の手順で実機で確かめる。狭める場合は止めてユーザーに戻す | 最終確認 |
| ADRとchange | ADR-0012で、ADR-0011の決定2と6を差し替える。changeは `sandbox-rules-revisit` の1つにする | 最終確認 |

## 後回しにしたもの

- 製品リポジトリの検証が、sandboxの中で0バイトのファイル（`.bash_profile` など）を開いて失敗すること。その製品の側で直す
- `gh` と `glab` による別のリポジトリの操作を、bash-guardで拒否すること（ADR-0011から引き続き）

## 状態

frontierは空。共有理解は2026-11-01に確認済み。
