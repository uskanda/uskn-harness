# Proposal

## Why

`plugins/uskn-notify/` の通知では、Claude Codeを動かす端末自身が発話する。
SSHの先やdevcontainerでは、手元の端末で動く受信のプロセスへ届ける設定が端末ごとに要る。
設定の無い端末では、turnが終わっても何も聞こえない。
この変更は通知を2つの処理に分ける。Telegramへの送信と、Telegramの受信を起点にした発話である。
こうすると、Claude Codeがどの端末で動いていても、同じチャンネルに通知が集まり、手元の端末が発話する。

## What Changes

- `claude-notify` はTelegramへ1通送るだけのコマンドになり、発話しない（**BREAKING**）。送信Botがチャンネルへ投稿する。Linux、macOS、WSL、WindowsネイティブのGit Bashで動く
- 通知のメッセージは2行にする。1行目は発話される文、2行目は識別行。プロンプトやツールの出力は送らない
- 送るのは、turnの終わりと確認依頼の2つ。確認依頼は3秒の猶予の後に1通だけ送る。10分ごとの再催促は無くなる（**BREAKING**）
- 新しいコマンド `claude-notify-telegram-bot` が受信の常駐プロセスになる。受信Botとしてチャンネルの投稿を読み、識別行のあるメッセージだけを発話する。macOSとWindowsで動く
- 発話は新しいコマンド `claude-notify-speak` とそのPowerShell版が受け持つ。VOICEVOXが応答しないときは、macOSは `say`、WindowsはSAPI5で読む
- `claude-notify-nag`、`claude-notify-daemon`、`claude-notify-ntfy-sub` を削除する（**BREAKING**）。その場での発話、端末間の転送、ntfyは無くなる
- 送信先が未設定の端末と、送信に失敗したときは、何も鳴らさずに終了コード0で終える。doctorが未設定を `warn` で報告する
- syncは、macOSに残る古いLaunchAgentを外し、プラグインから消えたコマンドを指すsymlinkを消す。入れ直すLaunchAgentは受信の常駐プロセスの1つになる
- `uskn-loop run` は、実装役と監査役のセッションの通知を止め、ループが完了したときと停止したときに1通送る
- `install-voicevox-engine.ps1` をdotfilesからプラグインへ移す。Windowsネイティブは、dotfilesが取得するハーネスのcheckoutからコマンドを直接実行する
- ADR-0008を書き、通知をTelegramに一本化した理由と捨てた案を残す
- dotfiles側の変更は、このchangeのtasksとしてdotfilesのmasterへ直接コミットする。通知のスクリプトと `dot_config/claude-notify/` を消し、Windowsのhookの配線をcheckoutへ向ける

対象外は次のとおり。ハーネスのsync全体のWindowsネイティブ対応、受信側での通知の絞り込み、Linuxの端末での発話、Telegramのメッセージに返信してClaude Codeへ指示する機能。

実装の前提は、`migrate-ai-config-to-harness` と `add-loop-run` の両方がarchive済みであること。
この2つが、今回書き換える `notify-plugin` と `loop-run` の仕様を `openspec/specs/` に置く。

## Capabilities

### New Capabilities

- `telegram-notify-send`: 通知をTelegramへ送る側の規則。送るイベント、メッセージの書式、送信先の設定、未設定と失敗の扱い、通知を止める環境変数
- `telegram-voice-receiver`: 受信の常駐プロセスの規則。受け付ける投稿の条件、発話、古い通知の破棄、導入と取り外し

### Modified Capabilities

- `notify-plugin`: プラグインのコマンドの構成を入れ替える。秘密のファイルが無いときの振る舞い、opt-inで入れるもの、syncが入れ直すLaunchAgentを新しい構成に合わせる。古いLaunchAgentと消えたコマンドのsymlinkの片付け、checkoutからの直接の実行を足す
- `harness-doctor`: 検査項目に通知の送信先の設定を足す
- `loop-run`: 実装役と監査役のセッションの通知を止める。ループの終わりに通知を1通送る

## Impact

ハーネスで変わるものは次のとおり。

- `plugins/uskn-notify/bin/` のコマンド
- `plugins/uskn-notify/README.md` と、`plugins/uskn-notify/.claude-plugin/plugin.json` の説明
- `bin/uskn-harness` のsyncとdoctor、`bin/uskn-loop` と `loop/lib/run.sh`
- `bin/tests/` のbats
- `docs/adr/`、`docs/setup-new-machine.md`、`README.md`、用語集、`openspec/known-names.txt`
- archiveの後の `openspec/specs/notify-plugin/spec.md` のPurpose

dotfilesで変わるものは次のとおり。

- `dot_local/bin/` の通知のスクリプトと `dot_config/claude-notify/` を削除する
- Windowsだけで有効な `.chezmoiexternal.toml` を足す
- `dot_claude/settings.json.tmpl` のWindowsのhookのパス、`setup.ps1` の引数、`.chezmoiignore`、文書

外部への依存として、Telegram Bot APIへのHTTPSの到達が要る。
通知のたびに、リポジトリ名、ホスト名、セッションIDの先頭8文字がTelegramのサーバーに残る。

端末の利用者が手で行う準備は次のとおり。BotFatherで送信Botと受信Botを作る。非公開のチャンネルを作り、Botを管理者に加える。各端末の `~/.config/claude-notify/config.env` にトークンを書く。
