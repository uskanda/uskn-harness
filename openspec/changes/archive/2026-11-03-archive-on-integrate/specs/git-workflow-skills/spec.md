## ADDED Requirements

### Requirement: pr は統合の前にarchiveする
integrationモードとcustomモードの `pr` は、pushの前に `uskn-archive-check --base origin/<target>` を実行しなければならない（MUST）。
出力された変更ごとに、`pr` は `archive-push <name>` を呼ばなければならない（MUST）。
releaseモードとqaモードでは、この確認をしない。

#### Scenario: 未archiveの変更がある
- **WHEN** 変更 `add-x` を実装したブランチで、引数なしの `pr` を実行する
- **THEN** `pr` は `archive-push add-x` を呼び、archiveのコミットがpushされてからPRを作る

#### Scenario: 未archiveの変更が無い
- **WHEN** `uskn-archive-check` が何も出力しない
- **THEN** `pr` はarchiveに進まず、今までどおりpushしてPRを作る

#### Scenario: release モード
- **WHEN** 統合ブランチと既定ブランチが別のリポジトリで、`pr <default>` を実行する
- **THEN** `uskn-archive-check` は実行しない

### Requirement: push は既定ブランチと統合ブランチへの直接のpushの前にarchiveする
送り先が既定ブランチか統合ブランチのとき、`push` はpushする前に `uskn-archive-check --base origin/<送り先>` を実行しなければならない（MUST）。
出力された変更ごとに、`push` は `archive-push <name>` を呼ばなければならない（MUST）。
送り先がそれ以外のブランチのとき、`push` はこの確認をしてはならない（MUST NOT）。

#### Scenario: main への直接の push
- **WHEN** 統合ブランチが `main` のリポジトリで、変更 `add-x` を実装した `main` から `push` を実行する
- **THEN** `push` は `archive-push add-x` を呼ぶ。`archive-push` の中の `push` は該当なしで、archiveのコミットをpushする

#### Scenario: 作業ブランチへの push
- **WHEN** `change/add-x` から `push` を実行する
- **THEN** `uskn-archive-check` は実行せず、今までどおりpushする

### Requirement: archive-push が止まったら統合しない
`pr` と `push` から呼んだ `archive-push` の止まったとき、呼んだスキルは統合の操作をせずに止まり、`archive-push` の報告を伝えなければならない（MUST）。

#### Scenario: 未実装の項目が残っている
- **WHEN** `pr` が呼んだ `archive-push add-x` が、変更を伴う未完了の項目で止まる
- **THEN** `pr` はpushもPRの作成もせず、その項目を報告する

### Requirement: archive保留の宣言を書く
ユーザーが変更をまだarchiveしないと言ったとき、エージェントはその変更のディレクトリに `.archive-later` を作り、理由を1行書いてコミットしなければならない（MUST）。

#### Scenario: チャットでの宣言
- **WHEN** ユーザーが「add-xはまだarchiveしない。続きの作業がある」と言う
- **THEN** `openspec/changes/add-x/.archive-later` に理由の1行が書かれてコミットされ、`uskn-archive-check` は `add-x` を出力しない
