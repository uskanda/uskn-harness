## ADDED Requirements

### Requirement: 未archiveの変更を持ち込むpull requestの検査
GitHub Actionsのdraftでないpull requestで走るとき、`make verify` は未archiveの変更を確かめなければならない（MUST）。
確かめるのは、そのpull requestが持ち込む変更で、`uskn-archive-check` を使う。
比べる先は、マージ用のコミットの1つめの親とする。
該当があれば、`make verify` は変更の名前を出力して失敗しなければならない（MUST）。
この検査はこのリポジトリの `Makefile` だけが持ち、製品リポジトリには配らない。

#### Scenario: 未archiveの変更を持ち込む
- **WHEN** `GITHUB_EVENT_NAME` が `pull_request` で、draftでないpull requestが、archive保留の宣言の無い変更 `add-x` を持ち込む
- **THEN** `make verify-archive` は非ゼロで終わり、出力に `add-x` が含まれる

#### Scenario: draft の pull request
- **WHEN** 同じ差分のpull requestがdraftである
- **THEN** `make verify-archive` は確かめずに終了コード0で終わる

#### Scenario: pull request の外
- **WHEN** `GITHUB_EVENT_NAME` が `pull_request` でない
- **THEN** `make verify-archive` は `skipped` を出力して終了コード0で終わる

#### Scenario: 判定できない（strict）
- **WHEN** draftでないpull requestで、`uskn-archive-check` が終了コード2を返し、`VERIFY_STRICT=1` である
- **THEN** `make verify-archive` は非ゼロで終わり、出力に `[archive]` と `VERIFY_STRICT` が含まれる
