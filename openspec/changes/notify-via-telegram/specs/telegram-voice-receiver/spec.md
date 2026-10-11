## Purpose

受信の常駐プロセスの規則。
手元の端末で受信Botとしてチャンネルの投稿を読み、Claude Codeの通知だけを発話する。送信する側の端末とは、チャンネルだけでつながる。

## ADDED Requirements

### Requirement: 投稿の受信
`claude-notify-telegram-bot run` は、受信Botとして、Bot APIの長ポーリングで投稿を読み続けなければならない（MUST）。
受信Botのトークンは `CLAUDE_TELEGRAM_RECV_TOKEN` から、チャンネルは `CLAUDE_TELEGRAM_CHAT_ID` から読む。
それぞれの値は、環境変数にあればそれを使い、無ければ `~/.config/claude-notify/config.env` の値を使う。

#### Scenario: 別の端末の通知
- **WHEN** 受信の常駐プロセスが動くmacOSの端末があり、SSHの先の端末でturnが終わる
- **THEN** macOSの端末が、数秒のうちに `<リポジトリ名>の作業が完了しました` と発話する

#### Scenario: 送信の設定が無い端末
- **WHEN** `CLAUDE_TELEGRAM_BOT_TOKEN` が空で、`CLAUDE_TELEGRAM_RECV_TOKEN` と `CLAUDE_TELEGRAM_CHAT_ID` がある
- **THEN** 受信の常駐プロセスは動き、届いた通知を発話する

### Requirement: 受け付ける送り元
受信の常駐プロセスは、`CLAUDE_TELEGRAM_CHAT_ID` のチャンネルの投稿と、そのチャンネルからグループへ自動で転送された投稿のほかを、発話してはならない（MUST NOT）。

#### Scenario: 別のチャンネル
- **WHEN** 受信Botが管理者である別のチャンネルに、識別行のあるメッセージが投稿される
- **THEN** 発話は起きない

#### Scenario: 人の書き込み
- **WHEN** グループに人が識別行のあるメッセージを書き込む
- **THEN** 発話は起きない

### Requirement: 識別行の無い投稿
投稿の2行目が `#claude_notify` で始まらないとき、受信の常駐プロセスはその投稿を発話してはならない（MUST NOT）。

#### Scenario: 手で書いた投稿
- **WHEN** チャンネルに、識別行の無い1行だけの投稿がある
- **THEN** 発話は起きない

### Requirement: 古い通知の破棄
投稿の時刻が現在より180秒を超えて古いとき、受信の常駐プロセスはその投稿を発話してはならない（MUST NOT）。

#### Scenario: 休止からの復帰
- **WHEN** 端末が3時間休止し、その間に通知が20通投稿された
- **THEN** 復帰の後、その20通はどれも発話されない

### Requirement: 発話する文
受け付けた投稿について、受信の常駐プロセスは、1行目から先頭の絵文字と空白を除いた文を発話しなければならない（MUST）。
文が200文字を超えるとき、200文字までを発話する。識別行は発話しない。

#### Scenario: 完了の通知
- **WHEN** 1行目が、種類 `done` の絵文字、空白、`uskn-harnessの作業が完了しました` の順に並ぶ通知を受け付ける
- **THEN** 発話される文は `uskn-harnessの作業が完了しました`

### Requirement: VOICEVOX での発話
VOICEVOXが `VOICEVOX_URL`（既定は `http://localhost:50021`）で応答する間、発話のコマンドはVOICEVOXが合成した音声を再生しなければならない（MUST）。
話者は `VOICEVOX_SPEAKER`（既定は8）で選ぶ。

#### Scenario: VOICEVOX が動いている
- **WHEN** VOICEVOXが応答する端末で通知を受け付ける
- **THEN** VOICEVOXの音声が1回再生され、OSの音声は使われない

### Requirement: VOICEVOX が応答しないときの発話
VOICEVOXが応答しないとき、発話のコマンドはOSの音声で読まなければならない（MUST）。
macOSでは `say`、WindowsではSAPI5を使う。

#### Scenario: VOICEVOX を入れていない Windows
- **WHEN** VOICEVOXの無いWindowsの端末で通知を受け付ける
- **THEN** SAPI5の音声で文が読まれる

### Requirement: 発話を重ねない
発話の途中で次の通知を受け付けたとき、受信の常駐プロセスは、前の発話が終わってから次の発話を始めなければならない（MUST）。

#### Scenario: 続けて届く通知
- **WHEN** 1秒の間隔で通知が2通届く
- **THEN** 2つの文は重ならず、届いた順に発話される

### Requirement: 同じ投稿を二度発話しない
受信の常駐プロセスは、一度発話した投稿を、再起動の後も再び発話してはならない（MUST NOT）。

#### Scenario: 再起動
- **WHEN** 通知を発話した10秒後に、受信の常駐プロセスを再起動する
- **THEN** その通知はもう一度発話されない

### Requirement: 受信の設定が無いとき
受信Botのトークンかチャンネルが空のとき、`claude-notify-telegram-bot run` は、設定が無いことを1行で出力し、終了コード0で終わらなければならない（MUST）。

#### Scenario: 設定の無い端末
- **WHEN** `CLAUDE_TELEGRAM_RECV_TOKEN` が空の端末で `run` を実行する
- **THEN** Telegramへの通信は起きず、1行の出力の後に終了コード0で終わる

### Requirement: 接続の失敗からの回復
Bot APIに届かない間、受信の常駐プロセスは終了せず、5秒から60秒まで間隔を広げながら接続をやり直さなければならない（MUST）。

#### Scenario: 回線の復旧
- **WHEN** ネットワークが10分切れてから戻る
- **THEN** 受信の常駐プロセスは動き続けており、戻ってから60秒以内に受信を再開する

### Requirement: 同じ受信 Bot の二重の受信
Bot APIが、同じ受信Botを別のプロセスが使っていると応答したとき、受信の常駐プロセスは警告をログに残し、終了せずに接続をやり直さなければならない（MUST）。

#### Scenario: 2 台で同じトークン
- **WHEN** 2台の端末が同じ `CLAUDE_TELEGRAM_RECV_TOKEN` で `run` を実行する
- **THEN** どちらのプロセスも終了せず、ログに受信Botの重複を知らせる警告が残る

### Requirement: 常駐の導入
`claude-notify-telegram-bot install` は、受信の常駐プロセスを、ユーザーのログインのたびに起動するよう登録し、その場で起動しなければならない（MUST）。
macOSではLaunchAgent `com.claude.notify-telegram-bot` として登録する。
Windowsでは、ログイン時に窓を出さずに起動する。

#### Scenario: macOS
- **WHEN** macOSで `claude-notify-telegram-bot install` を実行する
- **THEN** `~/Library/LaunchAgents/com.claude.notify-telegram-bot.plist` ができ、受信の常駐プロセスが動いている

#### Scenario: Windows の再起動
- **WHEN** Windowsで `install` を実行し、端末を再起動してログインする
- **THEN** 窓は現れず、受信の常駐プロセスが動いている

### Requirement: 常駐の取り外し
`claude-notify-telegram-bot uninstall` は、受信の常駐プロセスを止め、ログイン時の登録を消さなければならない（MUST）。

#### Scenario: macOS
- **WHEN** 導入済みのmacOSで `uninstall` を実行する
- **THEN** plistは消え、受信の常駐プロセスは動いていない

### Requirement: 取り外しで他のプロセスを止めない
`claude-notify-telegram-bot uninstall` は、受信の常駐プロセスのほかのプロセスを止めてはならない（MUST NOT）。

#### Scenario: 別の Python のプロセス
- **WHEN** Windowsで別のPythonのプロセスが窓を出さずに動いている状態で `uninstall` を実行する
- **THEN** 別のプロセスは動き続ける

### Requirement: 対応しない OS
LinuxかWSLで実行されたとき、`claude-notify-telegram-bot install` は何も登録せず、終了コード1で終わらなければならない（MUST）。
出力で、対応しないOSであることを知らせる。

#### Scenario: WSL
- **WHEN** WSLの中で `claude-notify-telegram-bot install` を実行する
- **THEN** 何も登録されず、Windows側で実行するよう案内する出力がある
