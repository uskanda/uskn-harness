## Context

動機はproposal.mdのWhyにある。要件はこの変更のdelta specsにある。
この変更はfix-hook-bugsの上に積む。bash-guardの字句解析、`is_allow_file`、`with_timeout`、Stopの `{decision, reason}` はそちらで入った。
hookはbashとjqで書き、失敗してもセッションを止めない（終了コード0）契約を持つ。

いまの形は次のとおり。

- `hooks.json` はmatcherでツール名だけを絞る。textlint-checkとterms-checkは、どのファイルのWriteとEditでも起動し、スクリプトの中で拡張子を見て黙る
- verify gateは `stop_hook_active` がtrueのとき何もしない。blockのあとエージェントが直さずに終えても、検証されない
- `make verify` は約57秒かかる。Stop gateは、変更のあった最初のStopで毎回これを走らせる
- ガードとtextlint、termsの検査のルートは、`CLAUDE_PROJECT_DIR` があればそれだけを使う。worktreeに入ると `cwd` は移るが、`CLAUDE_PROJECT_DIR` は開始時のまま残る
- スキルは補助スクリプトを長いパスで呼ぶ。`session-start.sh` の例は次の1行である

```text
${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/session-start.sh --json
```


Claude Codeの側の事実（2.1.282で確認）は次のとおり。

- hookの定義の `if` は、2.1.85から使える。権限の規則を1つだけ書け、ツールのイベントでだけ評価される。一致しなければhookは起動しない
- ファイルのツールの `if` は、作業ディレクトリからの相対で照合する。`Edit(<pattern>)` の規則はEditだけに一致し、WriteやNotebookEditには一致しない
- Stop hookの `stop_hook_active` は、Stop hookによる継続のあとでtrueになる。Claude Code自身も連続の継続を8回で打ち切る
- プラグインの `bin/` は、プラグインが有効な間Bashツールの `PATH` に載る。skills-dirプラグインでも同じで、hookの環境には載らない

## Goals / Non-Goals

**Goals:**
- Markdown以外の書き込みで、textlint-checkとterms-checkのプロセスを起こさない
- 文書を数本かスクリプトを1本変えただけのStopは、数秒で検証を終える
- blockのあとの再試行も検証する。ただし失敗が続いても、1ターンを延々と引き延ばさない
- worktreeに入ったセッションで、ガードが作業場所を拒否しない。検査はworktreeの設定と用語集を読む
- エージェントがverify gateの状態を書き換えて、検証を迂回できないようにする

**Non-Goals:**
- `verify-fast` を他のプロダクトリポジトリへ配ること。テンプレートは別の変更で扱う
- `verify-fast` にopenspecの検証、スキルのfrontmatterの解析、プラグインの検証、designmdを入れること。どれもフルの `verify` に残す
- `/allow-repo` とjournalの補助スクリプトを短いコマンドにすること（後述）
- bash-guardを完全なシェルの解析器にすること。取りこぼしは誤検知より許す方針のまま

## Decisions

### if はツールごとに matcher を分けて書く

`if` は1つの規則しか持てず、`Edit(<pattern>)` はWriteに一致しない。
そこで、同じスクリプトを `Write` と `Edit` の2つのmatcherに1つずつ置き、それぞれにそのツールの規則を付ける。
1つのmatcher `Write|Edit` に同じコマンドを2つ並べる案もあった。
Claude Codeは同じhookの定義を重複として1つにまとめることがある。その場合、片方の `if` を失うおそれがあるので採らない。

grilling-guardも同じ形で `**/openspec/changes/**` に絞る。NotebookEditのmatcherは `if` なしで残す。
NotebookEditの規則を書く利点が無く、スクリプトが拡張子とパスを見て黙るからである。
write-guardとbash-guardは、どの書き込みも見る必要があるので `if` を付けない。

スクリプトの中の絞り込みは残す。`if` を解さない版では全部の書き込みで起動するからである。
terms-checkとtextlint-checkのスクリプトは `.markdown` を対象から外し、`if` の `**/*.md` と同じ条件にする。
版によって検査されるファイルが変わるのを避けるためである。

`if` のパスは作業ディレクトリからの相対なので、作業ディレクトリの外の `.md`（scratchpadの下書きなど）は、新しい版では検査されない。
コミットメッセージとPRの本文は、`commit` と `pr` のスキルが自分でtextlintにかけるので、失うものは小さい。

### verify gate は verify-fast を先に探す

`cwd` のgitルートの `Makefile` か `GNUmakefile` に `^verify-fast:` の行があれば `make verify-fast` を使う。
判定は今の `verify` と同じ `grep` にする。`make -n` は、ターゲットの前提を展開して余計な時間がかかるので使わない。
`package.json` の `verify-fast` は見ない。決めたのはMakefileだけで、npmの規約を足す理由がまだ無い。

### verify-fast は基準からの差分で選ぶ

変更の範囲は `git diff --name-only --diff-filter=d <基準>` と、追跡されていないファイルの和にする。
基準は、HEADと次の参照とのmerge-baseである。`@{upstream}`、`origin/HEAD`、`origin/main`、`origin/master` の順に試し、どれも無ければHEADとする。
このリポジトリには `origin/HEAD` が無く、worktreeのブランチには上流が無い。そのため `origin/main` まで試す。
作業ツリーの差分だけ（HEADとの差）を見る案は、commitしてからStopしたときに何も検査しないので採らない。
セッション開始時のHEADを基準にする案は、状態ディレクトリへの依存を `Makefile` に持ち込むので採らない。
pushしていないcommitはすべて範囲に入る。pushされたものはCIのフルの `verify` が見る。

`Makefile` の中で、変更の一覧は最初の参照で1回だけ計算する（`$(eval)` による覚え書き）。
`make verify` はこの一覧を使わないので、gitを余計に呼ばない。
一覧は `make` の変数 `CHANGED` にあり、`make` の引数で与えればgitを使わずに差し替わる。テストはこれで選び方を確かめる。

検査の選び方はspecの `verify-fast` のとおり。対象は `make verify` と同じ一覧（`DOCS_JA`、`DOCS_TERMS`、スクリプトの一覧）との共通部分にする。
batsの対応は、名前の規則（`hooks/scripts/<name>.sh` と `hooks/tests/<name>.bats`）と、個別の対応の表で決める。
スキル全体を見るテストは `bin/tests/skill-*.bats` という名前にし、`skills/` の下が変わったときに走らせる。
選んだ結果を表示するだけの `verify-fast-plan` ターゲットも置く。テストと、Stopで何が走るかを確かめるのに使う。

手元の計測で、`make verify` は約57秒かかる。内訳はbatsが約43秒、textlintの全文書が約9秒、shellcheckの全スクリプトが約4秒。
文書を数本変えたときはtextlintとtermsだけで数秒、hookを1本変えたときはshellcheck1本と対応するbats1本で数秒に収まる。

### block の回数は状態ディレクトリで数える

状態ディレクトリの `sessions/<session_id>/verify-blocks` に、3行を書く。
このターンでblockした回数、最後に失敗したときの作業ツリーの指紋、そのときの終了コードである。

- `stop_hook_active` がfalseのStopは、ターンの始まりとしてこのファイルを消す
- 検証が成功したら、`verified` を書いてこのファイルを消す
- 失敗したら回数を1つ増やして書き、blockする
- 回数がすでに3のときはblockせず、`systemMessage` で作業ツリーが失敗したまま終わることを伝える

`systemMessage` にしたのは、Stopでblockしないときにユーザーへ見える出力がこれだけだからである。
上限3は定数にする。環境変数で変えられるようにする理由がまだ無い。

`stop_hook_active` がtrueで、作業ツリーの指紋が最後の失敗と同じときは、検証を走らせない。
`verify.log` と記録した終了コードで、前回と同じ理由のblockを返す。
直さずに終えようとするたびに、フルの `verify` を最大4回走らせるのを避けるためである。
結果が揺れる検査で古い失敗を返すことはあるが、上限で終わり、次のターンの最初のStopで必ず走り直す。

`verify-gate.sh` の `baseline` が無いときに記録する行は、別の変更が `project` と `started` の書き込みを外す。その行には触れない。

### ルートは 2 つ、検査は cwd の git ルート

`lib/common.sh` に `project_roots` を置く。`CLAUDE_PROJECT_DIR` と `cwd` のgitルートを、実体に解決して改行区切りで返す。
同じなら1行にし、どちらも無ければ `cwd` を返す。
`path_allowed` は、ルートの一覧のどれかの下にあれば許す。write-guardとbash-guardの理由の文には、ルートをすべて書く。

textlint-checkとterms-checkは `work_root`（`cwd` のgitルート、無ければ `cwd`）を使う。
worktreeで用語集を変えたとき、開始時のルートの用語集を読むと誤った指摘になるからである。
Q20の「verifyとbaselineは `cwd` のtop-level」を、verifyの一部である書き込み後の検査にも当てはめた。
`project_root` は、別の変更が書き換え中のjournal系のスクリプトが使うので残す。

### 状態ファイルは許可ファイルと同じ形で守る

守るのは `baseline`、`verified`、`verify-blocks` の3つ。
どれも書き換えると検証を迂回できる。`baseline` を消すと、verify gateは次のStopで記録し直して検証しない。
`verify.log` のような、書き換えても迂回にならないファイルは守らない。

write-guardは、実体が状態ファイルのパスを、許可ファイルと同じく解除できない拒否にする。
bash-guardは、許可ファイルの3つの方法をそのまま使い、消す操作を1つ足す。

- 文字列の照合：`uskn-harness/sessions/<id>/baseline` のように、コマンドが状態ファイルを名指しする
- 書き込み先の解決：リダイレクト先や書く操作の対象の実体が、状態ファイルかセッションのディレクトリ
- 消す操作：`rm`、`rmdir`、`mv` の対象が、状態ディレクトリ、その `sessions`、またはそれらの上位

セッションのディレクトリそのものを書き込み先として拒否するのは、`cp /tmp/baseline <dir>/` のようにファイル名を書かずに置く形を拾うためである。
上位のディレクトリを拒否するのは消す操作だけにする。`cp x ~/` のような普通のコピーを止めないためである。
文字列の照合は `cat` のような読み取りも拒否する。状態ファイルを読む用事は無く、検証の結果は `verify.log` にある。

### プラグインの bin/ は元のスクリプトを呼ぶだけ

`plugins/uskn-harness/bin/` に2つの実行ファイルを置く。

- `uskn-repo-context`：`hooks/scripts/session-start.sh` を同じ引数で `exec` する
- `uskn-terms-check`：`hooks/scripts/terms-check.sh` を同じ引数で `exec` する

中身は、自分のディレクトリから `../hooks/scripts/` を解決して `exec` する数行にする。
symlinkにする案は、`terms-check.sh` が `$(dirname "$0")/lib/common.sh` を読むので、`bin/` の下では壊れる。
名前は `uskn-` で始め、ほかのコマンドと衝突しないようにする。

スキルは長いパスをやめて、この短いコマンドを呼ぶ。代わりのパスの行は残さない。
スキルを読み込むのはClaude Codeだけで、このプラグインも同じ `sync` がsymlinkで置くからである。
hook、CI、普通のシェルは `bin/` を `PATH` に持たない。そちらは今までどおり `~/.local/bin/uskn-harness` とスクリプトのパスを使う。

`allow-repo.sh` は短いコマンドにしない。
許可ファイルを書く唯一の入口を `PATH` に載せると、エージェントが自分で許可を足す手間がさらに減るからである。
`/allow-repo` スキルは別の変更が書き換え中でもある。journalの `journal-update.sh` は、別の変更がjournalごと外す。

ADR-0002の「skills-dirプラグインは `bin/` 非対応」は、今の版では誤りである。
ADR-0005で `bin/` を使う決定を記録し、ADR-0002にはADR-0005を指す注記を足す。

### テストの置き場

- `hooks/tests/hooks-json.bats`：`if` とmatcherの組み合わせ。`hooks.json` をjqで読む
- `hooks/tests/plugin-bin.bats`：短いコマンドが元のスクリプトと同じ出力と終了コードを返すこと。symlinkを通したプラグインでも動くこと
- `bin/tests/skill-commands.bats`：スキルが `session-start.sh` と `terms-check.sh` を長いパスで呼ばないこと。スキルが呼ぶ `uskn-*` のコマンドが `bin/` に実在すること

`Makefile` の `SCRIPT_DIRS` に `plugins/uskn-harness/bin` を足し、shellcheckの対象にする。

### fix-hook-bugs との順序

write-guardのルートの外を拒否する要件と、textlint-hookの実行の条件の要件は、fix-hook-bugsも変える。この変更の本文は、fix-hook-bugsの版に今回の差分を足したものである。
terminology-guardのMarkdownに限る要件は、fix-hook-bugsが足すもので、main specsにまだ無い。
そのため `openspec validate` は、archiveがこのdeltaを拒むという情報を出す。fix-hook-bugsを先にarchiveすれば解消する。

## Risks / Trade-offs

- 作業ディレクトリの外の `.md` は、新しい版ではtextlintとtermsの検査にかからない → commitとprのスキルは自分で検査する。リポジトリの文書は `verify-fast` とCIが見る
- `cwd` のgitルートを許すと、Bashの `cd` で `cwd` を移した先のリポジトリへ書ける → Claude Codeは `cd` の先を作業ディレクトリと追加のディレクトリに限る。ユーザーが渡した場所の中だけで広がる
- `verify-fast` は、変えたファイルの外への影響を見ない。ファイルの削除で別の文書の名前が切れる場合や、共通でないスクリプトの変更で別のテストが落ちる場合である → フルの `verify` をCIとarchive-pushが走らせる
- 基準の参照が古いと、範囲が広がって遅くなる → 検査が減る向きには外れない
- 状態ファイルの保護は、変数に入れたパス、`find -delete`、`xargs`、別の言語から計算したパスを拾わない → bash-guardの既知の取りこぼしと同じ扱い
- 変わっていない作業ツリーでは前回の失敗を返すので、揺れる検査では古い失敗が残る → 上限で終わり、次のターンの最初のStopで走り直す
- 3回のblockのあとは、失敗したままターンが終わる → `systemMessage` でユーザーに伝える。回避はこれまでどおり `USKN_SKIP_VERIFY=1`
- `bin/` のコマンドはhookの `PATH` に無い → hookは `${CLAUDE_PLUGIN_ROOT}` からスクリプトを直接呼ぶ。`hooks.json` は変えない
- `AGENTS.md` のLayoutの表は、プラグインを「hookとテスト」と書いている → `AGENTS.md` はこの変更の外なので、別の変更で `bin/` を足す

## Migration Plan

`uskn-harness sync` はプラグインのディレクトリごとsymlinkで置く。そのため `bin/` はpullだけで各マシンに届く。
新しいセッションから `PATH` に載る。hookの変更も新しいセッションから効く。
戻すときは、この変更のcommitを戻す。状態ディレクトリの `verify-blocks` は残っても害が無い。
