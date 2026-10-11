## ADDED Requirements

### Requirement: 通知の送信先の検査
`doctor` は、通知の送信先の設定の有無を報告しなければならない（MUST）。
調べる値は `CLAUDE_TELEGRAM_BOT_TOKEN` と `CLAUDE_TELEGRAM_CHAT_ID` の2つ。それぞれ、環境変数にあればそれを使い、無ければ `~/.config/claude-notify/config.env` の値を使う。
両方に値があれば `ok`、どちらかが空なら `warn` とする。`doctor` はTelegramへ通信しない。

#### Scenario: 設定の無い端末
- **WHEN** `~/.config/claude-notify/config.env` が無く、環境変数も無い
- **THEN** `warn` に設定のファイルのパスと空のキーの名前が含まれ、終了コードは0

#### Scenario: 設定のある端末
- **WHEN** `config.env` に2つのキーの値がある
- **THEN** その項目は `ok` で、Telegramへの通信は起きない

### Requirement: 受信の設定の検査
受信の常駐プロセスを入れたmacOSで受信Botのトークンが空のとき、`doctor` は `warn` を報告しなければならない（MUST）。
入れたかどうかは、`com.claude.notify-telegram-bot` のplistの有無で判断する。トークンは `CLAUDE_TELEGRAM_RECV_TOKEN` から読む。

#### Scenario: トークンを消した端末
- **WHEN** plistがあり、`CLAUDE_TELEGRAM_RECV_TOKEN` が `config.env` と環境変数のどちらにも無い
- **THEN** `warn` にキーの名前が含まれ、終了コードは0

#### Scenario: 受信を入れていない端末
- **WHEN** plistが無い
- **THEN** 受信の設定についての出力は無い

### Requirement: 秘密を出力しない
`doctor` は、トークンの値を出力してはならない（MUST NOT）。

#### Scenario: 設定のある端末
- **WHEN** `config.env` にトークンがある端末で `doctor` を実行する
- **THEN** 出力のどの行にもトークンの値は現れない
