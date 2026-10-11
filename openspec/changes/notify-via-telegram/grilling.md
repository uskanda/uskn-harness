# grilling 記録: notify-via-telegram

Claude Codeの確認依頼とturnの終わりを知らせる通知を、Telegramへの送信と、Telegramの受信を起点にした発話の2つに分ける。
送信はClaude Codeが動くすべての端末で行い、発話は受信の常駐プロセスを入れた手元の端末だけで行う。
grillingの前に、ハーネスの `plugins/uskn-notify/` とdotfilesの `add-telegram-notify-transport` を読んだ。
未archiveの2つの変更の状態も調べた。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 変更の順序 | 計画は今書く。実装は `migrate-ai-config-to-harness` のdotfiles側のtasksを済ませてarchiveした後にする | 第1ラウンド Q1 |
| 発話の起点 | 受信Botを常駐させ、Bot APIの長ポーリングで読む。送信Botが非公開チャンネルへ投稿し、受信Botはチャンネルの投稿を読む。発話する端末ごとに受信Botを1つ作る。Telegramのアプリには依存しない | 第1ラウンド Q2 |
| 今ある発話の方法 | Telegramに一本化する。`claude-notify` は送信だけにする。直接の発話、`claude-notify-daemon`、`claude-notify-ntfy-sub`、WSLからWindows側を呼ぶ発話は削除する | 第1ラウンド Q3 |
| 送るイベント | 完了と確認依頼の両方を送る。確認依頼は3秒の猶予つきで1通だけ送り、10分ごとの再催促はやめる | 第1ラウンド Q4 |
| Windowsネイティブへの配り方 | ハーネスのsync全体のWindowsネイティブ対応は別の変更のままにする。dotfilesがWindowsでだけ、ハーネスのcheckoutにある `plugins/uskn-notify/bin/` を指す。dotfiles側の変更は今回のtasksに含める | 第1ラウンド Q5 |
| Telegramが未設定の端末 | 何も送らず、端末のベルも鳴らさず、終了コード0で終える。doctorが `warn` を出す。送信に失敗したときも無音で終了コード0にする | 第2ラウンド Q6 |
| メッセージの書式 | 1行目を発話される文、2行目を識別行にする。識別行は `#claude_notify` に続けて種類、ホスト名、リポジトリ名、セッションIDの先頭8文字を持つ。プロンプトやツールの出力は送らない | 第2ラウンド Q7 |
| 携帯端末の通知音 | 完了も確認依頼も音ありで送る。静かにしたいときはTelegramのアプリでチャンネルを消音にする | 第2ラウンド Q8 |
| 受信側が発話する範囲 | 絞り込みは持たない。受信の常駐プロセスを入れた端末は、どのセッションの通知でも発話する。180秒より古い通知だけ捨てる | 第2ラウンド Q9 |
| `uskn-loop` のセッション | 実装役と監査役のturnの終わりは送らない。`uskn-loop` が環境変数 `CLAUDE_NOTIFY_OFF=1` を渡し、hookはそれを見て何もしない。ループが完了したときと停止したときに、`uskn-loop` が1通送る | 第2ラウンド Q10 |
| WindowsでのClaude Codeの動かし方 | ネイティブとWSLの両方を使っている。両方で送信できるようにする | 第2ラウンド Q11（ユーザーの回答「両方使っている」） |
| 受信の常駐プロセスの導入 | 新しいコマンド `claude-notify-telegram-bot` に `run`、`install`、`uninstall` を持たせ、ユーザーが発話させたい端末で `install` を実行する。syncは新しく入れず、既に入っているものだけ入れ直す | 第2ラウンド Q12 |
| 古い常駐プロセスの片付け | macOSに `com.claude.notify-daemon` と `com.claude.notify-ntfy-sub` のLaunchAgentが残る端末では、syncがunloadしてplistを消し、`removed` と報告する | 第2ラウンド Q12 |
| VOICEVOXが応答しないとき | 今と同じく、macOSは `say`、WindowsはSAPI5で読む | 第2ラウンド Q12 |
| 秘密の置き場とキー | 管理外の `~/.config/claude-notify/config.env` に置く。キーは `CLAUDE_TELEGRAM_BOT_TOKEN`、`CLAUDE_TELEGRAM_CHAT_ID`、`CLAUDE_TELEGRAM_RECV_TOKEN`、`CLAUDE_TELEGRAM_TIMEOUT` の4つ。環境変数がファイルの値より優先される。古いキーは読まない。送信は同期で行い、5秒で打ち切る | 第2ラウンド Q13 |
| Windowsへのcheckoutの置き方 | dotfilesにWindowsだけで有効な `.chezmoiexternal.toml` を足し、`git-repo` として `~/.local/share/uskn-harness` へ取得する。`chezmoi apply` が週1回の間隔で更新する。Windowsのsettings.jsonのhookは、そのcheckoutの `claude-notify-hook` を指す | 第3ラウンド Q14 |
| dotfilesに残るWindows用の通知スクリプト | `install-voicevox-engine.ps1` もプラグインへ移し、dotfilesから通知のスクリプトと `dot_config/claude-notify/` をすべて消す。dotfilesに残るのは、Windowsのsettings.jsonのhookの配線と、`setup.ps1` の引数だけ | 第3ラウンド Q15 |
| ループの部分の扱い | 1つの変更にまとめる。実装の前提を、`migrate-ai-config-to-harness` と `add-loop-run` の両方がarchive済みであることにする | 第3ラウンド Q16 |
| 実機検証と失敗時 | 最初のtaskで、実装の前にcurlだけで確かめる。順は、チャンネルの投稿を受信Botが直接読む、次にチャンネルと連携させたグループへの自動転送を読む。両方とも読めなければ実装を止めてユーザーに相談する。BotとチャンネルはClaude Codeの通知専用に新しく作る | 第3ラウンド Q17 |
| コマンドの構成と名前 | `claude-notify-hook`、`claude-notify`、`claude-notify-telegram-bot`、`claude-notify-speak` とそのPowerShell版、`install-voicevox-engine` とそのPowerShell版にする。`claude-notify-nag`、`claude-notify-daemon`、`claude-notify-ntfy-sub` は削除する。今の `claude-notify.ps1` は発話のPowerShell版に改名する | 第3ラウンド Q18 |
| 変更の名前、ADR、試験の方法 | 変更の名前は `notify-via-telegram`。ADR-0008に一本化の理由と捨てた案を書く。送信はbashとcurlで書き、batsではcurlを差し替える。受信の常駐プロセスはPython 3に付属するモジュールだけで書き、Bot APIのURLを差し替えてbatsから確かめる | 第3ラウンドの末尾に挙げ、ユーザーが承認した |
| dotfilesのTelegramの変更 | `add-telegram-notify-transport` の削除は、`migrate-ai-config-to-harness` のtask 8.6のままにする | 第3ラウンドの末尾に挙げ、ユーザーが承認した |

## 後回しにしたもの

- ハーネスのsync全体のWindowsネイティブ対応。今回はuskn-notifyだけをdotfiles経由でWindowsへ配る
- 受信側の絞り込み。特定のホストの通知だけを読む設定は、必要と分かってから足す
- Telethonによる受信。実機検証でBot APIの2つの方法がどちらも使えないときに、改めて決める
- Linuxの端末での発話

## 状態

frontierは空。共有理解は2026-10-11に確認済み。
