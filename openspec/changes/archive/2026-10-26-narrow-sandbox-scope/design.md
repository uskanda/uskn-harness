# Design

## Context

動機はproposal.mdのWhyを見ること。

- syncの設定のマージは、`bin/uskn-harness` のjqの式が行う。集合として扱う配列は、`is_set` がパスで決める。今は `permissions` の下の4つだけである
- 端末別設定 `~/.config/uskn-harness/settings.json` は、ユーザーが書くファイルである。syncは作らず、変えない（`user-settings` の要件）。このchangeで、`sandbox-exclude` の下位コマンドだけが書けるようにする
- bash-guardは、コマンドを単語と演算子に分け、単純なコマンドごとに `simple_command` で判定する。パイプ、`&&`、`;`、かっこの位置は、演算子として分かる
- `excludedCommands` は、コマンド全体の先頭がパターンに当たるときだけ、そのコマンドをsandboxの外で動かす
- sandboxが作業ツリーに被せる空のファイルは、`/dev/null` を写したもので、Pythonの `os.path.isfile` は偽を返す
- `~/.claude/settings.json` は、sandboxの中から書けない。`uskn-harness` は `excludedCommands` にあり、単独で実行すればsandboxの外で動く

## Goals / Non-Goals

**Goals:**

- sandboxの外に出すコマンドを、コードを直さずに端末で足せる
- 外に出す道具の一覧の正本を、Claude Codeの設定の1つにする

**Non-Goals:**

- `gh` と `glab` による別のリポジトリの操作を、bash-guardで拒否すること
- 設定断片の既定値を、スキルから全端末向けに足すこと。全端末向けにはPRで設定断片を直す

## Decisions

### D1: 線の引き方

sandboxに残すのは、中身を前もって読めない実行である。外に出すのは、効果がコマンドの形から決まる、よく知られた道具である。
外に出した道具の安全は、bash-guardのdenyパターン（別のリポジトリへのgitの書き込み、chezmoi）と、auto modeのclassifierが受け持つ。
`docker` と `ssh` は、sandboxの中では動かない。`docker` は `docker.sock` へ接続できず、`ssh` はsandboxの中継を通らないためである。中に残しても安全にはならない。失敗の後にsandboxの外で再実行されるだけなので、外に出す。

捨てた案は次のとおり。

| 捨てた案 | 理由 |
|---|---|
| 対話のセッションではsandboxを切り、無人のループだけで使う | 対話のセッションで、スクリプトの中の書き込みが再び止まらなくなる |
| sandboxをやめる | ADR-0009で得た、間接の書き込みを止める利点を失う |
| 道具の一覧をハーネスのコードに書く | 道具を足すたびに、ハーネスのコードとテストを直すことになる |

### D2: sync の集合の配列

`is_set` の条件に、`["sandbox", "excludedCommands"]` と `["sandbox", "filesystem", "allowWrite"]` を足す。
3方向の片付けも、この2つを要素ごとに扱う。ハーネスが入れて設定断片から消えた要素だけが、liveから消える。
`denyWrite` は、置き換えのままにする。端末で書き込みの禁止を外せないようにするため。

### D3: sandbox-exclude の下位コマンド

`bin/uskn-harness` に `sandbox-exclude` を足す。引数は `<pattern>`、`--list`、`--remove <pattern>` の3つの形である。
端末別設定の読み書きはjqで行い、書くときは `write_json_atomic` を使う。
足した後と消した後は、`ensure_user_settings` だけを実行してliveに反映する。checkoutの更新やスキルのsymlinkには触れない。
`*` だけのパターンと空のパターンは拒否する。どちらも、すべてのコマンドをsandboxの外で動かすことになるため。

### D4: sandbox-exclude スキル

`skills/sandbox-exclude/SKILL.md` を英語で書く。`disable-model-invocation: true` と `argument-hint` を持たせる。
手順は、パターンの組み立て、中身を読めない実行かどうかの確認、`uskn-harness sandbox-exclude` の単独での実行、`--list` の表示の4つである。
中身を読めない実行の例は、`npm`、`pnpm`、`npx`、`make`、`python`、`node`、`bash`、`sh` とする。

### D5: bash-guard の知らせ

`simple_command` で、コマンドの語がliveの `sandbox.excludedCommands` のどれかのパターンに当たるかを調べ、当たったものを積む。
入力の全体を読み終えた後、演算子（パイプ、`&&`、`;`、かっこ）が1つでもあれば、積んだものをすべて知らせる。
演算子が無くても、道具の前に代入や `sudo` などの語があれば知らせる。
実機で、先頭の `git push` でも後ろにパイプがあるとsandboxの中で動いたため、先頭かどうかではなく、コマンド全体が単独の単純なコマンドかどうかで判定する。
パターンの照合は、bashの `[[ "$words" == $pattern ]]` で行う。`*/allow-repo.sh *` のような絶対パスのパターンも、同じ照合で扱える。
denyを返すときは、知らせを出さない。知らせの出力は、ADR-0009で削除したwarnパターンと同じく `hookSpecificOutput.additionalContext` を使う。
liveの設定はjqで読み、jqが無いときと読めないときは知らせを出さない。

### D6: terms-check

未追跡のファイルの一覧から、通常のファイルでないものを外す。`os.path.exists` の照合を、`os.path.isfile` か `os.path.isdir` に変える。

### D7: ADR-0011

`<docs/adr/0011-narrow-sandbox-scope.md>` に、D1の線の引き方、捨てた案、D2とD3の一覧の持ち方を書く。ADR-0009の決定3と4に、ADR-0011で差し替えた旨の注記を足す。

## Risks / Trade-offs

- `git`、`gh`、`glab` がsandboxの外で動く → 別のリポジトリへのgitの書き込みは、bash-guardが拒否する。`gh` と `glab` による別のリポジトリの操作は、classifierだけが判断する。ADR-0009の前と同じ守りである
- `docker` がsandboxの外で動き、`-v` でホストのディレクトリをつなげば、どこにでも書ける → classifierが判断する。必要なら、端末で `--remove` できるように、既定値でなく端末別設定へ移すことを後で検討する
- 知らせを読んでも、エージェントが単独で実行し直さないことがある → 失敗した後の再実行は、`allowUnsandboxedCommands` のまま残る

## Migration Plan

1. `adopt-bash-sandbox` と `add-dir-records-allow` を、この順でarchiveする
2. このchangeをmainへマージし、各端末で `uskn-harness sync` を実行する。liveの `sandbox.excludedCommands` に11個の道具が入る
3. 戻すときは、設定断片を前の値に戻してsyncを実行する。端末で足した要素は残る
