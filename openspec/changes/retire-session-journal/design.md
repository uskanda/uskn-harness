## Context

動機はproposal.mdのWhyを参照。現状の仕組みは次のとおり。

- hookは3本がjournal専用。SessionStartのjournal-recent.sh、Stopのjournal-update.sh、SessionEndのjournal-end.sh
- SessionStartの `session-start.sh` は `<repo-context>` にsession行とトレーラの案内を出す。`session-baseline.sh` は `baseline` のほかに、journalだけが読む `project`、`started`、`baseline-head` を書く。verify gateも `baseline` が無いときに `project` と `started` を書く
- `lib/common.sh` はjournal用の関数（`project_key`、`to_local_stamp` など）を持つ。write-guardとbash-guardが共有する許可リストに `~/.ai-sessions` を含む
- `bin/uskn-harness` の `sync` は `~/.ai-sessions` を `git init` で作り、`doctor` はそれを検査する
- `allow-repo` スキルは `<repo-context>` のsession行からsid8を得る。`allow-repo.sh` は `session_dir_for_prefix` でsid8から状態ディレクトリを探す
- 状態ディレクトリ `~/.local/state/uskn-harness/sessions/` は増える一方で、消す手順が無い

並行する変更が2つある。fix-hook-bugsは `harness-sync` に要件「失敗の終了コード」を足し、`write-guard` の要件「ルート外の拒否」を書き換える。
fork-skills-model-effortは `git-workflow-skills` のSessionトレーラの要件を書き換える。あわせて `skills/git/commit/SKILL.md` を編集中である。

## Goals / Non-Goals

**Goals:**

- journalに関わるスキル、hook、インストーラの手順、文書、仕様をすべて外す
- 状態ディレクトリを、hookが実際に読むファイルだけにし、古いセッションを `sync` で消す
- sid8を、`<repo-context>` を経由せずにセッションIDから得る

**Non-Goals:**

- 各端末の `~/.ai-sessions` を消すこと、移すこと。ユーザーが決める
- journalに代わる記録の仕組み。決定はOpenSpecのアーカイブ、ADR、コミットに、好みはauto memoryに任せる
- verify gateの判定、`if` の条件、再検証の仕組み。別の変更が扱う

## Decisions

### 能力の廃止はREMOVEDだけの差分で表す

`journal-context`、`journal-skeleton`、`journal-skill`、`journal-sync`、`recall-skill` は、要件をすべてREMOVEDにした差分を置く。
OpenSpec 1.12はarchiveのときに、最後の要件が消えた能力の `spec.md` を削除する。main specを手で消す必要は無い。
ただし削除には、変更の `.openspec.yaml` に `retire_capabilities: true` が要る。無いとarchiveは要件の無いspecを拒んで止まる。
各REMOVEDのMigrationに、代わりに見る場所を書く。

### archiveの順序

`harness-sync` の差分は、fix-hook-bugsが足す要件「失敗の終了コード」をMODIFIEDで書き換え、sessionsリポジトリの `git init` を失敗の定義から外す。
`write-guard` の差分は、fix-hook-bugsの版の「ルート外の拒否」を元に、許可リストから `~/.ai-sessions` を外す。
`git-workflow-skills` の差分は、fork-skills-model-effortが書き換えたSessionトレーラの要件を削除する。
そのため、この変更は2つのあとにarchiveする。先にarchiveすると、`harness-sync` のMODIFIEDが見つからずに止まる。
`openspec validate` はこの状態を情報として報告するだけで、検証は通る。

### 古いセッションの状態は最も新しい更新時刻で判断する

`sync` は `sessions/` の直下のディレクトリごとに、ディレクトリそのものと中のファイルを `find -mmin -43200` で調べる。
30日以内に更新されたものが1つも無ければ、そのディレクトリを消す。
ディレクトリの更新時刻だけでは足りない。verify gateは `verify.log` や `verified` をその場で上書きするので、ディレクトリの時刻が動かない。
状態ディレクトリの場所はhookの `lib/common.sh` と同じ式で決め、`USKN_STATE_DIR` と `XDG_STATE_HOME` に従う。テストは偽の状態ディレクトリで動く。
削除は通常の `sync` だけで行い、`--tools` と `--remove` では行わない。`--dry-run` では予定を出力するだけにする。
消せなかったディレクトリは `warn` にとどめ、終了コードを1にしない。導入の失敗ではないため。
代わりに、SessionEndなどのhookで消す案もあった。デスクトップアプリではSessionEndがアプリを閉じるまで走らないので採らない。

### sid8はスキルとスクリプトの両方で得られるようにする

`allow-repo` スキルは、読み込み時に置換された `${CLAUDE_SESSION_ID}` の先頭8文字を `--session` に渡す。
`allow-repo.sh` は `--session` が無いか空のとき、環境変数 `CLAUDE_CODE_SESSION_ID` を使う。どちらの値も先頭8文字に切ってから探す。
`${CLAUDE_SESSION_ID}` が置換されずにシェルへ渡ると、未設定の変数として空に展開される。その場合もスクリプト側の代替で拾える。
代替をスクリプトに置くと、batsで確かめられる。スキルの本文だけに書く案より、センサーを付けやすい。
この探索に使う `session_dir_for_prefix` は `lib/common.sh` から外さない。

### 状態ディレクトリにはhookが読むファイルだけを書く

`session-baseline.sh` は `baseline` だけを書く。verify gateが `baseline` の無いときに書くのも `baseline` だけにする。
`project`、`started`、`baseline-head` はjournalだけが読んでいた。
`lib/common.sh` からは `USKN_SESSIONS`、`sid8`、`project_key`、`to_local_stamp` を外す。使う箇所が無くなる `now_iso` も外す。
`session-start.sh` は `session_id` を読まなくなる。

### 許可リストから `~/.ai-sessions` を外す

write-guardとbash-guardは `lib/common.sh` の `path_allowed` を共有するので、1か所の変更で両方から外れる。
以後 `~/.ai-sessions` への書き込みは、ほかのルート外と同じく拒否される。ユーザーが要るときは `/allow-repo` で許可できる。

### 削除したスキルのsymlinkは `sync` が取り除く

`journal` と `recall` を消すと、各端末の `~/.claude/skills/journal` と `~/.claude/skills/recall` は先の無いsymlinkになる。
`sync` は、`~/.claude/skills` の直下で、ハーネスの中を指していて先が無いsymlinkを取り除く。
対象は、リンク先の文字列がハーネスのcheckoutのパスで始まるものに限る。ハーネスの外を指すsymlinkと実ディレクトリには触れない。
スキルを外すという決定を各端末まで届けるための手順で、新しい判断は含まない。手作業の `rm` を案内する案もあったが、端末ごとに忘れるので採らない。

### Co-Authored-Byは `commit` の本文で付ける

forkした `commit` には、本体のセッションが受け取るattributionの案内が届かない。
そのため、トレーラはスキルの本文の規則として常に付ける。
`skills/git/commit/SKILL.md` はfork-skills-model-effortが編集中なので、この変更の作業としては、そのarchive後に書き換える。

### ADRと用語集

ADR-0003とADR-0005は別の変更が使うので、この変更はADR-0004とする。ADR-0004はADR-0001 §10（履歴）と、§7のjournalに関わる行を置き換える。
ADR-0001には置き換えの注記だけを足し、本文は記録として残す。
用語集からは、journalを指していた項目を外す。grilling.mdで使う「アーカイブ」を足し、一般語リストに「データ」を足す。
ユーザー層の `CLAUDE.md` では、journalと `recall` の行を、決定の置き場（アーカイブ、ADR、コミット）を示す1行に替える。再決定の前に探す先を、`recall` の代わりに示すため。
`ja-writing` の例文は、journalの代わりに保護ブランチの注入を題材にする。直す前の文の指摘の数は変えない。

## Risks / Trade-offs

- archiveの順序を誤る → proposal.mdのImpactとtasks.mdに順序を書く。誤っても `openspec archive` がMODIFIEDの不一致で止まるので、main specは壊れない
- 30日より長く開いたままのセッションが状態を失う → verify gateは `baseline` が無ければ記録し直す。`/allow-repo` の許可はもう一度出してもらう。30日間hookが1度も走らないセッションはまれ
- 未更新の端末は古いhookを走らせ続ける → `sync` がcheckoutを更新するまでは、journal系のhookが `~/.ai-sessions` に書く。更新後は止まる。書かれたデータはユーザーが消すかを決める
- `USKN_SKIP_JOURNAL` を設定したままの環境 → 読む箇所が無くなるだけで害は無い。READMEから外す

## Migration Plan

1. この変更をfix-hook-bugsとfork-skills-model-effortのあとにマージする
2. `commit` スキルの書き換え（tasks.mdの保留分）を行う
3. 各端末で `uskn-harness sync` を実行する。先の無いsymlinkが消え、ユーザー層の `CLAUDE.md` が更新され、古いセッションの状態が消える
4. `~/.ai-sessions` を消すかは、端末ごとにユーザーが決める

戻すときは、この変更のコミットをrevertして `sync` を実行する。`~/.ai-sessions` は `sync` がもう一度作る。
