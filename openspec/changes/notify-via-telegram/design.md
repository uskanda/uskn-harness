# Design

## Context

動機はproposal.mdのWhyを見ること。ここには、方式を決めるのに要る現状と制約だけを書く。

今の `plugins/uskn-notify/` の流れは次のとおり。

```
hook(JSON) → claude-notify-hook → claude-notify-nag（3秒の猶予、10分ごとの再催促）
                                → claude-notify
                                     ├ macOS            VOICEVOX → say
                                     ├ Git Bash、WSL    PowerShell → claude-notify.ps1 → VOICEVOX → SAPI5
                                     └ SSH、devcontainer claude-notify-daemon(:50090) → ntfy → 端末のベル
```

制約は次のとおり。

- TelegramのBotは、グループでは他のBotの投稿を受け取れない。チャンネルの投稿を管理者のBotが受け取れるかは、実機で確かめていない
- 同じトークンで同時に長ポーリングできるプロセスは1つだけである
- hookとbatsは、macOSの `/bin/bash` 3.2とBSDの道具でも動かす（AGENTS.md）
- WindowsネイティブのClaude Codeは、hookをGit Bashで実行する。Git Bashにはcurlがあり、`python3` という名前のコマンドは無いことが多い
- ハーネスのsyncはWindowsネイティブで動かない。Windowsにはsymlinkも `~/.local/bin` への公開も無い
- `notify-plugin` と `loop-run` の仕様は、未archiveの2つの変更の中にある。このchangeのdeltaは、その2つがarchiveされた後の仕様に対して書いた

## Goals / Non-Goals

**Goals:**

- 送信と発話を、チャンネルだけでつながる2つの部品にする。どちらも相手のコマンドを呼ばない
- 送信の部品は、bashとcurlだけでLinux、macOS、WSL、Git Bashを同じコードで扱う
- 実機検証でどちらの形が届いても、仕様とコードを変えない
- 受信Botのトークンを、発話する端末の外に置かない

**Non-Goals:**

- 発話の品質を変えること。VOICEVOXの呼び方と話者の既定値は今のまま移す
- PowerShellのスクリプトの自動の検査。CIはLinuxとmacOSだけで動くため、Windowsでの確認は手で行う
- Telegramの投稿を消すことや、まとめること

## Decisions

### D1: 送信Botがチャンネルへ投稿し、受信Botがチャンネルの投稿を読む

```
Claude Codeが動く端末（Linux、macOS、WSL、Git Bash）
  hook → claude-notify-hook → claude-notify ──sendMessage──▶ チャンネル ──▶ 携帯端末のTelegram
                                                              │
                                                    getUpdates（長ポーリング）
                                                              ▼
発話する端末（macOS、Windows）       claude-notify-telegram-bot → claude-notify-speak → VOICEVOX
```

受信の常駐プロセスは、2つの形の投稿を受け付ける。

- 種類が `channel_post` で、投稿先がチャンネルのもの
- 種類が `message` で、`is_automatic_forward` が真、送り元の `sender_chat` がチャンネルのもの

1つ目は、受信Botがチャンネルの管理者のとき届く。
2つ目は、チャンネルと連携させたグループへ受信Botを入れたとき届く。
両方を実装しておくと、実機検証の結果で変わるのはREADMEの準備の手順だけになる。
どちらも届かなかったときは、実装を止めてユーザーに相談する。

捨てた案は次のとおり。

| 捨てた案 | 理由 |
|---|---|
| その場の発話とTelegramを設定で選ぶ | 発話の方法の組み合わせとフォールバックが残り、端末ごとの設定が減らない |
| Telethonによる受信 | ユーザーのTelegramの全権を持つセッションを端末に置くことになる |
| Telegramのアプリが出すOSの通知を読む | macOSには、他のアプリの通知を読む公開のAPIが無い |
| 1つのBotで送受信する | Botは自分の投稿を受け取れない |

### D2: コマンドの役割と呼び出しの関係

| コマンド | 言語 | 呼ぶもの | 呼ばれる場所 |
|---|---|---|---|
| `claude-notify-hook` | bash | `claude-notify` | hook |
| `claude-notify` | bash | curl | `claude-notify-hook`、`uskn-loop`、手 |
| `claude-notify-telegram-bot` | Python 3 | 発話のコマンド | LaunchAgent、Windowsのログイン時の登録 |
| `claude-notify-speak` | bash | VOICEVOX、`afplay`、`say` | `claude-notify-telegram-bot`（macOS） |
| 発話のPowerShell版 | PowerShell | VOICEVOX、SAPI5 | `claude-notify-telegram-bot`（Windows） |

`claude-notify-speak` は、今の `claude-notify` の `voicevox_speak` と `say` へのフォールバックをそのまま移す。
発話のPowerShell版は、今の `claude-notify.ps1` を改名するだけで、中身は変えない。
どのコマンドも、隣のコマンドを自分のファイルの場所から探す。今の `BIN_DIR` の方法を保つ。

### D3: `claude-notify` の引数

```
claude-notify [--kind <種類>] [--repo <名前>] [--sid <ID>] [--emoji <絵文字>] <文>
```

- `--kind` の既定は `manual`。絵文字は種類から決め、`--emoji` で上書きできる。`uskn-loop` は停止のときだけ上書きする
- `--repo` が無いときは、現在のディレクトリのgitのtoplevelの名前を使う
- ホスト名は `hostname` の出力の最初の `.` より前を使う

dotfilesの設計は環境変数で渡していた。引数にしたのは、`uskn-loop` と手からの実行で同じ入口を使うためである。

### D4: hookの入力はjqで読み、無ければPythonで読む

`claude-notify-hook` が読むのは `session_id`、`cwd`、`notification_type` の3つ。
jqがあればjqを使う。無ければ、今の `py` 関数（`python3`、`python`、`py -3` の順）を使う。
どちらも無いときは、`cwd` を現在のディレクトリ、セッションIDを `-` として送る。`notification_type` は空として扱い、確認依頼として送る。
両方を持つ理由は2つある。Git Bashの多くはjqを持たない。Linuxのコンテナにはpythonを入れていないものがある。

### D5: 送信はcurlの設定を標準入力から渡す

`claude-notify` は `curl --config -` を使い、URL（トークンを含む）と `--data-urlencode` の2つの値を標準入力から渡す。
こうすると、トークンは `ps` で見える引数に現れない。
`parse_mode` は付けない。`--max-time` に `CLAUDE_TELEGRAM_TIMEOUT` を渡す。
APIのURLの先頭は `CLAUDE_TELEGRAM_API_BASE` で差し替えられ、既定は `https://api.telegram.org` である。これは試験のための入口で、READMEには載せない。
送信は同期で行う。失敗の理由を、今ある `~/.claude/notify-hook-debug.on` のログに残せる。

### D6: `config.env` の読み方

送信の側は、今と同じく `. config.env` で読む。環境変数を優先するため、4つのキーについて、読む前の値を覚えておき、読んだ後に戻す。
受信の常駐プロセスは、`KEY="value"` の行を自分で解析し、環境変数に無いキーだけを採る。
doctorは、キーの行をgrepで調べるだけで、ファイルを実行しない。値は出力しない。
Windowsネイティブでは、Git Bashの `$HOME` もPythonのホームも `%USERPROFILE%` である。
そのため、bashのコマンドとPythonのコマンドは同じ `config.env` を読む。

### D7: 確認依頼の猶予は `claude-notify-hook` が持つ

`claude-notify-hook notification` は、切り離した子プロセスで3秒待ってから `claude-notify --kind confirm` を呼ぶ。
子プロセスのPIDを、セッションごとのファイル `${TMPDIR:-/tmp}/claude-notify-confirm-<sid>.pid` に書く。
`stop` と `done` は、そのPIDのプロセスを止めてファイルを消す。
待つ秒数は `CLAUDE_NOTIFY_GRACE` で変えられる。batsは短い値を使う。
子プロセスの標準入出力はすべて閉じる。閉じないと、Claude Codeがhookの終了を3秒待つ。
`claude-notify-nag` はこの仕組みのほかに再催促のループを持っていた。再催促をやめるので、ファイルごと削除する。

### D8: 受信の常駐プロセスの作り

- Python 3に付属するモジュールだけで書く、1つのファイル
- `getUpdates` は `timeout=50`、`allowed_updates` は `channel_post` と `message`
- 次に読む位置を `~/.local/state/claude-notify/telegram-offset` に書く。再起動の後の二重の発話を防ぐ
- 受け付けた文をキューに入れ、発話のコマンドを1つずつ順に呼ぶ
- HTTPの409は、同じ受信Botの重複としてログに警告を残し、60秒待つ
- `run --once` は、`getUpdates` を1回呼び、届いた分を発話して終わる。batsと手での確認に使う
- 試験のための入口は3つ。`CLAUDE_TELEGRAM_API_BASE`、発話のコマンドを差し替える `CLAUDE_NOTIFY_SPEAK_CMD`、OSの判定を差し替える `CLAUDE_NOTIFY_OS`

導入の形は次のとおり。

- macOS: plistは `~/.local/bin/claude-notify-telegram-bot run` を指す。`KeepAlive` は異常終了のときだけ再起動する設定にする。設定が無くて終了コード0で終わったプロセスを、launchdが起動し直さないためである。ログは `~/Library/Logs/claude-notify-telegram-bot.log`
- Windows: ログイン時に実行されるユーザーのフォルダーに、`pythonw` で `run` を起動する短いスクリプトを置く。スクリプトは、`install` を実行したファイルの場所（checkout）を指す。PIDを `~/.local/state/claude-notify/telegram-bot.pid` に書き、`uninstall` はそのPIDだけを止める

今の `claude-notify-daemon uninstall` は、`pythonw.exe` のプロセスをすべて止める。同じ方法は採らない。

### D9: syncの変更

- 入れ直すLaunchAgentの一覧 `NOTIFY_AGENTS` を、`com.claude.notify-telegram-bot` の1組にする
- 古いLaunchAgentの一覧を別に持つ。plistがあれば `launchctl unload` を実行し、plistとハッシュの記録を消す
- `~/.local/bin` のsymlinkのうち、宛先が `$HARNESS/plugins/uskn-notify/bin/` の下で、宛先のファイルが無いものを消す
- 片付けは、コマンドの公開より前に実行する。`--dry-run` では、消す予定だけを出力する
- `--remove` の手順は変えない

### D10: `uskn-loop` の変更

- `loop/lib/run.sh` の2つの `claude -p` の前に `CLAUDE_NOTIFY_OFF=1` を置く
- `finish_done` と `finish_stop` の最後で、ハーネスの `plugins/uskn-notify/bin/claude-notify` を `--kind loop` で呼ぶ。実行できないときと失敗したときは、何もせずに続ける

### D11: Windowsネイティブへの配り方

- dotfilesに、Windowsだけで有効な `.chezmoiexternal.toml` を置く。`type = "git-repo"`、取得先は `~/.local/share/uskn-harness`、`refreshPeriod = "168h"`
- `dot_claude/settings.json.tmpl` のWindowsのhookのパスを、checkoutの `claude-notify-hook` に変える
- `setup.ps1` の `-Voicevox` は、checkoutの `install-voicevox-engine.ps1` を呼ぶ。新しい `-TelegramBot` は、checkoutの `claude-notify-telegram-bot install` を呼ぶ
- ハーネスに `.gitattributes` を足し、`plugins/uskn-notify/bin/` のファイルの改行をLFに固定する。Windowsのgitが改行をCRLFに変えると、bashのスクリプトが動かない

### D12: 試験

- `bin/tests/notify-send.bats`: `PATH` の先頭にcurlの差し替えを置き、引数と標準入力を記録する。`CLAUDE_NOTIFY_GRACE` を短くして、猶予と取り消しを確かめる
- `bin/tests/notify-receiver.bats`: `bin/tests/fixtures/` にPythonの小さなHTTPサーバーを置く。そのURLを `CLAUDE_TELEGRAM_API_BASE` に渡して `run --once` を実行する。発話は `CLAUDE_NOTIFY_SPEAK_CMD` で記録する
- `bin/tests/notify-plugin.bats`、`bin/tests/uskn-harness.bats`、`bin/tests/uskn-loop.bats`: 既存の試験を新しい構成に合わせる
- `Makefile` の `FAST_BATS` に、`plugins/uskn-notify/bin/` の変更から3つの通知の試験への対応を足す
- Windowsでの確認と、実際の発話は、tasksの手での確認にする

## Risks / Trade-offs

- チャンネルの投稿を受信Botが受け取れない → 最初のtaskで確かめる。グループへの自動転送の形も実装してある。両方とも届かなければ止めて相談する
- 手元の端末の作業でも、発話にはTelegramへの通信が要る。発話は1秒から2秒遅れる → 受け入れる。grillingのQ3とQ9で決めた
- ハーネスのPRをマージしてから `config.env` を書くまで、その端末は無音になる → doctorが `warn` を出す。移行の手順で、syncの前に `config.env` を書く
- 回線が悪いと、Stopのhookが最長で5秒かかる → `CLAUDE_TELEGRAM_TIMEOUT` で短くできる
- Telegramのサーバーに、リポジトリ名、ホスト名、作業した時刻が残る → READMEに書く。チャンネルは非公開にする
- 送信Botのトークンを、SSHの先やコンテナにも置く → 漏れたときにできるのは、チャンネルへの投稿だけである。受信Botのトークンは発話する端末だけに置く
- CIは、PowerShellのスクリプトとWindowsの導入を検査できない → Windowsの端末を使い、手で確かめるtaskを置く
- Windowsのcheckoutは週1回しか更新されない。送信側と受信側で版がずれる → 両者の契約はメッセージの書式だけである。受信側は識別行の先頭だけを見るので、識別行にキーが増えても動く
- 古いLaunchAgentを消した後に前の版へ戻すと、常駐が無い → 戻すときは `claude-notify-daemon install` を手で実行する

## Migration Plan

1. `migrate-ai-config-to-harness` と `add-loop-run` をarchiveする
2. ユーザーがBotFatherで送信Botと受信Botを作り、非公開のチャンネルを作る。curlだけで投稿と受信を確かめ、結果をこの文書に追記する
3. ハーネスの実装をPRにし、mainへマージする
4. 各端末で `~/.config/claude-notify/config.env` に送信の2つのキーを書き、`uskn-harness sync` を実行する。syncが古いLaunchAgentと消えたコマンドのsymlinkを片付ける
5. 発話させるmacOSの端末で、受信Botのトークンを書き、`claude-notify-telegram-bot install` を実行する
6. Windowsでは、先に古い `claude-notify-daemon uninstall` を実行する。その後にdotfilesの変更をコミットし、`chezmoi apply` と `setup.ps1 -TelegramBot` を実行する

戻すときは、ハーネスのコミットをrevertしてsyncを実行する。dotfilesのコミットもrevertする。古い常駐は手で入れ直す。
