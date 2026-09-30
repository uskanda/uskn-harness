## Context

動機はproposal.mdのWhyにある。
`pr` スキルは統合ブランチ向けのPRに自動マージを付ける。`push` スキルは未コミットの変更があると `commit` を呼んで全部をコミットする。
どちらも、changeのディレクトリだけを載せたdraftの仕様PRという形に合わない。
SessionStart hookのrepo-contextが、platform（github / gitlab）、CLI、統合ブランチを渡す。無ければ `uskn-repo-context --json` で得られる。
`/spec` の直後、changeのディレクトリは未追跡のファイルとして作業ツリーにある。

## Goals / Non-Goals

**Goals:**
- 仕様PRの作成は、ユーザーの作業ツリーの別の変更を動かさない
- 止まる場面を、ブランチを作る前にすべて置く

**Non-Goals:**
- 仕様PRの中身（成果物）を書き換えること。直すのは `/spec` か `/opsx:update` の仕事である
- ループの起動と、本文でのループの案内。案内はループ本体と一緒に `add-loop-run` が足す。まだ無いコマンドを仕様PRで案内しないためである

## Decisions

- **置き場は `skills/spec-pr/`。** `spec` や `archive-push` と同じく、OpenSpecの手順が主なので `skills/git/` ではなく直下に置く
- **確認はすべてブランチを作る前に行う。** 順番は、対象の決定、成果物と `openspec validate --strict` の確認、公開済みかどうかの確認、ブランチ名の衝突の確認である。公開済みかどうかは2つの問いで判定する。1つ目は、`origin/<integration>` にchangeのディレクトリがあるかである。2つ目は、`origin/<integration>..HEAD` にそのディレクトリを触るコミットがあるかである。後者は履歴の書き換えを避けるために止める
- **ブランチは `git switch -c change/<name> origin/<integration>` で作る。** 未追跡のchangeのディレクトリは切り替えに付いてくる。ほかの未コミットの変更も付いてくるが、コミットしないのでそのまま残る。統合ブランチと衝突する変更があればgitが切り替えを拒むので、何も作らずに止まる。worktreeで作る案は、changeのディレクトリをコピーし、元を消す操作が要るので採らない
- **コミットは `commit` スキルに頼み、範囲と要約行を指定する。** 範囲は `openspec/changes/<name>/` だけ、1つのコミット、要約行は「`<name>`の仕様を追加」とする。`archive-push` と同じ頼み方である
- **pushは `git push -u origin change/<name>` を直接実行する。** `push` スキルは未コミットの変更を全部コミットするので使わない
- **PRとMRはCLIで直接作る。** GitHubは `gh pr create --draft`、GitLabは `glab mr create --draft` で、向き先は統合ブランチにする。自動マージの指定は付けない。本文は一時ファイルに書き、textlintを通してから渡す（`pr` スキルと同じ手順）
- **成果物へのリンクは絶対URLにする。** PRの本文の相対リンクはファイルに届かないためである。GitHubは `<repo URL>/blob/change/<name>/<path>`、GitLabは `<repo URL>/-/blob/change/<name>/<path>` とする
- **作り終えたら `git switch -` で元のブランチに戻る。** gitは1つのブランチを2つのworktreeで開けない。ループが後で `change/<name>` のworktreeを作れるよう、手元ではこのブランチを開いたままにしない。changeのディレクトリは作業ツリーから消えてブランチに移るので、報告でそのことと切り替えのコマンドを伝える
- **センサーは `bin/tests/spec-pr-skill.bats`。** `name: spec-pr` であることと、`disable-model-invocation: true` が無いことを確かめる。説明文の長さと `argument-hint` は既存の `skill-invocation` のテストが見る
- **本文に実例を2つ載せる。** 既存のchange名を渡す流れと、公開済みのchangeで止まる流れである

## Risks / Trade-offs

- アイデアを渡したとき、`spec` のgrillingで対話が長くなり、仕様PRの作成が同じ実行の最後になる → `spec` が終わった時点の成果物で確認を進める。途中で止めたらchange名を渡して再実行する
- 検出ロジックの漏れで、公開済みのchangeから二重に仕様PRを作る → ブランチ名の衝突の確認でも止まる。二重のPRは作られない
- ユーザーが元のブランチでchangeを探して見つからない → 報告にブランチ名と `git switch change/<name>` を必ず書く
- GitLabのMR作成は手元に実機が無く未確認 → `glab` のコマンドは偽物を使うテストでは確かめられないので、GitLabのリポジトリができたときに手で確かめる（grillingで後回しにした）
