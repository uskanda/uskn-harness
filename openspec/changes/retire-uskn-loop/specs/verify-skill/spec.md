## ADDED Requirements

### Requirement: 差分の検査
作業が終わったと報告する前とPRを作る前に、`verify` は `uskn-diff-check --base origin/<統合ブランチ>` を実行しなければならない（MUST）。
統合ブランチは `<repo-context>` の値から取る。進行中の変更があれば、その `tasks.md` を `--allow-from` で渡す。
終了コードが1のとき、エージェントは消したテストかskipを元に戻すか、ユーザーかtasksが求めたことを報告に書かなければならない（MUST）。
`verify-setting` の行は、変えた理由とともに報告に載せる。終了コードが2のときは、判定できなかったことを報告に書く。

#### Scenario: テストを消して通した
- **WHEN** 失敗するテストファイルを消して `make verify` が通り、エージェントが完了と言おうとする
- **THEN** `uskn-diff-check` が `test-deleted` を出力し、エージェントはテストを戻すか、消した理由を報告に書く

#### Scenario: 検証の設定だけを変えた
- **WHEN** 変更が `Makefile` のverifyのターゲットを書き換えている
- **THEN** 報告に `Makefile` を変えたことと、その理由が載る
