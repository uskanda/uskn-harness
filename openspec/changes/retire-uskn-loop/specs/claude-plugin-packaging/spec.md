## MODIFIED Requirements

### Requirement: スキル向けの短いコマンド
プラグインは `bin/` に、スキルがBashで呼ぶ補助スクリプトの短いコマンドを持たなければならない（MUST）。
`uskn-repo-context` は `session-start.sh` を、`uskn-terms-check` は `terms-check.sh` を、同じ引数で実行する。
`uskn-archive-check` も同じく、`archive-check.sh` を同じ引数で実行する。
`uskn-diff-check` も同じく、`diff-check.sh` を同じ引数で実行する。
終了コードと出力は、元のスクリプトと同じにする。
プラグインがsymlinkを通して読み込まれていても動く。

#### Scenario: ブランチモデルの取得
- **WHEN** gitリポジトリの中で `uskn-repo-context --plain branches` を実行する
- **THEN** `session-start.sh --plain branches` と同じ4行が出力される

#### Scenario: 用語の検査
- **WHEN** 実在しない名前を含む文書に `uskn-terms-check` を実行する
- **THEN** 指摘が出力され、終了コードは1

#### Scenario: 未archiveの変更の判定
- **WHEN** 未archiveの変更を足したブランチで `uskn-archive-check --base origin/main` を実行する
- **THEN** `archive-check.sh --base origin/main` と同じ出力と終了コードになる

#### Scenario: 差分の検査
- **WHEN** テストファイルを消したブランチで `uskn-diff-check --base origin/main` を実行する
- **THEN** `diff-check.sh --base origin/main` と同じ出力と終了コードになる
