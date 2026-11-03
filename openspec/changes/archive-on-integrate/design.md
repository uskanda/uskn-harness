# Design

## Context

動機はproposal.mdのWhyを見る。決定の出典はgrilling.mdにある。

- `archive-push` は `disable-model-invocation: true` を持ち、ユーザーしか呼べない。tasksの分類、archiveの前後のverify、コミットの分け方、`push` までを1回で進める
- `pr` はintegrationモードとcustomモードで、現在のブランチをpushしてからPRを作り、auto-mergeを設定する。`push` は現在のブランチをそのままpushする
- bash-guardは、コマンドを単純なコマンドに分け、`cd` を追って作業ディレクトリを決めてから、1つずつ判定する
- CIは `.github/workflows/verify.yml` の1つのjobで `make verify VERIFY_STRICT=1` を走らせる。`actions/checkout` は既定の深さ1で、pull requestではマージ用のコミット（`refs/pull/<n>/merge`）を取り出す
- mainにはブランチ保護が無く、PRはGitHubの画面でもマージされる

## Goals / Non-Goals

**Goals:**

- エージェントが統合の操作をするとき、そのブランチが手を付けた未archiveの変更が、統合の前にarchiveされる
- エージェントがスキルを通らずに統合の操作をしようとしても、hookが止める
- 画面からのマージの前に、PRのチェックが赤くなって気付ける

**Non-Goals:**

- ブランチが手を付けていない、もとからあるactiveな変更をarchiveすること
- 製品リポジトリのCIに同じ確認を入れること。製品リポジトリのCIはハーネスが配らない
- uskn-loopの完了の扱いを変えること

## Decisions

### D1 判定は `uskn-archive-check` の1つにまとめる

本体は `plugins/uskn-harness/hooks/scripts/archive-check.sh` に置く。
短いコマンド `plugins/uskn-harness/bin/uskn-archive-check` から呼べるようにする（ADR-0005の形）。
hook、CI、スキルは同じものを呼ぶ。

```
uskn-archive-check --base <ref> [DIR]
```

- `git diff --name-only <ref>...HEAD -- openspec/changes/` の出力から、変更の名前を集める。名前は `openspec/changes/<name>/` の `<name>` で、`archive/` は除く
- そのうち、HEADの木に `openspec/changes/<name>/` があり、`openspec/changes/<name>/.archive-later` が無いものを、1行に1つ出力する
- 終了コードは、該当があれば1、無ければ0とする
- 判定できないときは2とし、標準エラーに理由を出す。たとえば `<ref>` の無いときや、merge-baseの求まらないときである
- gitだけを使う。OpenSpec CLIとネットワークは使わない

作業ツリーではなくHEADの木を見る。pushとマージで運ばれるのはコミットだからである。`archive-push` がarchiveをコミットすれば、該当は無くなる。

- 退けた案：`openspec list --json` のactiveな変更を全部数える。ブランチが手を付けていない変更まで止め、OpenSpec CLIの無いCIやhookで動かない
- 退けた案：hook、CI、スキルがそれぞれ判定を書く。判定がずれる

### D2 archive保留の宣言は `.archive-later`

変更のディレクトリに `.archive-later` を置き、理由を1行書く。
OpenSpec CLIは、変更のディレクトリにある知らないファイルを読み飛ばし、archiveのときはディレクトリごと移す。宣言は理由ごとarchiveに残る。
ユーザーがチャットで「archiveしない」と言ったら、エージェントがこのファイルを書き、コミットする。

### D3 bash-guardは統合の操作を見つけて `uskn-archive-check` を呼ぶ

既存の単純なコマンドの解析を使う。作業ディレクトリは、`cd` を追った結果と、gitの `-C` で決まる。

- `gh pr merge` と `glab mr merge`：比べる先は `origin/<統合ブランチ>` とする。統合ブランチは `session-start.sh --plain branches` の値から取る
- `git push`：送り先が既定ブランチか統合ブランチのときに限る。送り先は次の順に決め、比べる先は `origin/<送り先>` とする
  1. refspecがあれば、その送り先（`src:dst` の `dst`。`:` が無ければそのもの。`HEAD` は現在のブランチ）。`+` と `refs/heads/` は外す
  2. refspecが無ければ、上流のブランチ名。上流が無ければ、現在のブランチ
- `uskn-archive-check` が1を返したら拒否する。理由には変更の名前を並べ、`/archive-push <name>` を実行するか、`.archive-later` で宣言するよう案内する
- 0と2のときは、この判定では何も言わない（bash-guardの「誤報より見逃し」の契約）

計画の「上流のない現在のブランチ」は、上流がある `git push` を判定しないとも読める。上流があるときは上流のブランチ名で判定する。`push` スキルは上流があると引数なしの `git push` を実行するので、これを外すと既定ブランチへの直接のpushを見逃すためである。

### D4 スキルは統合の操作の前に `archive-push` を呼ぶ

- `pr` のintegrationモードとcustomモード：pushの前に `uskn-archive-check --base origin/<target>` を実行する。出力された変更ごとに `archive-push <name>` を呼ぶ
- `push`：送り先が既定ブランチか統合ブランチのとき、step 5の前に同じ手順を行う
- `archive-push` は最後に `push` を呼ぶ。そのときはarchiveのコミットで該当が無くなっているので、2回目の `push` はarchiveに進まない。循環しない
- `archive-push` が止まったら（変更を伴う未完了の項目、verifyの失敗）、呼んだスキルも止まって報告する。未archiveのまま統合しない
- `archive-push` は `.archive-later` のある変更を選ばない

`archive-push` から `disable-model-invocation` を外す。ユーザーが `/archive-push` と打つ使い方は変わらない。

### D5 CIの確認は `make verify` の `verify-archive` で行う

承認された計画では、`verify.yml` に別のjob `archive-check` を足すことにしていた。
この変更を実装した実行（switchboard）は、`.github/workflows/` を変えられない。そこで、CIがすでに走らせている `make verify` に、target `verify-archive` を足す。

- `GITHUB_EVENT_NAME` が `pull_request` のときだけ確かめる。それ以外では `[archive] skipped` を出して終了コード0
- `GITHUB_EVENT_PATH` のJSONで、`.pull_request.draft` が `true` なら確かめない
- 比べる先は、マージ用のコミットの1つめの親 `HEAD^1`（PRの統合先の先端）とする。深さ1のcheckoutで親が無ければ、`git fetch --depth=2 origin <GITHUB_SHA>` で取り寄せる
- `uskn-archive-check` が1を返したら失敗にする。2を返したら、strictモードでは失敗、そうでなければskipとする

- 退けた案：`verify.yml` にjobを足す（承認された計画）。このリポジトリの持ち主が後で足せる。足すなら `pull_request` の `types` に `ready_for_review` を加える
- 退けた案：確かめない。#16と#18のような画面からのマージに気付けない

### D6 uskn-loopは変えない

`uskn-loop run` は変更をarchiveしない（spec loop-run）。完了コメントの案内もそのままにする。
人がマージする前に、CIの `verify-archive` が未archiveを知らせる。

## Risks / Trade-offs

- 危険：`verify.yml` は `ready_for_review` で起動しない。draftのPRをレビュー待ちにしただけでは、`verify-archive` が走らない。対策：次のpushで走る。持ち主が `types` を足せば閉じる
- 危険：mainにブランチ保護が無く、CIの失敗はマージを止めない。対策：PRに赤い印が付くので、マージの前に気付ける
- 危険：`gh pr merge <n>` が、現在のブランチと別のPRを指すことがある。対策：無い。現在のブランチを比べるので見逃すが、誤報より見逃しを選ぶ
- 危険：計画にあったuser層の指示への1行が入らない。`templates/user/CLAUDE.md` は、この実行が変えられないファイルと名前が同じだからである。対策：スキルの手順とhookが同じ規則を持つ。持ち主が後で足せる
