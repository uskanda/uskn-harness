## Context

動機は `proposal.md` のWhyを参照。設計を縛る事実は次のとおり。
出典は[Claude Codeの公式文書](https://code.claude.com/docs/en/memory#agents-md)とCHANGELOGで、2026-09-25に確かめた。

- Claude Codeの既定の設定は `claude-md-or-agents-md`。作業ディレクトリかその上位に `CLAUDE.md`、`.claude/CLAUDE.md`、`CLAUDE.local.md` のどれかがあると `AGENTS.md` は読まれない。
- `~/.claude/CLAUDE.md` と組織が管理する `CLAUDE.md` はこの判定に数えない。どちらも `AGENTS.md` と並んで読まれる。
- セッション開始時には、作業ディレクトリと上位にある `AGENTS.md` と `.claude/AGENTS.md` がすべて読まれる。下位のディレクトリの `AGENTS.md` は、そこのファイルを読んだときに読まれる。`AGENTS.md` の中の `@path` も展開される。
- 対応はv2.1.277から。Amazon Bedrock、Google Vertex AI、Microsoft Foundry、LLM gateway、telemetryを無効にしたセッションではv2.1.281から。
- 対応版でも読まれないのは、組み込みの `agents-md` プラグインを `/plugin` で無効にしたときと、v2.1.276以前から更新した直後の最初のセッションの一部。文書のこの一覧に `disableAllHooks` は無い。
- 読むファイルは `/config` のProject instructionsで変えられる。設定ファイルでは `pluginConfigs["agents-md@builtin"].options.instructionFiles` に書く。
- `instructionFiles` の値は `claude-md-or-agents-md`（既定）、`claude-md-and-agents-md`、`claude-md`、`managed-only` の4つ。効くのは `~/.claude/settings.json` などユーザー層の設定で、プロジェクトとlocalの設定ファイルでは無視される。
- `@AGENTS.md` だけを持つ `CLAUDE.md` は、残しても `AGENTS.md` を2度読ませない。中身がそれだけなら消してもよい、と文書は案内している。
- このマシンのPATHの `claude` は2.1.270。`~/.local/bin/claude` は `versions/2.1.270` へのsymlinkで、ネイティブ版の自動更新は2026-08-26が最後。
- VS Code拡張は2.1.282で、同梱の実行ファイルで動く。置き場は `~/.vscode-server/extensions/anthropic.claude-code-2.1.282-linux-x64`。
- `claude --version` だけを見る検査はCLIの古さには気づく。VS Code拡張の版には気づかない。
- Claude Codeは `deps.json` の管理外にある。
- `doctor` にstrictモードは無い。`claude` が無いとき、既存の `plugin validate` の検査は何も報告せずに飛ばす。
- batsのテストは `HOME` を一時ディレクトリに向け、stubモードでネットワークと実行時の検査を止めている。

## Goals / Non-Goals

**Goals:**

- 新しいプロダクトリポジトリが `CLAUDE.md` 無しで動き、古いClaude Codeでは `doctor` が気づかせる。PATHのCLIとVS Code拡張のどちらが古くても気づかせる。
- `AGENTS.md` の読み込みを妨げる `CLAUDE.md` と `CLAUDE.local.md` を `onboard-check` が見つける。

**Non-Goals:**

- Claude Codeのインストールや更新を `sync` が行うこと。
- Claude Codeの版に上限を設けること、特定の版にピンすること。
- 既存のプロダクトリポジトリから `CLAUDE.md` を消すこと。
- `/config` のProject instructionsの設定を検査すること。
- `instructionFiles` をハーネスが設定すること。
- `~/.vscode` と `~/.vscode-server` の外にある拡張の版を検査すること。

## Decisions

### grillingからの変更（2026-09-25）

grillingのあとで公式文書とCHANGELOGを確かめ、次の3点を改めた。`grilling.md` の行は面談の記録なので書き換えない。
確認済みの印にある第1ラウンドは、2026-09-25にユーザーへ確かめたときのラウンドを指す。`grilling.md` のラウンドとは別。

- 最低版（Q5、Q7）：2.1.277から2.1.281へ上げる。2.1.281から、Bedrock、Vertex、Foundry、LLM gateway、telemetryを無効にしたセッションでも読まれるため。2026-09-25に確認済み（第1ラウンドQ1）。
- `CLAUDE.local.md`（Q9）：文書は `CLAUDE.local.md` を `CLAUDE.md` と同じく数える。`AGENTS.md` に頼るリポジトリでは、置いただけで読まれなくなる。`onboard-check` の対象に入れ、`warn` を出す。`warn` には直し方を書く。2026-09-25に確認済み（第1ラウンドQ2）。
- `disableAllHooks`（Q8と後回しの項目）：文書の読まれない条件に無いので、この変更の注意書きとADR-0003には書かない。スキル評価の手順を文書にするとき、`AGENTS.md` が読まれるかを実際に確かめる。

### `deps.json` の `runtimes` に `claude-code` を足し、`min_version` を持たせる

`runtimes` の既存の項目は `version` を持つが、あれはピンであって下限ではない。
下限を `version` に入れると意味が2つになるので、`min_version` という別のキーにする。
値は2.1.281。接続先やtelemetryの設定によらず `AGENTS.md` が読まれる最初の版だから。
`role` に、`sync` が入れないことと下限の理由を書く。`_readme` にも `min_version` の意味を1文で足す。

代案は `bin/uskn-harness` の定数。外部依存の版を `deps.json` に集める方針から外れるので採らない。

### Claude Codeの版を縛らない

Claude Codeの版は厳密には管理しない。ハーネスは、最新版を使うことを妨げてはならない。2026-09-25に確認済み（第1ラウンドQ26）。

- 最低版は `doctor` の `warn` にだけ使う。上限は設けず、最低版より新しい版はどれも `ok` とする。
- `sync` はClaude Codeをインストールせず、版のピンもしない。`sync` が入れるのは `deps.json` の `clis` だけで、`runtimes` の `claude-code` は対象にならない。
- CIは今までどおり、版を指定せずに最新版を入れる。

### 検査するのはPATHのCLIとVS Code拡張

`claude --version` だけでは、このマシンのようにCLIとVS Code拡張の版が分かれた状態を見落とす。
`doctor` は次のインストールをそれぞれ検査する。

- PATHの `claude`。版は `claude --version` の出力 `2.1.270 (Claude Code)` の先頭の語。
- `~/.vscode/extensions` と `~/.vscode-server/extensions` にある `anthropic.claude-code-<version>-*` のディレクトリ。版はディレクトリ名の `<version>` の部分。

インストールごとに1行を出す。最低版以上なら `ok`、古ければ `warn` で、どちらの行もインストールを名前で示す。
名前は、CLIならPATHで見つけた `claude` のパス、拡張ならディレクトリのパス。
`warn` には、そのインストールの版と最低版、更新の方法を入れる。`CLAUDE.md` の無いリポジトリで `AGENTS.md` が読まれないことも添える。
同じ `extensions` ディレクトリに複数の版があるときは、最も新しい版だけを比べる。拡張の更新のあとで、古い版のディレクトリは残ることがあるため。
最低版は `deps.json` からjqで読む。jqが無いときは、`check_npm_globals` と同じく検査を飛ばす。

### 版の比較は `sort -V` で行う

最低版と並べて `sort -V` の先頭が最低版なら満たしている。
`sort -V` はGNU coreutilsとmacOS 13以降にあり、ハーネスの対象環境で足りる。
版が読み取れない出力のときは `warn` とし、出力をそのまま添える。

### インストールが無いときは報告しない

grillingでは「既存の道具と同じ扱い（skip、strictでは失敗）」とした。
`doctor` にはstrictモードが無いので、同じ `doctor` 内の `plugin validate` の扱いに合わせ、項目を報告しない。
Claude Codeを使わないマシン（CIなど）で `warn` が常に出るのを避ける。
CLIが無く拡張だけがあるときは、拡張の行だけを出す。

### 版の検査はstubモードでも走らせる

`claude --version` はネットワークに出ない。拡張の検査は `HOME` の下のディレクトリ名を読むだけなので、stubで止める理由が無い。
テストは一時 `HOME` の `.local/bin` に偽の `claude` を置き、PATHの先頭に入れて版を差し替える。
拡張は、一時 `HOME` の下に `.vscode-server/extensions/anthropic.claude-code-<version>-linux-x64` を作って差し替える。
既存のテストが実機の `claude` を拾って結果が変わらないよう、`setup` で偽の `claude`（最低版以上）を既定として置く。

### `onboard-check` の判定は1項目にまとめる

`CLAUDE.md` と `.claude/CLAUDE.md` を順に見て、`@AGENTS.md` を含まないファイルごとに `warn` を1行出す。
どちらも無いリポジトリは `AGENTS.md` に頼っている。そこに `CLAUDE.local.md` があれば `warn` を1行出す。
`warn` が1つも無ければ `ok` を1行出す。文言は、どちらも無ければ `AGENTS.md only`、あれば `CLAUDE.md -> @AGENTS.md`。
`CLAUDE.md` の `warn` の文言には「このファイルがあると `AGENTS.md` は読まれない。中身を `AGENTS.md` へ移す」を入れる。
`CLAUDE.local.md` の `warn` の文言には、`AGENTS.md` が読まれなくなることと、直し方を入れる。
直し方は、`CLAUDE.local.md` を消すか、Project instructionsを `claude-md-and-agents-md` にするかの2つ。
`CLAUDE.md` が `@AGENTS.md` を含むリポジトリでは、`CLAUDE.local.md` を問題にしない。`AGENTS.md` は `CLAUDE.md` から取り込まれるので、指示は欠けない。

### このリポジトリの `CLAUDE.md` は確認のあとで消す

消す前に次を確かめる。PATHの `claude` を2.1.281以上へ更新する。セッションを1度開いて閉じる。
次のセッションで `CLAUDE.md` を一時的に退避し、`/memory` の一覧に `AGENTS.md` のパスが出ることを見る。
`/memory` はv2.1.280から、直接読んだ `AGENTS.md` を一覧に出す。確認はPATHのCLIとVS Code拡張の両方で行う。
読まれなければ `CLAUDE.md` を戻し、削除の作業だけを未完のまま残して報告する。
このリポジトリに `CLAUDE.local.md` は無い（2026-09-25に確認）。

### ADR-0003は決定と、読まれない条件の一覧を持つ

ADR-0001の19行目と49行目の段落には「ADR-0003で置き換え」の注記を足すだけにし、本文は履歴として残す。
ADR-0003の「結果」には次を書く。

- 読まれない条件：版が2.1.277より古いとき。Bedrock、Vertex、Foundry、LLM gateway、telemetry無効のセッションでは2.1.281より古いとき。
- 読まれない条件：組み込みの `agents-md` プラグインを `/plugin` で無効にしたとき。v2.1.276以前から更新した直後の最初のセッションの一部。
- 読まれない条件：作業ディレクトリか上位に `CLAUDE.md`、`.claude/CLAUDE.md`、`CLAUDE.local.md` のどれかがあるとき。
- 回避策：一時的な `CLAUDE.md` に `@AGENTS.md` の1行を書く。
- 回避策：`CLAUDE.local.md` を使い続ける人は、ユーザー層の `instructionFiles` を `claude-md-and-agents-md` にする。ハーネスはこの設定を入れない。
- 既存リポジトリの `CLAUDE.md` を触らない根拠：`@AGENTS.md` だけの `CLAUDE.md` は残してよく、消してもよい、と文書が案内している。

## Risks / Trade-offs

- 懸念：古いClaude Codeのマシンで新しいリポジトリを開くと、指示が何も読まれない。対処：`doctor` がインストールごとに `warn` を出す。`sync` の最後に `doctor` が走るマシンではそこで気づく。
- 懸念：CLIとVS Code拡張の版が分かれる（このマシンでは2.1.270と2.1.282）。対処：それぞれを別の行で検査する。
- 懸念：Claude Code以外で `CLAUDE.md` だけを読むツール。対処：現在の利用ツールには無い。出てきたらそのリポジトリにだけ `@AGENTS.md` の `CLAUDE.md` を置く。`onboard-check` はそれを `ok` とする。
- 懸念：個人の指示を `CLAUDE.local.md` に置くと、`AGENTS.md` が読まれなくなる。対処：`onboard-check` の `warn`。回避策はADR-0003に書く。
- 懸念：更新直後の最初のセッションで読まれないことがある。対処：`doctor` では検知できないのでADR-0003に書く。このリポジトリの確認では、更新後にセッションを1度開いて閉じる。
- 懸念：上位ディレクトリの `CLAUDE.md` が読み込みを妨げる。対処：`onboard-check` は対象ディレクトリしか見ない。`~/repos` より上に `CLAUDE.md` を置く運用は無いので検査しない。

## Migration Plan

1. テンプレート、スキル、`onboard-check`、`doctor` を先に入れる。ここまでは古いClaude Codeでも害が無い。
2. このマシンのPATHの `claude` を更新し、読み込みを確認してからこのリポジトリの `CLAUDE.md` を消す。
3. 戻すときは、`CLAUDE.md` に `@AGENTS.md` の1行を書けば元の動きになる。
