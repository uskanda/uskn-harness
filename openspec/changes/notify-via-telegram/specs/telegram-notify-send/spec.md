## Purpose

通知をTelegramへ送る側の規則。
Claude Codeが動く端末は、turnの終わりと確認依頼を送信Botでチャンネルへ投稿し、自分では発話しない。

## ADDED Requirements

### Requirement: メッセージの投稿
`claude-notify <文>` は、送信Botを使い、引数の文を持つメッセージをチャンネルへ1通投稿しなければならない（MUST）。
種類を指定しないとき、種類は `manual` とする。

#### Scenario: 手で実行する
- **WHEN** 送信先を設定した端末で `claude-notify "試験です"` を実行する
- **THEN** チャンネルにメッセージが1通現れ、1行目は `試験です` で終わり、識別行の種類は `manual`

### Requirement: 送信する端末は発話しない
`claude-notify` と `claude-notify-hook` は、発話してはならず、音を鳴らしてはならない（MUST NOT）。

#### Scenario: VOICEVOX が動いている macOS
- **WHEN** VOICEVOXが応答するmacOSの端末でturnが終わる
- **THEN** VOICEVOXへの要求も `say` の実行も起きず、チャンネルへの投稿だけが起きる

### Requirement: メッセージの書式
通知のメッセージは、ちょうど2行でなければならない（MUST）。
1行目は、種類を表す絵文字1つ、空白1つ、発話される文の順に並べる。
2行目は識別行で、次の形にする。

```
#claude_notify kind=<種類> host=<ホスト名> repo=<リポジトリ名> sid=<セッションIDの先頭8文字>
```

種類は `done`、`confirm`、`loop`、`manual` のどれか。種類ごとの絵文字は次のとおり。

```
done     ✅
confirm  ❓
loop     🏁（完了）、⛔（停止）
manual   🔔
```

リポジトリ名かセッションIDが分からないとき、その値は `-` にする。
値に含まれる空白は `_` に置き換える。
メッセージ全体が4096文字を超えるとき、1行目を切り詰める。

#### Scenario: turn の終わり
- **WHEN** ホスト `devbox` のリポジトリ `uskn-harness` で、セッション `ab12cd34ef56` のturnが終わる
- **THEN** 2行目は `#claude_notify kind=done host=devbox repo=uskn-harness sid=ab12cd34`

#### Scenario: git の外
- **WHEN** gitのリポジトリでないディレクトリで `claude-notify "試験です"` を実行する
- **THEN** 識別行の `repo` と `sid` は `-`

### Requirement: 書式の解釈を指定しない
`claude-notify` は、Telegramに対してメッセージの書式の解釈を指定してはならない（MUST NOT）。

#### Scenario: 記号を含むリポジトリ名
- **WHEN** リポジトリ名が `my_repo*test` である
- **THEN** 投稿は成功し、1行目と識別行にその名前がそのまま現れる

### Requirement: 送らない内容
`claude-notify-hook` は、プロンプト、Claude Codeの応答、ツールの入出力をメッセージに含めてはならない（MUST NOT）。

#### Scenario: 確認依頼の本文
- **WHEN** Notificationのhookの入力に、実行しようとしているコマンドの文字列が入っている
- **THEN** 投稿されるメッセージにその文字列は現れない

### Requirement: turn の終わりの通知
Claude Codeのturnが終わったとき、`claude-notify-hook done` は種類 `done` のメッセージを1通投稿しなければならない（MUST）。
発話される文は `<リポジトリ名>の作業が完了しました` とする。リポジトリ名が分からないときは `作業が完了しました` とする。

#### Scenario: リポジトリの中
- **WHEN** リポジトリ `uskn-harness` でturnが終わる
- **THEN** 1行目は、種類 `done` の絵文字、空白、`uskn-harnessの作業が完了しました` の順に並ぶ

### Requirement: 確認依頼の通知
確認依頼のNotificationが届いたとき、`claude-notify-hook` は3秒後に種類 `confirm` のメッセージを1通だけ投稿しなければならない（MUST）。
発話される文は `<リポジトリ名>の確認をお願いします` とする。
hookの入力の `notification_type` が次のどれかのNotificationは、確認依頼として扱わない。

- `idle_prompt`
- `auth_success`
- `elicitation_complete`
- `elicitation_response`

#### Scenario: 権限の確認
- **WHEN** `notification_type` が `permission_prompt` のNotificationが届き、ユーザーが10分のあいだ応答しない
- **THEN** 3秒後に、発話される文が `uskn-harnessの確認をお願いします` のメッセージが1通投稿され、2通目は投稿されない

#### Scenario: 待機の知らせ
- **WHEN** `notification_type` が `idle_prompt` のNotificationが届く
- **THEN** 何も投稿されない

### Requirement: 確認依頼の取り消し
猶予の3秒の間に同じセッションのStopかUserPromptSubmitが届いたとき、`claude-notify-hook` はその確認依頼を投稿してはならない（MUST NOT）。

#### Scenario: turn の終わりに重なる
- **WHEN** Notificationの1秒後に同じセッションのStopが届く
- **THEN** 投稿されるのは種類 `done` の1通だけ

#### Scenario: 別のセッション
- **WHEN** セッションAのNotificationの1秒後に、セッションBのStopが届く
- **THEN** セッションAの確認依頼は3秒後に投稿される

### Requirement: 送信先の設定
`claude-notify` は、送信先を2つのキーから読まなければならない（MUST）。
送信Botのトークンのキーは `CLAUDE_TELEGRAM_BOT_TOKEN`、チャンネルのキーは `CLAUDE_TELEGRAM_CHAT_ID` である。
それぞれの値は、環境変数にあればそれを使い、無ければ `~/.config/claude-notify/config.env` の値を使う。

#### Scenario: 環境変数が優先される
- **WHEN** `config.env` と環境変数の両方に、異なる `CLAUDE_TELEGRAM_CHAT_ID` がある
- **THEN** 環境変数のチャンネルへ投稿される

### Requirement: 送信先が未設定のとき
送信Botのトークンかチャンネルが空のとき、`claude-notify` は何も投稿せず、終了コード0で終わらなければならない（MUST）。

#### Scenario: 設定の無い端末
- **WHEN** `config.env` が無く、環境変数も無い端末でturnが終わる
- **THEN** Telegramへの通信は起きず、hookは終了コード0で終わる

### Requirement: 送信の打ち切り
投稿が `CLAUDE_TELEGRAM_TIMEOUT` 秒（既定は5）以内に終わらないとき、`claude-notify` は投稿を打ち切らなければならない（MUST）。

#### Scenario: 応答の無い回線
- **WHEN** Telegramが応答を返さない
- **THEN** `claude-notify` は5秒ほどで終わる

### Requirement: 送信に失敗したとき
投稿が失敗したとき、または打ち切られたとき、`claude-notify` は再送せず、終了コード0で終わらなければならない（MUST）。

#### Scenario: 回線が切れている
- **WHEN** ネットワークに届かない端末でturnが終わる
- **THEN** hookは終了コード0で終わり、Claude Codeにエラーは表示されない

### Requirement: トークンを引数に渡さない
`claude-notify` は、送信Botのトークンを、他のプロセスから見えるコマンドの引数に渡してはならない（MUST NOT）。

#### Scenario: 引数の記録
- **WHEN** curlの引数を記録する差し替えを置いて `claude-notify` を実行する
- **THEN** 記録された引数にトークンは現れない

### Requirement: 通知を止める環境変数
環境変数 `CLAUDE_NOTIFY_OFF` が `1` の間、`claude-notify-hook` は何も投稿してはならない（MUST NOT）。

#### Scenario: 無人のセッション
- **WHEN** `CLAUDE_NOTIFY_OFF=1` で起動したClaude Codeのturnが終わる
- **THEN** 何も投稿されず、hookは終了コード0で終わる

### Requirement: 送信が動く環境
`claude-notify` と `claude-notify-hook` は、Linux、macOS、WSL、WindowsのGit Bashで、同じメッセージを投稿しなければならない（MUST）。

#### Scenario: Windows の Git Bash
- **WHEN** `python3` という名前のコマンドが無く、`py` があるWindowsのGit Bashでturnが終わる
- **THEN** 種類 `done` のメッセージが1通投稿される

#### Scenario: WSL
- **WHEN** WSLの中でturnが終わる
- **THEN** メッセージが1通投稿され、Windows側のPowerShellは起動されない
