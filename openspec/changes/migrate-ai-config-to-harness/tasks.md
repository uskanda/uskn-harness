# Tasks

## 1. ADR

- [x] 1.1 `docs/adr/0006-ai-config-from-dotfiles.md` を書く。ADR-0001の「4つのスキルはdotfilesに残す」と、ADR-0002の「settings.jsonは触らない」を置き換える理由と、Windowsネイティブを後のchangeへ送る判断を書く。ADR-0001とADR-0002の該当箇所に、ADR-0006で置き換えた旨の注記を足す。textlintとterms-checkが通ることを確かめる

## 2. ユーザー層の設定（user-settings）

- [x] 2.1 batsを先に書く。設定断片がJSONのオブジェクトとして読めることと、`hooks` と `modelSettings` を持たないことを確かめる。走らせて失敗することを確かめる
- [x] 2.2 syncのbatsを先に書く。一時的な `HOME` と `USKN_HARNESS_STUB_NET` で、specの各シナリオを1つずつ確かめる。対象はマージ、集合として扱う配列、3方向の片付け、適用記録、初回の写し、effortの消去、端末別設定、読めないJSON、`--dry-run`、`--tools`、`--remove`。走らせて失敗することを確かめる
- [x] 2.3 `templates/user/settings.json` をdesignの「設定断片の中身」のとおりに作る。`templates/user/settings-seed.json` に、dotfilesの `dot_claude/settings.json.tmpl` をLinux向けに描画した写しを置く。2.1が通ることを確かめる
- [x] 2.4 `bin/uskn-harness` のsyncに、ユーザー層の設定の手順をjqで足す。手順の位置はdesignの「syncの手順の順序」のとおり。2.2が通り、2回目のsyncが `ok` だけを出すことを確かめる
- [x] 2.5 doctorにユーザー層の設定の検査を足し、鮮度警告の案内をsyncへ向け直す。batsで、sync直後の `ok` と、liveに `modelSettings` があるときの `warn` を確かめる
- [x] 2.6 `bin/uskn-harness` の冒頭の手順の説明、`README.md` の機能の表、`docs/setup-new-machine.md` を更新する。端末別設定の置き場と書き方、移行の前の `sync --dry-run` を案内する。textlintとterms-checkが通ることを確かめる

## 3. プラグインの一般化（harness-sync、claude-plugin-packaging）

- [x] 3.1 batsを先に書く。確かめるのは3つ。syncが `plugins/` の下のプラグインをすべてsymlinkすること。`uskn-notify` という名前のスキルで終了コード2になること。`--remove` で全プラグインのsymlinkが消えること。走らせて失敗することを確かめる
- [x] 3.2 sync、doctor、`--remove` のプラグインの扱いを `plugins/*` のループにし、予約名をプラグインの名前全体にする。`Makefile` の `claude plugin validate --strict` もループにする。3.1と `make verify-plugin` が通ることを確かめる

## 4. 通知のプラグイン（notify-plugin）

- [x] 4.1 `plugins/uskn-notify/` を作る。`.claude-plugin/plugin.json`、`hooks/hooks.json`、`bin/` の7つのコマンドを置く。コマンドはdotfilesの `dot_local/bin/` から振る舞いを変えずに写し、出所のコミットをコミットメッセージに書く。`claude plugin validate --strict plugins/uskn-notify` が通ることを確かめる
- [x] 4.2 `Makefile` の `SCRIPT_DIRS` に `plugins/uskn-notify/bin` を足し、shellcheckに渡すファイルをshebangで選ぶ。写したbashのスクリプトのshellcheckの指摘を、振る舞いを変えずに直す。`make verify-shell` が通り、`claude-notify-daemon` が対象に入らないことを確かめる
- [x] 4.3 batsを先に書く。通知のコマンドの `~/.local/bin` へのsymlinkと、実ファイルがあるときの `conflict` を確かめる。`~/.config/claude-notify/config.env` に触れないことと、`--remove` も確かめる。macOSのLaunchAgentの入れ直しは、OSの判定とplistの置き場を差し替えて、記録が無いとき、ハッシュが同じとき、Linuxのときを確かめる。走らせて失敗することを確かめる
- [x] 4.4 syncに、通知のコマンドのsymlinkとLaunchAgentの入れ直しを足す。4.3が通ることを確かめる
- [x] 4.5 doctorに通知のコマンドの検査を足す。batsで、symlinkの `ok` と実ファイルの `warn` を確かめる
- [x] 4.6 `plugins/uskn-notify/README.md` を英語で書く。opt-inのコマンド、`~/.config/claude-notify/config.env` のキー、Windowsネイティブはdotfilesに残ることを書く。`README.md` の機能の表と `docs/setup-new-machine.md` にも、通知の導入と確認方法を足す。textlintとterms-checkが通ることを確かめる

## 5. スキル（utility-skills）

- [x] 5.1 `skills/cleanup/SKILL.md` を英語で書く。止める対象を起動から2時間より長いプロセスに揃え、`disable-model-invocation: true` を保つ。`make verify-skills` が通ることを確かめる
- [x] 5.2 `skills/set-workspace-theme/SKILL.md` を英語で書き、`scripts/vscode-workspace-env.py` を写す。説明文を200文字以内に縮める。`bin/tests/skill-invocation.bats` と `make verify-skills` が通り、補助スクリプトがこの端末でJSONを返すことを確かめる
- [x] 5.3 `README.md` の機能の表に2つのスキルを足す。textlintとterms-checkが通ることを確かめる

## 6. bootstrap（machine-bootstrap）

- [x] 6.1 batsを先に書く。テンプレートからchezmoiの指示の行を除いた本体に `bash -n` をかけ、`uskn-harness" sync` を実行する行と `CHEZMOI_DEST_DIR` の扱いがあることを確かめる。走らせて失敗することを確かめる
- [x] 6.2 `templates/chezmoi/run_after_uskn-harness.sh.tmpl` を作る。古いrun_onceのテンプレートは消す。6.1が通ることを確かめる
- [x] 6.3 `README.md` の導入の節と `docs/setup-new-machine.md` の「仕組み」「更新」を、applyのたびにsyncが走る形に書き直す。textlintとterms-checkが通ることを確かめる

## 7. ハーネスの統合

- [x] 7.1 `openspec validate migrate-ai-config-to-harness --strict` と `make verify VERIFY_STRICT=1` が通ることを確かめる
- [x] 7.2 WSLのこの端末で、作業ツリーのsyncを `--dry-run` で実行する。liveから `hooks`、`modelSettings`、捨てるallowを消す予定が出力され、liveは変わらないことを確かめる
- [ ] 7.3 PRをmainへマージする

## 8. dotfiles（7.3の後に、dotfilesのmasterへ直接コミットする）

- [ ] 8.1 chezmoi-mergeとsync-claude-settingsを、`dot_claude/skills/` からリポジトリ直下の `.claude/skills/` へ `git mv` する。chezmoi-mergeから、Unixのsettings.jsonの突合の手順を外す。`.claude/settings.json` を作り、`PowerShell(git *)` と `PowerShell(chezmoi …)` の3つを持たせる。`chezmoi managed` に `.claude/skills/chezmoi-merge` が出ないことを確かめる
- [ ] 8.2 `dot_claude/skills/cleanup/` を消す。`.chezmoiignore` を、Windows以外で `.claude/`、通知のコマンドの名前、`.config/claude-notify/` を除外する形にする。Linuxで `chezmoi managed` にそれらが出ないことを確かめる
- [ ] 8.3 `run_onchange_before_remove-migrated-claude-skills.sh.tmpl` に、4つのスキルの名前と通知のコマンドの名前を足す。一時的な `CHEZMOI_DEST_DIR` に実ファイルとsymlinkを置いて走らせ、実ファイルだけが消えることを確かめる
- [ ] 8.4 dotfilesのrun_onceのスクリプトを消し、ハーネスの `templates/chezmoi/run_after_uskn-harness.sh.tmpl` を写す。`chezmoi execute-template` の結果に `bash -n` が通ることを確かめる
- [ ] 8.5 `setup` から `INSTALL_VOICEVOX` と `INSTALL_NOTIFY_DAEMON` の節を消し、ハーネスの文書を案内する。`bash -n setup` が通ることを確かめる
- [ ] 8.6 `openspec/changes/add-telegram-notify-transport/` を消す
- [ ] 8.7 dotfilesの文書を、ハーネスへの案内とWindowsの凍結の説明に書き直す。対象は、`README.md` のClaude Codeの設定の節と発話の3節、`CLAUDE.md` の該当節、windows-voicevox.md、chezmoi-mergeの起動スクリプトのコメント。Markdownのリンク切れが無いことを確かめる
- [ ] 8.8 dotfilesのmasterへコミットしてpushする

## 9. 移行の確認

- [ ] 9.1 WSLのこの端末で、要る端末別設定を書いてから `chezmoi apply` を実行する。`uskn-harness doctor` が `warn` を出さず、liveに `hooks` と `modelSettings` が無く、turnの終わりに通知が1回だけ鳴ることを確かめる
- [ ] 9.2 `chezmoi apply` をもう一度実行し、syncが `ok` だけを出してliveを書き換えないことを確かめる
- [ ] 9.3 `/effort` を変えてから `chezmoi apply` を実行し、liveの `modelSettings` からeffortが消え、ハーネスのcheckoutが変わらないことを確かめる
- [ ] 9.4 macOS端末で `chezmoi update` を実行し、LaunchAgentがある場合はsyncが入れ直して `updated` と報告することを確かめる
