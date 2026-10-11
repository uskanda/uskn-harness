## ADDED Requirements

### Requirement: セッションの通知を止める
`uskn-loop run` は、実装役と監査役を起動するとき、環境変数 `CLAUDE_NOTIFY_OFF=1` を渡さなければならない（MUST）。

#### Scenario: 3 ラウンドのループ
- **WHEN** 送信先を設定した端末で、3ラウンドで完了するループを実行する
- **THEN** 実装役と監査役のturnの終わりの通知は1通も投稿されない

### Requirement: ループの終わりの通知
完了基準を満たしたとき、または停止条件に当たったとき、`uskn-loop run` は種類 `loop` の通知を1通投稿しなければならない（MUST）。
発話される文は、完了のとき `<リポジトリ名>のループが完了しました`、停止のとき `<リポジトリ名>のループが停止しました` とする。
投稿には通知のコマンド `claude-notify` を使う。

#### Scenario: 完了
- **WHEN** リポジトリ `uskn-harness` のループが2ラウンド目で完了基準を満たす
- **THEN** 発話される文が `uskn-harnessのループが完了しました` の通知が1通投稿される

#### Scenario: 停止
- **WHEN** 監査役が人の判断が要る問いを返す
- **THEN** 発話される文が `uskn-harnessのループが停止しました` の通知が1通投稿される

#### Scenario: 受け付けなかった実行
- **WHEN** 受け付け条件を満たさず、`uskn-loop run` が終了コード2で終わる
- **THEN** 通知は投稿されない

### Requirement: 通知の失敗でループの結果を変えない
ループの終わりの通知を投稿できないとき、`uskn-loop run` は終了コードとPRの扱いを変えてはならない（MUST NOT）。

#### Scenario: 通知のコマンドが無い
- **WHEN** `claude-notify` が見つからない端末でループが完了する
- **THEN** PRのdraftは解除され、終了コードは0
