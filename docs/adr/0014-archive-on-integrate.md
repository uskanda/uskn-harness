# ADR-0014: 統合の操作の前に、ブランチが手を付けた変更をarchiveする

- 状態：採用（2026-11-03）
- 決定者：uskanda（change `archive-on-integrate`。issue #19のQ1〜Q6と計画への `/ok`）
- 関連：ADR-0005、ADR-0007、issue #19

## 文脈

変更のarchiveは、ユーザーが `/archive-push` を打つまで行われなかった。`archive-push` は `disable-model-invocation: true` を持ち、エージェントからは呼べなかった。
PR #16と#18はarchiveされないままマージされた。`openspec/changes/` には、doctor-probe-nested-usernsとsandbox-rules-revisitが残った。
2つのPRは、GitHubの画面からマージされたとみられる。mainにはブランチ保護が無い。

## 決定

1. 統合の操作の前に、そのブランチが手を付けた未archiveの変更をarchiveする。統合の操作とは次の3つである
   - `pr` のintegrationモードとcustomモード
   - `push` による、既定ブランチか統合ブランチへの直接のpush
   - エージェントが実行する `gh pr merge` と `glab mr merge`
2. releaseモード、qaモード、`spec-pr`、作業ブランチへの途中のpushは、統合の操作に含めない
3. 判定は `uskn-archive-check --base <ref>` の1つにまとめる。hook、CI、スキルが同じものを呼ぶ。gitだけを使い、HEADの木を見る
4. `pr` と `push` は、判定が挙げた変更ごとに `archive-push` を呼ぶ。そのため `archive-push` から `disable-model-invocation` を外す。`archive-push` が止まったら、統合しない
5. archiveしないときは、archive保留の宣言として、変更のディレクトリに `.archive-later` を置き、理由を1行書く。ユーザーがチャットで宣言したら、エージェントが書く
6. bash-guardは、判定が該当ありを返す統合の操作を拒否する。判定できないときは止めない
7. このリポジトリの `make verify` は、GitHub Actionsのdraftでないpull requestで、未archiveの変更を持ち込む差分を失敗にする。製品リポジトリのCIには入れない
8. uskn-loopは変えない。ループは変更をarchiveしない（ADR-0007）

決定7は、計画では `.github/workflows/verify.yml` に別のjobを足すことにしていた。実装した実行はworkflowを変えられないので、CIがすでに走らせる `make verify` に入れた。

## 検討した代替案

| 案 | 退けた理由 |
|---|---|
| `pr` と `push` が止まり、`/archive-push` の実行を案内するだけにする | 今回と同じ忘れが起きる |
| `pr` と `push` が `opsx:archive` を直接呼ぶ | tasksの分類と、archiveの前後の検証が抜ける |
| 宣言を変更の `.openspec.yaml` のキーにする | OpenSpec CLIが知らないキーを受け付けるかに依存する |
| 宣言をPRの本文かコミットのtrailerに書く | hookとCIが同じ方法で読めず、変更に付いて残らない |
| hookだけにする | 画面からのマージを捕まえられない |
| activeな変更を全部数える | ブランチが手を付けていない変更まで止める |
| ループが完了の後にブランチ上でarchiveする | archiveを人の承認の後に置く前提を変える。別のissueで決める |

## 結果

- 良い点：エージェントの統合の操作は、archive済みの変更を運ぶ。スキルを通らない操作もhookが止める。画面からマージする前に、PRのチェックが赤くなる
- 引き受けるコスト：mainにブランチ保護が無いので、CIの失敗はマージを止めない。`verify.yml` が `ready_for_review` で起動しないので、draftをレビュー待ちにしただけでは確認が走らない。次のpushで走る
- 後回し：`verify.yml` の `types` に `ready_for_review` を足すこと。user層の指示（`templates/user/` の指示ファイル）に同じ規則を1行足すこと。どちらもこの実行では変えられないファイルにある
