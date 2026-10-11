# Tasks

## 1. 前提と実機検証

- [ ] 1.1 `openspec list --specs` に `notify-plugin` と `loop-run` が出ることを確かめる。出なければ、`migrate-ai-config-to-harness` と `add-loop-run` のarchiveを待つ。`openspec validate notify-via-telegram --strict` がarchiveの拒否を知らせないことも確かめる
- [ ] 1.2 BotFatherで、ユーザーが送信Botを1つ、受信Botを発話する端末の数だけ作る。非公開のチャンネルを作り、すべてのBotを管理者に加える。それぞれのトークンで `getMe` が成功することをcurlで確かめる
- [ ] 1.3 curlで送信Botから2行のメッセージを `parse_mode` なしで投稿する。チャンネルに現れることを確かめ、応答からチャンネルのIDを控える
- [ ] 1.4 `getUpdates` を受信Botで呼び、1.3の投稿が `channel_post` として読めることを確かめる。読めなければ、チャンネルにグループを連携させ、自動転送された投稿を読む。どちらも読めなければ、実装を止めてユーザーに相談する
- [ ] 1.5 design.mdのMigration Planに、検証の結果（届いた形と、応答の要点）を追記する。textlintが通ることを確かめる

## 2. ADR

- [ ] 2.1 `docs/adr/0008-notify-via-telegram.md` を書く。通知をTelegramに一本化した理由、design.mdのD1の捨てた案、送信と発話を別のコマンドにした理由を書く。ADR-0006の通知の節に、ADR-0008で置き換えた旨の注記を足す。textlintとterms-checkが通ることを確かめる

## 3. 送信（telegram-notify-send）

- [ ] 3.1 `bin/tests/notify-send.bats` を先に書く。curlの差し替えで引数と標準入力を記録し、`telegram-notify-send` の各シナリオを1つずつ確かめる。書式と種類、未設定と失敗と打ち切り、猶予と取り消しを確かめる。トークンが引数に無いこと、環境変数の優先、`CLAUDE_NOTIFY_OFF` も確かめる。jqを隠した場合と、`python3` を隠して `py` だけを置いた場合も確かめる。走らせて失敗することを確かめる
- [ ] 3.2 `plugins/uskn-notify/bin/claude-notify` を、design.mdのD3、D5、D6のとおりに書き直す。発話、端末間の転送、端末のベルのコードを消す。3.1の送信のテストが通ることを確かめる
- [ ] 3.3 `plugins/uskn-notify/bin/claude-notify-hook` を、D4とD7のとおりに書き直す。`claude-notify-nag` を消す。3.1がすべて通り、`make verify-shell` が通ることを確かめる
- [ ] 3.4 `.gitattributes` を足し、`plugins/uskn-notify/bin/` のファイルの改行をLFに固定する。`git check-attr eol plugins/uskn-notify/bin/claude-notify-hook` が `lf` を返すことを確かめる

## 4. 発話と受信（telegram-voice-receiver）

- [ ] 4.1 `bin/tests/notify-receiver.bats` を先に書く。Bot APIの代わりをするHTTPサーバーも `bin/tests/fixtures/` へ置く。`run --once` で `telegram-voice-receiver` の各シナリオを確かめる。受け付ける投稿は2つの形で確かめる。受け付けない投稿は、別のチャンネル、人の書き込み、識別行の無い投稿、古い通知で確かめる。発話する文、発話の順、再起動の後も確かめる。設定の無い端末と409の応答も確かめる。走らせて失敗することを確かめる
- [ ] 4.2 `plugins/uskn-notify/bin/claude-notify-speak` を作り、今の `claude-notify` のVOICEVOXと `say` の処理を移す。`claude-notify.ps1` を `git mv` で発話のPowerShell版の名前に変える。batsで、curl、`afplay`、`say` を差し替え、VOICEVOXが応答するときと応答しないときを確かめる
- [ ] 4.3 `plugins/uskn-notify/bin/claude-notify-telegram-bot` に `run` と `run --once` を、design.mdのD8のとおりに書く。4.1が通ることを確かめる
- [ ] 4.4 batsを先に足す。`CLAUDE_NOTIFY_OS` と `launchctl` の差し替えを使う。macOSでは、`install` がplistを書くことと、`uninstall` が消すことを確かめる。Linuxでは、`install` が終了コード1で終わることを確かめる。Windowsについては、ログイン時のスクリプトの中身とPIDのファイルの扱いを確かめる。走らせて失敗することを確かめてから実装し、通ることを確かめる
- [ ] 4.5 `claude-notify-daemon` と `claude-notify-ntfy-sub` を消す。dotfilesの `install-voicevox-engine.ps1` を `plugins/uskn-notify/bin/` へ写し、出所のコミットをコミットメッセージに書く。`ls plugins/uskn-notify/bin` が仕様の7つだけを出すことを確かめる

## 5. プラグイン、sync、doctor（notify-plugin、harness-doctor）

- [ ] 5.1 `bin/tests/notify-plugin.bats` を先に直す。コマンドの一覧を新しい7つにする。古いLaunchAgentの片付け、消えたコマンドのsymlinkの片付け、入れ直しの対象、`--dry-run` を確かめるテストを足す。doctorの送信先の検査、受信の設定の検査、トークンを出力しないことも足す。走らせて失敗することを確かめる
- [ ] 5.2 `bin/uskn-harness` のsyncを、design.mdのD9のとおりに変える。5.1のsyncのテストが通り、2回目のsyncが `ok` だけを出すことを確かめる
- [ ] 5.3 `bin/uskn-harness` のdoctorに、送信先の検査と受信の設定の検査を足す。5.1のdoctorのテストが通ることを確かめる
- [ ] 5.4 `plugins/uskn-notify/.claude-plugin/plugin.json` の説明を直す。`Makefile` の `FAST_BATS` を直し、`plugins/uskn-notify/bin/` が変わったときに通知の3つのテストを選ぶようにする。14行目のコメントも直す。`make verify-plugin` と `bin/tests/makefile.bats` が通ることを確かめる
- [ ] 5.5 `openspec/specs/notify-plugin/spec.md` のPurposeを書き直す。Telegramへの送信と、受信を起点にした発話を配るプラグインと書く。`openspec validate --specs --strict` が通ることを確かめる
- [ ] 5.6 `plugins/uskn-notify/README.md` を英語で書き直す。Botとチャンネルの準備、`config.env` の4つのキー、受信の常駐プロセスの導入、Windowsでの使い方、Telegramに残る情報、動かないときの調べ方を書く。`README.md` の機能の表、`docs/setup-new-machine.md`、`bin/uskn-harness` の冒頭の説明も直す。textlintとterms-checkが通ることを確かめる

## 6. ループ（loop-run）

- [ ] 6.1 `bin/tests/uskn-loop.bats` にテストを先に足す。`claude` の差し替えが環境変数を記録し、`CLAUDE_NOTIFY_OFF=1` が渡ることを確かめる。完了と停止で `claude-notify` の差し替えが `--kind loop` で1回呼ばれること、終了コード2では呼ばれないことを確かめる。`claude-notify` が無いときに終了コードが変わらないことも確かめる。走らせて失敗することを確かめる
- [ ] 6.2 `loop/lib/run.sh` を、design.mdのD10のとおりに変える。`bin/uskn-loop` の冒頭の説明に通知を足す。6.1が通ることを確かめる

## 7. ハーネスの統合

- [ ] 7.1 `openspec validate notify-via-telegram --strict` と `make verify VERIFY_STRICT=1` が通ることを確かめる
- [ ] 7.2 `~/.config/claude-notify/config.env` を今の端末に作り、送信の2つのキーを書く。作業ツリーの `claude-notify "試験です"` を実行し、チャンネルに届くことを確かめる。`uskn-harness sync --dry-run` が、消えたコマンドのsymlinkを消す予定を出力することを確かめる
- [ ] 7.3 PRをmainへマージする

## 8. dotfiles（7.3の後に、dotfilesのmasterへ直接コミットする）

- [ ] 8.1 `/allow-repo` で、ユーザーがdotfilesの編集を許可する。`dot_local/bin/` の通知のスクリプトと `dot_config/claude-notify/` を消し、`.chezmoiignore` の該当の行を消す。Windowsの `~/.local/bin` に残る古い通知のスクリプトを `.chezmoiremove` に足す。`chezmoi managed` にそれらが出ないことを確かめる
- [ ] 8.2 Windowsだけで有効な `.chezmoiexternal.toml` を、design.mdのD11のとおりに足す。Linuxで `chezmoi execute-template` の結果が空であることを確かめる。Windowsで `chezmoi apply --dry-run` が `~/.local/share/uskn-harness` の取得を出力することを確かめる
- [ ] 8.3 `dot_claude/settings.json.tmpl` のWindowsのhookのパスを、checkoutの `claude-notify-hook` に変える。OSをWindowsとして描画した結果の3つのhookが、そのパスを指すことを確かめる
- [ ] 8.4 `setup.ps1` の `-Voicevox` の呼び先をcheckoutへ変え、`-TelegramBot` を足す。Windowsで `setup.ps1 -TelegramBot` が受信の常駐プロセスを登録することを確かめる
- [ ] 8.5 dotfilesの `README.md`、`CLAUDE.md`、windows-voicevox.mdの通知の節を、ハーネスの文書への案内に書き直す。Markdownのリンク切れが無いことを確かめる
- [ ] 8.6 dotfilesのmasterへコミットしてpushする

## 9. 移行の確認

- [ ] 9.1 macOSの端末で `config.env` を書き、`uskn-harness sync` を実行する。出力に古いLaunchAgentの `removed` があり、`launchctl list` に古い2つが無いことを確かめる。`claude-notify-telegram-bot install` の後、別の端末でturnを終え、macOSの端末が発話することを確かめる
- [ ] 9.2 Windowsの端末で、古い `claude-notify-daemon uninstall` を先に実行する。続けて `chezmoi apply` と `setup.ps1 -TelegramBot` を実行する。Git BashのClaude Codeでturnを終え、チャンネルに届き、Windowsが発話することを確かめる。VOICEVOXを止めた状態では、SAPI5で読むことを確かめる
- [ ] 9.3 WSLのClaude Codeでturnを終え、チャンネルに1通届くことを確かめる。確認依頼を出したまま10分待ち、2通目が届かないことを確かめる
- [ ] 9.4 10分のあいだ発話する端末を休止させ、その間に別の端末でturnを終える。復帰の後に、その通知が発話されないことを確かめる
- [ ] 9.5 `uskn-loop run` を1件実行する。ラウンドごとの通知が届かず、終わりに1通だけ届くことを確かめる
