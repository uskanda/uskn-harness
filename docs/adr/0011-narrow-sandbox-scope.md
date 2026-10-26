# ADR-0011: sandboxに残すのは、効果を前もって判断できない実行だけにする

- 状態：採用（2026-10-26）。ADR-0009の決定3と4を差し替える
- 決定者：uskanda（change `narrow-sandbox-scope` のgrilling。第1ラウンドのQ1からQ4、第2ラウンドのQ5からQ8）
- 関連：ADR-0009、ADR-0010

## 文脈

ADR-0009でsandboxを入れた後、実際の作業で6つの制約に当たった。

- 作業ディレクトリのリポジトリの `.git/config` に書けず、gitの上流の設定が失敗する
- `excludedCommands` は、1つの単純なコマンドだけから成り、その先頭がパターンと一致するコマンドにしか当たらない
- `~/.cache/gh` などのキャッシュに書けない
- この端末自身のIPに解決されるホスト（同じ端末で動かすGitLab）へ接続できない
- 作業ディレクトリに `/dev/null` の写しが被さり、`git add -A` が失敗し、terms-checkがCIと食い違う
- 入れ子の `claude -p` が、外側のsandboxに閉じ込められる

sandboxが役に立つのは、中身を前もって読めない実行が、間接にルートの外へ書くのを止めるときである。
一方、効果がコマンドの形から決まる道具は、bash-guardとauto modeのclassifierが判断できる。

## 決定

1. sandboxに残すのは、中身を前もって読めない実行（`npm`、`pnpm`、`npx`、`make`、`python`、`node`、`curl` など）である
2. 効果がコマンドの形から決まるよく知られた道具は、sandboxの外で動かす。設定断片の既定値は、`git`、`gh`、`glab`、`docker`、`mise`、`claude`、`uskn-harness`、`uskn-loop`、`chezmoi`、`ssh`、`scp` の11個である
3. 一覧はコードに書かず、`sandbox.excludedCommands` のデータとして持つ。syncはこの配列と `sandbox.filesystem.allowWrite` を集合として扱う
4. 端末で足すときは、ユーザーが `/sandbox-exclude <tool>` を打つ。スキルは `uskn-harness sandbox-exclude` で端末別設定に足し、ユーザー層の設定を反映し直す。全端末向けの既定値は、設定断片へのPRで足す
5. sandboxの中で書けるのは、`~/.cache`、`~/.npm`、`~/.local/share/mise`、`~/.local/share/pnpm`、`~/.local/state` である。`denyWrite` で、ハーネスの状態ディレクトリを禁止する
6. 外に出す道具がコマンドの先頭にないとき、bash-guardが `additionalContext` で、単独で実行し直すよう知らせる。一覧はliveの設定から読む
7. terms-checkは、通常のファイルとディレクトリだけを実在と数える

## 検討した代替案

| 案 | 退けた理由 |
|---|---|
| 対話のセッションではsandboxを切り、無人のループだけで使う | 対話のセッションで、スクリプトの中の書き込みが再び止まらなくなる |
| sandboxをやめる | ADR-0009で得た、間接の書き込みを止める利点を失う |
| `docker`、`ssh`、`scp` をsandboxに残す | sandboxの中ではそもそも動かない。失敗の後にsandboxの外で再実行されるだけで、安全にはならない |
| 道具の一覧をハーネスのコードに書く | 道具を足すたびに、ハーネスのコードとテストを直すことになる |
| スキルで足したコマンドを、ハーネスの設定断片に書いて全端末に配る | 作業中のリポジトリの外にあるハーネスを書き換えることになり、`/add-dir` かPRが要る |
| 途中に出てくる外の道具を拒否する | sandboxの中でも問題なく動く読み取りのgitまで止めてしまう |

## 結果

- 良い点：gitの上流の設定、`gh` のキャッシュ、入れ子の `claude -p`、`docker` と `ssh` が、sandboxに止められなくなる。スクリプトとビルドの間接の書き込みは、今までどおり止まる
- 引き受けるコスト：`gh` と `glab` による別のリポジトリの操作と、`docker` の `-v` によるホストのディレクトリの指定は、auto modeのclassifierだけが判断する。ADR-0009の前と同じ守りである
- 後回し：`gh` と `glab` による別のリポジトリの操作を、bash-guardで拒否すること
