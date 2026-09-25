## Context

動機はproposal.mdのWhyにあり、決定はgrilling.mdにある。要件はこの変更のdelta specsにある。
`sync` は今、`openspec init` を一時ディレクトリで実行している。
できた `.claude/skills/openspec-*` と `.claude/commands/opsx/` は、両方ともユーザー層にコピーする。
生成されるワークフローの組とdeliveryは、ユーザー全体の設定 `~/.config/openspec/config.json` に従う。
OpenSpecにはプロジェクト単位のprofileとdeliveryの設定が無い。
この設定を `delivery: commands` に変えたとする。プロダクトリポジトリで次に `openspec update` を実行すると、そのリポジトリの `.claude/skills/openspec-*` が消える。
`doctor` は4つの `openspec-*` スキルを検査しており、`~/.claude/commands/opsx/` は見ていない。
スキルのsymlinkは `$HARNESS/skills/**` を指す絶対パスで張る。ハーネスからスキルを消すと、symlinkは実体の無いまま残る。

## Goals / Non-Goals

**Goals:**

- OpenSpecのユーザー層を、ユーザーの設定に左右されずcommandsの6つにそろえる
- 削除したスキルの後始末（symlink、`openspec-*`）を、各マシンで `sync` を1回実行するだけで済ませる
- 完了前の確認とCIの確認を、`verify` 1つに寄せる

**Non-Goals:**

- `test-driven-development` と `systematic-debugging` の本文を削ること。削除したスキルへの参照だけを直し、本文の整理は後の変更が扱う
- プロダクトリポジトリの `.claude/skills/openspec-*` を消すこと。ユーザー全体の設定を変えないので、各リポジトリは今のまま
- エイリアスの整理。grillingで残すと決めた

## Decisions

### 生成の間だけ XDG_CONFIG_HOME を差し替える

`sync` は `openspec init` を実行する間だけ、`XDG_CONFIG_HOME` を一時ディレクトリに向ける。
そこに `openspec/config.json` として `{"profile":"core","delivery":"commands"}` を置く。
openspec 1.13.2で、この設定なら `.claude/commands/opsx/` の6ファイルだけが生成されることを確かめた。
一時ディレクトリは生成のあとで消す。openspecがそこへtelemetryの欄を書き足すが、一緒に消える。
差し替えるのはopenspecのプロセスだけで、`mise exec -- env XDG_CONFIG_HOME=<tmp> openspec init` の形にする。
miseはグローバルのnodeを `XDG_CONFIG_HOME` の下の設定から読むので、mise自身に一時ディレクトリを見せると、openspecを見つけられない。

代わりの案は2つあった。

- ユーザー全体の設定を `delivery: commands` にする：プロダクトリポジトリの `openspec update` が、そのリポジトリのスキルを消してしまう。採らない
- 今の生成のまま、commandsだけをコピーする：ユーザーの設定がdelivery `skills` やprofile `custom` だと、コマンドが無いか、組が変わる。profileとdeliveryの両方を一時的な設定で固定すれば、生成物がユーザーの設定に左右されない

### 旧スキルは管理印で見分けて消す

`sync` は `~/.claude/skills/openspec-*` のうち、`.uskn-harness-managed` を持つものだけを消す。
印はハーネスが入れたことの証拠で、`sync --remove` も同じ印で消している。印の無いものは、ユーザーかchezmoiが置いたものとみなして触らない。
この手順はopenspecの生成とは別にし、生成が失敗しても、ネットワークを使わないテストでも動くようにする。
`--dry-run` では予定だけを出す。

### 実体の無い symlink は向き先の文字列で判定する

実体の無いsymlinkは `realpath` で解決できない。そのため、`readlink` で読んだ向き先の文字列が `$HARNESS/skills/` か参照点の `skills/` で始まるかで判定する。
消すのは、向き先が存在せず、名前が現存のスキルと違うものだけである。
同じ名前のスキルが別の場所へ移ったときは、今までどおり `ensure_link` が張り直す。そのため、判定はスキルのsymlinkを張ったあとに行い、現存の名前を対象から外す。
`--dry-run` では張り直しと削除のどちらも起きない。現存の名前は対象から外すので、同じsymlinkが張り直しと削除の両方の予定に出ることは無い。

代わりの案は、削除したスキルの名前を並べて消すことだった。スキルを消すたびに一覧を直す必要がある。実体の無いsymlinkを一律に消す案は、ユーザーが自分で張ったsymlinkまで消すので採らない。
`doctor` は同じ判定で `warn` を出す。`sync --remove` も同じ判定で消す。

### doctor は commands/opsx の6ファイルを見る

`doctor` は `~/.claude/commands/opsx/` の印と、`apply` `archive` `explore` `propose` `sync` `update` の6ファイルを検査する。
profile `core` の組がこの6つであることは、1.13.2の生成で確かめた。
`openspec-*` スキルの検査はやめる。消したものを「無い」と警告しないためである。

### verify は根拠の規則と CI からの導出だけを足す

`verification-before-completion` から移すのは、「同じターンで実行したコマンドと結果を先に示す」という規則だけにする。
`pre-merge` から移すのは、検証規約が無いときにCIの設定から確認コマンドを導く手順だけにする。
言い訳の表や、言語ごとの典型的なコマンドの一覧は移さない。完了前の検証はStop hookの `verify-gate` が機械的に強制する。`verify` には、手で実行するときの手順と報告の形があれば足りる。
例を1つ本文に置き、報告の形を示す。

### archive-push は opsx:archive を呼ぶ

`archive-push` の手順5は、Skillツールで `openspec-archive-change` を呼んでいた。コマンドもSkillツールから `opsx:archive` として呼べるので、名前だけを差し替える。
質問への答え方（sync、archive、cancel）は変えない。

### schema は上流の文をそのまま移す

`uskn` schemaの指示とテンプレートへ、上流 `spec-driven` の1.12.0から1.13.2までの差分を、英文のまま移す。
上流の文に近いほど、次にopenspecを上げたときの差分が読みやすい。
`--store` への言及もそのまま残す。ハーネスはstoreを使わないが、既存の指示もstoreを前提にした文（`planningHome.root`）を持っている。
`grilling` 成果物、EARS記法の型、`requires` はそのまま残す。
1.13ではapplyの `requires` にある未知の成果物がエラーになるが、`uskn` は `tasks` だけなので影響しない。

### 移行スクリプトは書き換えずに消す

`templates/chezmoi/` の移行スクリプトは、chezmoiの `run_onchange` である。中身が変わると再実行される。
再実行すると、`sync` が管理する実ディレクトリの `openspec-*` を `rm -rf` する。そのため、書き換えて直すのではなく削除する。
移行は2026-09-05に終わっている。chezmoiはスクリプトの削除では何も実行しない。
dotfilesのコピーは、fresh cloneからdraft PRで消す。`~/dotfiles` の作業ツリーには触らない。
`openspec/known-names.txt` にスクリプトのファイル名を足す。この変更の文書がその名前を書くためである。

### ADR は ADR-0001 に追記する

変わるのはADR-0001の§6（profileとdelivery）、§8（`nessun-dorma` と `pre-merge`）、§9（forkの数）の記述で、構成の考え方は変わらない。
ADR-0001は、2026-09-06の修正などを本文の中に日付付きで書き足してきた。同じ形で追記し、新しいADRは作らない。

### methodology-skills の Purpose は main spec を直接直す

deltaの `## Purpose` は既存の能力では無視される。schemaの指示どおり、`openspec/specs/methodology-skills/spec.md` のPurposeを実装の中で直接直す。

## Risks / Trade-offs

- ほかの指示が `openspec-apply-change` などのスキル名を書いている → ハーネスの中の参照は `archive-push` だけで、この変更が直す。セッションの指示に残る名前は `opsx:apply` などに読み替える。
- `sync` を実行するまで、各マシンに削除したスキルのsymlinkは残る → 実体の無いsymlinkは、Claude Codeのスキル一覧に出ない。`doctor` が `warn` で知らせる。
- openspecが将来 `XDG_CONFIG_HOME` を読まなくなる → 生成物にスキルが混ざる。`openspec-*` はコピーしないので、ユーザー層には出ない。コマンドが欠ければ `doctor` が `warn` を出す。

## Migration Plan

1. この変更をmainに入れる。各マシンで `uskn-harness sync` を実行する。削除したスキルのsymlinkと、印のある `openspec-*` が消える。
2. `uskn-harness doctor` で、`openspec commands opsx` が `ok`、実体の無いsymlinkの `warn` が無いことを確かめる。
3. dotfilesのdraft PRをマージする。移行スクリプトは再実行されない。

戻すときはこの変更をrevertし、`sync` を実行する。openspecは1.12.0に戻り、`openspec-*` スキルが再び生成される。
