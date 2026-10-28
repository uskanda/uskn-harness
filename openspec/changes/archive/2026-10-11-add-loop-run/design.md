## Context

動機はproposal.mdのWhyに、調査は `docs/loop-engineering-2026-09.md` にある。
`claude -p` について、次のことを公式文書で確かめた。

- `--permission-mode auto` は `-p` でも使える。分類器が承認しない操作は拒否される
- `--permission-prompts none` を付けると、確認待ちで止まらず、AskUserQuestionが外れる
- `--max-budget-usd` は、見積もりの費用が上限に達した時点で実行を止める。`--output-format json` は見積もりを `total_cost_usd` で返す
- `--json-schema` は、道具を使い終えたあとの結果を `structured_output` に返す
- `--bare` を付けなければ、ユーザー層のスキル、プラグイン、hookが読み込まれる

最後の点により、実装役のセッションでもwrite-guard、bash-guard、verify gateが働く。
プラグインの `bin/` はClaude CodeのBashツールのPATHにしか載らないので、ターミナルから呼ぶコマンドは `~/.local/bin` に置く（ADR-0005）。
hookの状態は `${USKN_STATE_DIR:-${XDG_STATE_HOME:-~/.local/state}/uskn-harness}` に置く決まりがある。
batsのテストは `bin/tests/fixtures/fake-bin` に外部コマンドの偽物を置く形をとっている。

## Goals / Non-Goals

**Goals:**
- 続けるか止めるかを、LLMでなくスクリプトの決まった規則で判定する
- どの経路で止まっても、PRの状態（draftかどうか、コメント）から次にすることが読める
- 偽物の `claude`、`gh`、`glab` を使い、ネットワークなしで全経路をテストできる

**Non-Goals:**
- ウォッチャー、ラベル、1日ごとの費用上限、コメント駆動（段階2と3）
- コンテナによる隔離。段階1は手元のマシンで、ハーネスのhookとautoの権限モードに頼る

## Decisions

### 構成

- 入口は `bin/uskn-loop` で、下位コマンドは段階1では `run` だけにする。段階2で `watch` を足す
- 補助ファイルは `loop/` に置く。中身は次の4種類である
    - `loop/lib/*.sh`：共通の関数
    - `loop/prompts/implementer.md` と `loop/prompts/auditor.md`：英語の指示
    - `loop/verdict.schema.json`：判定のJSON Schema
    - `loop/limits.env`：上限の既定値
- `bin/uskn-loop` は自分の実体のパスから `loop/` を探す。`~/.local/bin` のsymlinkから呼ばれても、ハーネスのcheckoutのファイルを読む
- ホストは、originに設定したURL（insteadOfで書き換える前の値）から判定する。名前で判定できないホストのときだけ、ハーネスの `session-start.sh` を直接呼んで尋ねる。hookと同じく、プラグインの `bin/` には頼らない。`session-start.sh` は書き換えたあとのURLを読むので、テストでoriginを手元のリポジトリに向けると判定できなくなる

### ホストへの操作を1か所にまとめる

`loop/lib/host.sh` だけが `gh` と `glab` を呼ぶ。ほかの部分はホストを知らない。
関数は、PRかMRの情報の取得、ログイン中のユーザーの取得、コメントの作成と書き換えと検索、draftの解除の5つである。

| 判定 | GitHub | GitLab |
|---|---|---|
| fork | `gh pr view --json isCrossRepository` | `source_project_id` と `target_project_id` の比較 |
| 基底ブランチとの衝突 | `mergeable` が `CONFLICTING` | `has_conflicts` が真 |
| draftの解除 | `gh pr ready` | `glab mr update --ready` |
| コメントの書き換え | `gh api` でissue commentをPATCH | `glab api` でMRのnoteをPUT |

### changeの特定

PRの差分（`git diff --name-only origin/<base>...HEAD`）で、`openspec/changes/<name>/` の下にファイルを追加しているディレクトリを数える。archiveの下は数えない。
ちょうど1つのときだけ受け付ける。grillingでは「archiveされていないchangeがちょうど1つ」とした。差分で数えるのは、統合ブランチに別の進行中のchangeがあっても受け付けるためである。
成果物がそろっているかは、worktreeを作る前に `origin/<head>` の木をgitで読んで確かめる。求めるのは、grilling.md、proposal.md、tasks.mdがあることと、specsがあることである。specsは、`specs/` の下に `spec.md` があるか、`.openspec.yaml` が `skip_specs: true` を持てばよい。

### worktree

- worktreeは次のコマンドで作り、pushは `git push origin HEAD:<head>` で行う

    ```bash
    git worktree add -B loop/pr-<番号> .claude/worktrees/loop-pr-<番号> origin/<head>
    ```

- headのブランチを直接checkoutしない。手元で同じブランチが開かれていると、gitは2つ目のworktreeを拒むからである
- 再開のときは、ラウンドの前に `origin/<head>` をfetchし、fast-forwardできれば進める。できなければ基底ブランチとの衝突と同じく止める
- `.claude/worktrees/` がgitに無視されていないリポジトリでは、`.git/info/exclude` に1行足す。プロダクトリポジトリの追跡ファイルは変えない

### 状態

- 置き場は `<状態の場所>/loop/<host>/<owner>/<repo>/<番号>/` とする。grillingの置き場にhostを加えたのは、GitHubとGitLabに同じ名前のリポジトリがあっても混ざらないようにするためである
- `<state.json>` にラウンドの数え、費用の合計、状態、進捗コメントのID、ラウンドごとの要約を持つ。ラウンドごとの生の出力は `round-<k>/` に置く
- ロックは `mkdir` で作るディレクトリとPIDで行う。PIDのプロセスが無ければ、残ったロックを引き継ぐ

### 実装役

- 実装役は、worktreeを作業ディレクトリにして次のコマンドで起動する。60分の上限はhookの `with_timeout` と同じ方法でかける

    ```bash
    claude -p "<指示>" --permission-mode auto --permission-prompts none \
      --max-budget-usd 10 --output-format json
    ```
- 実装役への規則は `loop/prompts/implementer.md` に置き、`--append-system-prompt-file` で渡す。指示の本文は、1ラウンド目が `/opsx:apply <change>` だけで、2ラウンド目以降は修正必須の指摘と失敗したセンサーの出力の末尾である。1ラウンド目の本文に規則を足さないのは、`/opsx:apply` に続く文字列がコマンドの引数として渡るからである
- 指示では、`commit` スキルでコミットすること、pushとマージとarchiveをしないことを求める
- 実装役が終わったら、`total_cost_usd` を費用の合計に足し、新しいコミットがあればpushする

### 計算的センサー

- 順番は、未コミットの変更、検証規約、`openspec validate <change> --strict`、tasks.md、差分の検査である。安い検査を先に置く
- 1つでも失敗したら、そのラウンドの監査役は起動しない。監査役は1回3ドルかかるので、機械で分かる失敗を先に直させる
- 検証規約は全体を走らせる。上限は30分とし、`loop/limits.env` に置く。verify-fastは変わったファイルに絞るので、完了の判定には使わない
- 差分の検査は、`git diff --diff-filter=D` で消えたテストファイルを、追加された行の正規表現でskipの印を見つける。テストファイルは、パスに `test`、`spec`、`__tests__` を含むか、拡張子が `.bats` のファイルとする。`openspec/` の下は文書なので除く。tasks.mdがそのパスに触れていれば失敗としない
- skipの印はテストファイルの種類ごとに見分ける。batsは行頭の `skip`、JavaScriptとTypeScriptは `.skip(` と `xit(` などである。種類を見ないと、検査のコードや仕様の文書にある `.skip(` という文字列まで誤ってskipの印と判定するからである
- 検証の設定は、`Makefile`、`package.json`、`.github/workflows/`、`.gitlab-ci.yml`、textlintの設定ファイルの変更で見分ける

### 監査役

- 監査役は次のコマンドで起動する

    ```bash
    claude -p "<指示>" --model opus --effort high \
      --tools Read,Grep,Glob,Bash --disallowedTools Edit,Write,NotebookEdit \
      --strict-mcp-config --permission-mode auto --permission-prompts none \
      --max-budget-usd 3 --json-schema "<schema>" --output-format json
    ```
- モデルは別名 `opus` で指定する。今はOpus 5.5を指す。Claude Codeの版を縛らないハーネスの方針に合わせ、後継のOpusにも自動で移る
- `--tools` にSkillを入れないので、監査役はスキルを呼べない。`--strict-mcp-config` で、MCPのサーバーも読み込まない
- 指示には、changeの成果物のパス、差分の範囲、センサーの結果、確認させる設定の変更、前のラウンドの指摘を渡す。シナリオごとにテストを挙げて実際に走らせること、疑ってかかることを求める
- 修正必須にするのは、specの要件かシナリオを満たしていないとき、シナリオを確かめるテストが無いとき、設定の変更に理由が無いとき、明らかな誤りがあるときに限る
- 判定は `jq '.structured_output'` で読み、4つの欄がそろっているかを確かめる。欠けていれば「判定なし」として止める
- 完了とみなすのは、判定がpassで修正必須の指摘が無く、シナリオが1つ以上あり、どのシナリオにもテストが挙がって判定がpassのときである。仕様の網羅の層を、監査役の申告だけでなく判定の中身でも確かめる
- 監査の前にHEADを記録する。監査のあとは、そのHEADへの `git reset --hard` と `git clean -fd` で戻す。監査の前には、未コミットの変更が無いことを計算的センサーで確かめてある

### 進展なし

指摘の要約の文言はラウンドごとに変わる。そのため、文言の代わりに次の2つを比べる。修正必須の指摘があるファイルの集合と、失敗したセンサーの名前の集合である。
2ラウンド続けて両方が同じなら止める。

### 上限と終了コード

- PRごとの費用の合計は、ラウンドを始める前に確かめる。1回の呼び出しの使いすぎは `--max-budget-usd` が抑えるので、合計が上限を超えるのは最大でも1ラウンド分である
- 上限の既定値は `loop/limits.env` に置く。名前が `USKN_LOOP_` から始まる環境変数を渡すと、既定値を上書きできる。試験の結果を見て調整するためである
- 終了コードは、完了が0、想定外の失敗が1、受け付けない場合と使い方の誤りが2、停止が3とする

### 進捗コメント

- `<state.json>` から毎回全文を組み立て、IDのコメントを書き換える。IDが無いときは、印 `<!-- uskn-loop -->` を持つ自分のコメントを探す
- 生の出力は載せず、ローカルのログの場所を書く

### テスト

- `bin/tests/uskn-loop.bats` で、一時ディレクトリに本物のgitのbareリポジトリをoriginとして作る
- 偽物の `claude` は、呼ばれるたびに筋書きのファイルを1つ読み、worktreeにコミットを作り、JSONを出力する
- 偽物の `gh` と `glab` は、呼び出しを記録し、用意したJSONを返す
- 受け付け条件、ロック、再開、各停止条件、作業ツリーの復元、コメントの作成と書き換え、GitLabの経路を確かめる

### 配布と記録

- `bin/uskn-harness` のsyncとdoctorに `~/.local/bin/uskn-loop` を足す。`--remove` でも取り除く
- `Makefile` のverify-fastで、`bin/uskn-loop` と `loop/` の変更に `bin/tests/uskn-loop.bats` を対応させる
- `spec-pr` の本文の雛形の進め方に `uskn-loop run <このPRの番号>` の行を足し、報告の次の一歩にもループを加える。`bin/tests/spec-pr-skill.bats` で雛形の行を確かめる
- `bin/tests/skill-commands.bats` が認めるコマンドに、リポジトリの `bin/` の実行ファイルを加える。今はインストーラとプラグインの `bin/` だけを認めている。`uskn-loop` はプラグインでなくリポジトリの `bin/` に置くからである
- ADR-0007を `docs/adr/0007-loop-runner.md` に書き、AGENTS.mdのLayout表に `loop/` の行を、README.mdの機能の表にループの行を足す

## Risks / Trade-offs

- autoの権限モードが、テストに要るコマンドを拒む → 拒否は実装役の出力に残る。試験で頻出するものがあれば、ユーザー層の許可の設定に足す
- 監査役が判定を甘くする、または毎回違う指摘を出す → 完了基準の2層を計算的センサーにしてある。試験では人が指摘を採点し、指示を直す
- 進展なしの判定が粗く、別の問題を同じファイルで直している途中でも止まる → 回数の上限より前に人へ戻すほうを選ぶ。止まったら再開のコマンドで続けられる
- 状態のディレクトリがPRごとに増え続ける → 段階1では手で消す。段階2でsyncの掃除に含めるかを決める
- GitLabの経路は実機で確かめていない → 偽物の `glab` のテストで形だけを確かめ、GitLabのリポジトリができたときに手で試す
- 手元のマシンにコンテナの隔離が無い → 受け付けるのは自分のPRだけにし、ハーネスのwrite-guardとbash-guard、autoの権限モードで操作を制限する
