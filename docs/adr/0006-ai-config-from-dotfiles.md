# ADR-0006: Claude Code とAI関連の設定の正本をハーネスに移す

- 状態：採用（2026-10-05）。ADR-0001の「dotfilesに残す4つのスキル」と、ADR-0002の決定2の「settings.jsonは触らない」を置き換える
- 決定者：uskanda（変更migrate-ai-config-to-harnessのgrilling、第1〜4ラウンド）

## 文脈

ADR-0001とADR-0002は、Claude Codeのユーザー層を2つに分けた。
スキルとhookはハーネスが配り、`~/.claude/settings.json` と読み上げ通知はdotfilesが配る。
settings.jsonはchezmoiのテンプレートで丸ごと描画していた。

この分担では、Claude Codeが端末で書いた値がdotfilesのテンプレートに取り込まれる。取り込んだ値は、ほかの端末の値と衝突する。
`/effort` は `modelSettings` に値を書くので、ある端末で一時的に変えたeffortが全端末へ広がった。
`permissions.allow` の端末間の和集合は、dotfilesのスキルを使って手で集めていた。
dotfilesの `.chezmoiignore` は、Windows以外へ `dot_local/bin/claude-notify.ps1` を配らない。このため、新しいWSL端末では読み上げ通知が鳴らなかった。

## 決定

1. ユーザー層のsettings.jsonは、ハーネスの設定断片と端末別設定からsyncが作る。設定断片は `templates/user/settings.json`、端末別設定は `~/.config/uskn-harness/settings.json` に置く
2. syncは丸ごと置かず、マージする。設定断片のキーは毎回上書きし、設定断片に無いキーは残す。消すのは適用記録にあって合成に無いものだけにする
3. syncはliveの値をどこにも書き戻さない。`modelSettings` のeffortは毎回消し、effortの既定値は設定断片のtop-levelの `effortLevel` だけにする
4. 読み上げ通知は、2つ目のskills-dirプラグイン `plugins/uskn-notify/` で配る。hookは設定ファイルではなくプラグインの `hooks/hooks.json` に書く。秘密を持つ `~/.config/claude-notify/config.env` はユーザーが管理する
5. cleanupとset-workspace-themeは、英訳してハーネスのスキルにする。chezmoi-mergeとsync-claude-settingsは、dotfilesのプロジェクト層 `.claude/skills/` に移す。この2つはdotfilesのリポジトリでしか使わないためである
6. dotfilesは、`chezmoi apply` のたびに導入とsyncを行う `run_after_` のスクリプトだけを持つ
7. Windowsネイティブは今回移さない。dotfilesのWindows用の設定と通知は凍結し、ハーネスのWindows対応は別のchangeで決める
8. ローカルLLMのスクリプト、opencodeの設定、Fusion MCPはdotfilesに残す。端末の構成であり、エージェントの作法ではないためである

## 結果

- 良い点：端末で変えた値が共有の設定へ入らなくなり、effortとallowの衝突が無くなる。設定の変更は、ハーネスの1か所で済む
- 良い点：新しいWSL端末でも、syncが `claude-notify.ps1` を `claude-notify` の隣に置くので読み上げが鳴る
- 引き受けるコスト：設定断片のキーを端末で変えても、次の `chezmoi apply` で戻る。端末で残したい値は端末別設定に書く
- 引き受けるコスト：Windowsネイティブの設定は、Windows対応のchangeまでdotfilesとハーネスの2か所にある。dotfiles側は凍結して変えない
- 引き受けるコスト：`chezmoi apply` のたびにsyncが走り、2秒ほどとハーネスのfetchが足される
