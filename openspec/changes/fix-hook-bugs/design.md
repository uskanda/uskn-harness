## Context

動機はproposal.mdのWhyにある。直す対象は、監査が見つけた13項目である。要件はこの変更のdelta specsにある。
hookはbashとjqで書き、失敗してもセッションを止めない（終了コード0）契約を持つ。
bash-guardの判定はコマンド文字列への正規表現だけで、引用符、heredoc、gitのオプションを区別できていなかった。
`terms-check` は `2>/dev/null || true` でpythonの異常終了を握りつぶしていた。
`sync` は失敗の数を数えていたが、終了コードに反映していなかった。

## Goals / Non-Goals

**Goals:**
- エージェントは許可ファイルを書けない。境界の解除は、ユーザーの依頼で動く `/allow-repo` だけが足す
- センサー（`terms-check`、`make verify`、`sync`、bats）は、失敗を終了コード0で隠さない
- bash-guardの報告された取りこぼしと誤検知を直す。直すのは字句解析で扱える範囲に限る

**Non-Goals:**
- bash-guardを完全なシェルの解析器にすること。specのとおり、取りこぼしは誤検知より許す
- journal系のhookとスキル。別の変更がjournalの仕組みごと扱う
- hookの `if` 欄、Stop gate用の速い検証、block後の再検証、`CLAUDE_PROJECT_DIR` とgitルートの統一
- エージェントがBashで `allow-repo.sh` を直接実行することの防止（後述）

## Decisions

### 許可ファイルは解除できない拒否にする

`path_allowed` は状態ディレクトリ全体を許可リストに入れていた。
状態ディレクトリはhookが書く場所なので許可リストには残し、`sessions/*/allow` だけを除く。
write-guardは実体が許可ファイルのパスを、許可ファイルの中身に関係なく拒否する。
状態ディレクトリを `/allow-repo` しても解除できないようにするため、判定は `path_allowed` より前に置く。

bash-guardは2つの方法で拒否する。

- 文字列の照合：コマンドが `uskn-harness/sessions/<id>/allow` か、実際の状態ディレクトリのパスに続く `sessions/<id>/allow` を含む
- 書き込み先の解決：リダイレクト先と書く操作の対象を実体に解決し、それが許可ファイル

文字列の照合は読むだけの `cat` も拒否する。読むには `allow-repo.sh --list` があるので、理由の文でそれを案内する。
`python3 -c` の中の文字列のように、書き込み先として解析できない書き方も文字列の照合で拾える。

`/allow-repo` スキル自身は `allow-repo.sh --session <sid8> <path>` を実行するだけで、許可ファイルのパスを書かない。そのため拒否されない。

### chezmoi の拒否は source directory の許可で解除する

`chezmoi apply` が書くのは `$HOME` 全体で、`add` や `re-add` が書くのはsource directoryである。
`$HOME` 全体を `/allow-repo` するのは広すぎる。ユーザーが自然に言うのは「dotfilesを直してよい」なので、source directoryを解除の鍵にする。
source directoryは、コマンドの `--source`/`-S`、`chezmoi source-path`（読むだけ、5秒の上限）、`~/.local/share/chezmoi` の順に決める。
比較は両側の実体で行う。`~/.local/share/chezmoi` が `~/dotfiles` へのsymlinkでも、`/allow-repo ~/dotfiles` で解除できる。

解除に使うのはセッションの許可ファイルだけで、プロジェクトルートや `/tmp` の許可リストは使わない。
dotfilesのリポジトリそのもので作業していても、`chezmoi apply` は作業ツリーの外（`$HOME`）を書き換えるからである。
`chezmoi source-path` は、chezmoiの書き込み系の下位コマンドを見つけたときだけ実行する。ほかのコマンドでは余計なプロセスを起こさない。
許可ファイルが無くても実行するのは、拒否の理由の文に正しいsource directoryを書くためである。

下位コマンドの判定では、値を取るオプション（`-S`、`-D`、`-c`、`--config`、`-o` など）の値を読み飛ばす。値を取らないオプション（`-v`、`--force`）は1語として飛ばす。
別の案は「コマンドのどこかに `apply` があれば拒否」で、`chezmoi cat ~/apply` のような誤検知を生むので採らない。

### bash-guard は字句解析してから判定する

判定の前に、コマンドを語と演算子に分ける。字句解析はawkで書き、`LC_ALL=C` で動かす。BSD awkとmawkでも同じに動くよう、POSIXの範囲に限る。

- heredocの本文は行単位で先に取り除く。`git commit -F - <<'EOF'` の本文に書いた文を、コマンドとして読まないため
- 単引用符、二重引用符、文字の前の `\` を外して語にする。`$(...)` とバッククォートは、括弧の対応を数えて1語に含める
- `;`、`&&`、`||`、`|`、`&`、改行、`(`、`)` で単純コマンドに区切る
- リダイレクト（`>`、`>>`、`&>`、`N>` など）は演算子として分け、次の語を書き込み先とする。`>&2` のような複製は書き込み先にしない

単純コマンドごとに、先頭の代入（`GIT_DIR=...` は覚える）、`env`、`sudo`、`command`、`exec`、`time`、`nohup`、予約語（`{`、`if` など）を読み飛ばして、コマンド名を決める。
作業ディレクトリは `cwd` から始め、`cd` と `pushd` で動かす。`(` と `)` の内側での移動は、外に持ち出さない。
相対パスはこの作業ディレクトリから解決する。そのため、`cd /x && touch f` の `f` はルート外として警告できる。

gitは、`-C`、`-c`、`--git-dir`、`--work-tree`、`--namespace`、`--config-env` の値を読み飛ばし、最初の語を下位コマンドとする。
下位コマンドが書き込み操作で、対象のリポジトリがルート外なら拒否する。対象は `--git-dir`、`--work-tree`、`-C` を重ねた結果、作業ディレクトリの順に決める。

書く操作の対象は、コマンドごとに決める。

- `cp`、`install`、`rsync`：`-t` の値、無ければ最後の引数
- `ln`：最後の引数（リンクを作る場所）。引数が1つなら作業ディレクトリに作るので見ない
- `mv`、`rm`、`mkdir`、`touch`、`tee`、`rmdir`：オプションでない引数すべて
- `sed -i`：`-e` と `-f` が無ければ最初の引数が式なので除く。残りの引数がファイル

`$` で始まる語（変数やコマンド置換）は値が分からないので判定しない。
1回の判定にかかる時間は、手元の計測で100ミリ秒ほどである（jqでの入力の読み取りを含む）。

別の案として、`shlex` で解析するpythonの補助スクリプトも考えた。hookはbashとjqで動くという前提を崩し、python3が無い環境で黙って何もしなくなるので採らない。

### terms-check は CLI では失敗を隠さない

pythonの異常終了は、CLIでは標準エラーに出して終了コード2で返す。hookでは従来どおり終了コード0で黙る。
ファイルはバイト列で読み、NULバイトを含むものは中身の照合から外す。それ以外は `errors="replace"` でUTF-8として読む。
python3が無いとき、CLIでは `VERIFY_STRICT=1` なら終了コード1、そうでなければ終了コード0で飛ばす。hookでは常に黙る。
`Makefile` の `verify-terms` は `VERIFY_STRICT=$(VERIFY_STRICT)` を明示して渡す。`make` の引数で与えた変数が、環境変数として渡るかどうかに頼らない。
hookでの対象の絞り込みは `hooks.json` のmatcherではなくスクリプトで行う。matcherはツール名しか見られないからである。

### sync は失敗を数えて終了コードに出す

`note fail` の数が1以上なら、`done` の行のあとで標準エラーに要約を出し、終了コード1で終わる。`--tools` も同じ。
checkoutの更新の失敗は、既存のspec（fast-forwardできないときは終了コード0）に合わせて `warn` として数える。
`check_duplicates` の予約名の判定は、`|` の右側の `while` で `exit 2` していたため、subshellだけが終わっていた。重複の判定と同じく、主のシェルで結果を受け取ってから止める。

### スキルの frontmatter は YAML として解析する

6つのgitスキルの `description` は `Optional argument: …` を引用符なしで含み、YAMLとしては不正だった。他のスキルと同じく ` - ` に直す。
`verify-skills` は、python3とPyYAMLで全 `SKILL.md` のfrontmatterを解析する。Pythonのコードは `Makefile` の `define` に置き、環境変数としてpython3に渡す。
`bin/` に実行ファイルとして置くとshellcheckの対象になるので避けた。
python3かPyYAMLが無ければskipし、`VERIFY_STRICT=1` では失敗にする。
CIのworkflowは `import yaml` に失敗したときだけ、`apt-get install python3-yaml` で入れる。`skills-ref` はピンの仕組みの外にあるので、ここでは使わない。

### timeout が無い環境の上限

`lib/common.sh` に `with_timeout <秒> <コマンド...>` を置く。`timeout`、`gtimeout`、perlの順に使い、どれも無ければ上限なしで実行する。
perlの実装はforkした子を新しいprocess groupに入れ、`alarm` で時間が来たらgroup全体にTERM、1秒後にKILLを送って124で終わる。
GNUの `timeout` もprocess groupごと止めるので、`make` が起こしたbatsも残らない。perlはmacOSに標準で入っている。
verify gateは、テストで打ち切りを試せるよう、上限を `USKN_VERIFY_TIMEOUT`（既定570秒）で変えられるようにする。

### テストの判定

`[ A ] && [ B ]` は、Aが偽でもbatsの失敗にならない。`set -e` は `&&` の途中の失敗では止まらないからである。1行に1つの判定へ分ける。
行の途中の `! grep` も同じ理由で失敗にならない。`refute() { ! "$@"; }` という補助関数を各ファイルに置き、`refute grep -q ...` と書く。関数の戻り値は `set -e` の対象になる。
判定を直すと、`textlint-check.bats` のリポジトリ設定のテストが失敗し始めた。
`ls .textlintrc .textlintrc.*` は片方が無いだけで非ゼロを返すため、`.textlintrc.json` だけを置いたリポジトリでハーネスの設定が使われていた。
ファイルを1つずつ `-f` で確かめる形に直す。textlint-hookのspecの「設定の選択」の要件どおりの振る舞いに戻るだけなので、specは変えない。

ガードのテストは `USKN_GUARD_ALLOW_DIRS` を、`BATS_TEST_TMPDIR` の下の専用ディレクトリだけにする。既定の許可リスト（`/tmp` と `$TMPDIR`）は、別のテストで `USKN_GUARD_ALLOW_DIRS` を外して確かめる。

### そのほか

- `MultiEdit` はClaude Codeのツール一覧に無いので、matcher、スクリプト冒頭のコメント、textlint-hookのspecから外す
- verify gateのStopの出力は `{decision, reason}` だけにする。journal-updateの出力は別の変更が扱う
- 用語集の「verify gate」の定義を「失敗中は終了させない」に直す
- `.gitignore` から使われていない `.harness-session/` を外し、`.claude/worktrees/` を足す

## Risks / Trade-offs

- bash-guardの字句解析は次のものを読まない → specは取りこぼしを許すので、既知の取りこぼしとしてここに残す
  - `bash -c '...'` の中身と `eval`
  - 変数に入れたパス（`cd "$D"`）
  - `xargs` と `find -exec`
  - python3やperlのような別の言語から書くもの
- heredocの本文は行単位で取り除くため、引用符の中に `<<EOF` と書いたコマンドでは、後ろの行を読まずに通すことがある → 取りこぼしの側に倒れるだけで、誤検知は増えない
- chezmoiの下位コマンドのうち、次は拒否の対象外のまま → specの一覧を広げる判断はこの変更ではしない
  - `init --apply`、`destroy`、`forget`、`remove`、`merge-all`、`chattr`、`import`、`git`
- `popd` と `cd -` は作業ディレクトリを追わない → 移動先が分からないので、それ以降は移動前のディレクトリで判定する
- エージェントがBashで `allow-repo.sh` を直接実行すると、許可を足せる → `/allow-repo` スキルも同じコマンドをBashで実行するので、hookからは両者を区別できない。スキルの `disable-model-invocation` と、ユーザーの依頼が要るという規則で抑える
- 状態ディレクトリの `verified` や `baseline` は、今もエージェントが書ける → verify gateを迂回できるが、この変更の範囲（許可ファイル）の外。block後の再検証を扱う変更で合わせて考える
- 許可ファイルのパスを含むだけの読み取りも拒否する → `allow-repo.sh --list` を理由の文で案内する
- `sync` の終了コードが1になると、失敗したマシンのchezmoiのrun_onceは次回も走る → machine-bootstrapのspecが求める振る舞いそのもの
- CIで `apt-get` を使う → PyYAMLはOSのパッケージで、版を直書きしない
