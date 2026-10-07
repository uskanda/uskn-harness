## Context

動機はproposal.mdのWhyにある。

- dotfilesは `dot_claude/settings.json.tmpl` から、すべてのOSへ `~/.claude/settings.json` を丸ごと描画している。読み上げ通知のhookは、その中から `~/.local/bin/claude-notify-hook` を呼ぶ
- Claude Codeは、`/model` の値を `model` に書く。`/effort` の値は `modelSettings.<model>.effortLevel` に書く（`max` だけは保存しない）。どちらも公式文書のsettingsとcommandsの節にある
- syncは今、symlinkと管理印付きのコピーだけを扱い、JSONのマージは持たない。jqはsyncの手順2がmiseで入れ、hookも前提にしている
- Windowsネイティブの `C:\Users\<user>\.claude` も日々使われている。このため段階的に移す（grilling第1ラウンドQ2）
- `claude-notify-ntfy-sub` は、自身と `claude-notify` の場所を `$HOME/.local/bin` に固定して書いている。LaunchAgentのplistも同じパスを焼き込む

## Goals / Non-Goals

**Goals:**

- `chezmoi apply` のたびに、liveの設定がマージの結果へ収束する。何も変わっていなければsyncは書き込まない
- 既存の端末は、`chezmoi update` だけで移る。手作業は、端末固有の値を端末別設定へ書くことに限る

**Non-Goals:**

- ハーネスが持つキーを端末で変えた値の保護。設定断片のキーは毎回ハーネスの値で上書きする。端末で残したい値は端末別設定に書く
- プロジェクト層とlocal層の設定。syncが触るのはユーザー層の `~/.claude/settings.json` だけである
- Windowsネイティブ。dotfilesの凍結した写しを、後のchangeで移すか廃止する

## Decisions

### マージは jq で行う

合成 `D` は、設定断片に端末別設定をマージして求める。liveを `L`、適用記録を `R` とすると、新しいliveは次の順で作る。

1. `R` にあって `D` に無いパスを `L` から消す。オブジェクトは再帰し、集合として扱う配列は要素ごとに比べ、それ以外の値は1つのパスとして扱う。値は比べない
2. `D` を `L` へマージする。オブジェクトは再帰し、集合として扱う配列は和集合を取り、それ以外は `D` の値で置き換える
3. `modelSettings` の各モデルから `effortLevel` を消し、空になったオブジェクトを消す
4. 結果が `L` と同じなら書かない。違えば同じディレクトリの一時ファイルに書いてから `mv` で置き換え、`R` に `D` を書く

集合として扱う配列は、`permissions` の `allow`、`deny`、`ask`、`additionalDirectories` の4つに限る。
python3で実装する案も考えた。jqはsyncが自分で入れる道具であり、hookと同じ依存に収まるので、jqを採る。
値を比べずにパスで消す理由は、片付けの規則を1つにするためである。ハーネスが入れたキーを端末が変えていても、同じ規則が当てはまる。

### 置き場

| もの | パス |
|---|---|
| 設定断片 | `templates/user/settings.json` |
| 初回用の写し | `templates/user/settings-seed.json` |
| 端末別設定 | `~/.config/uskn-harness/settings.json` |
| 適用記録 | `${USKN_STATE_DIR:-${XDG_STATE_HOME:-~/.local/state}/uskn-harness}/settings-applied.json` |

適用記録は状態ディレクトリと同じ親の下で `sessions/` の外に置くので、古いセッションの状態の削除に巻き込まれない。
初回用の写しは、dotfilesの最後の `dot_claude/settings.json.tmpl` をLinux向けに描画したものである。
片付けはパスで判定するので、写しの中のhookのパスが端末の `$HOME` と違っても結果は変わらない。
片付けの対象を個別に列挙する案（grilling第3ラウンドQ14のB）は、片付けの仕組みが2つになるので採らない。

### 設定断片の中身

dotfilesのテンプレートから、`hooks`、`modelSettings`、`extraKnownMarketplaces` を除いた残りを入れる。
`env.IMPECCABLE_NO_STALENESS_CHECK` は `"1"` で足す。
top-levelのキーは次のとおり。

- 値を持つもの：`effortLevel`（`xhigh`）、`model`（`opus[1m]`）、`cleanupPeriodDays`、`theme`、`tui`
- 真偽値のもの：`agentPushNotifEnabled`、`inputNeededNotifEnabled`、`includeCoAuthoredBy`、`remoteControlAtStartup`
- オブジェクトのもの：`env`、`permissions`

`permissions` は `defaultMode`（`auto`）、`additionalDirectories`（`/tmp`）、`allow` を持つ。

`allow` の仕分けは次のとおり（grilling第3ラウンドQ13）。

| 行き先 | 要素 |
|---|---|
| 設定断片 | `Bash(git *)`、`Bash(gh auth *)`、`Bash(gh repo *)`、glabの6つ（`auth`、`variable`、`api`、`ci`、`issue`、`repo`）、`Bash(ls -la)`、`Bash(bash -n *)`、`Bash(bash --version)`、`Bash(claude --version)`、`WebSearch`、`Bash(apt-cache *)`、`Bash(grep -iE *)`、`Bash(command -v *)`、`Bash(chezmoi --version)`、`Bash(chezmoi source-path *)`、openspecの9つ、`Bash(systemctl is-enabled *)`、`Bash(systemctl is-active *)`、`Bash(lscpu)`、`Read(//etc/**)`、`Read(//usr/lib/**)`、`Read(//tmp/**)`、`Read(//sys/devices/system/cpu/**)` |
| 端末別設定の候補 | `Bash(crontab -l)`、`Bash(sudo ls -la /var/spool/cron/crontabs/)`、`Read(//var/spool/cron/crontabs/**)`、`Bash(lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,UUID)`、`Bash(mount)`、`Bash(pvs)`、`Bash(vgs)`、`Bash(sudo pvs)`、`Bash(sudo vgs)`、`Bash(sudo lvs)`、`Read(//home/vscode/.claude/**)` |
| dotfilesのプロジェクト層 | `PowerShell(git *)` と、`PowerShell(chezmoi …)` の3つ |
| 捨てる | pyinfraとvenvの10個、`Bash(cat MEMORY.md)`、`Bash(exit 1)`、`Bash(apt-get download *)`、`Bash(dpkg -L fonts-noto-cjk)`、`Bash(dpkg-deb -c *)`、`Bash(fc-list*)`、`Bash(snap list *)`、`Skill` の許可の8つ、mypyとruffのgrep、`/workspace` のfind、`/proc/1/cgroup` の1行、`Read(//usr/share/fonts/**)`、`Read(//proc/1/**)` |

端末別設定の候補は、どの端末で要るかをハーネスは知らない。移行のときに、ユーザーが要る端末の端末別設定へ書く。
端末ごとの `model` の上書き（dotfilesの `[data.claude] model`）も端末別設定に書く。

### 通知のプラグイン

`plugins/uskn-notify/` は次の構成にする。

- `.claude-plugin/plugin.json`: name `uskn-notify`
- `hooks/hooks.json`: 3つのイベントから `claude-notify-hook` を呼ぶ。コマンドは `"${CLAUDE_PLUGIN_ROOT}"/bin/claude-notify-hook <kind>` の形
- `bin/`: dotfilesの7つのコマンドを、振る舞いを変えずに移す。出所のコミットはコミットメッセージに書く

syncは各コマンドを `~/.local/bin/<name>` へsymlinkする。
置き場を `~/.local/bin` にする理由は次の3つである。

- `claude-notify-ntfy-sub` とplistが `$HOME/.local/bin` を前提にしている
- ユーザーがシェルから `claude-notify-daemon install` などを実行できる
- WSLの `claude-notify` が、隣の `claude-notify.ps1` を見つけられる

各コマンドは、起動に使われたパスの親ディレクトリから隣のコマンドを探す（`BIN_DIR`）。hookからはプラグインの `bin/`、シェルからは `~/.local/bin` が親になり、どちらでも隣が見つかる。

skills-dirプラグインの `bin/` は、Bashツールの `PATH` にも載る（ADR-0005）。通知のコマンドがエージェントから見えるが、ユーザーがシェルで使うコマンドと同じなので害は無い。

### LaunchAgent の入れ直し

macOSでだけ、syncは `com.claude.notify-daemon` と `com.claude.notify-ntfy-sub` のplistを見る。
plistがあり、対応するコマンドのsha256が記録と違えば、`~/.local/bin/<cmd> install` を実行して記録を更新する。
記録は状態ディレクトリと同じ親の下の `notify-installed/<label>.sha256` に置く。
`~/.local/bin` 経由で呼ぶのは、`claude-notify-daemon` がplistに自分の起動パスを書くためである。ハーネスのcheckoutのパスを焼き込まない。
sha256はmacOSの `shasum -a 256` で求める。

### sync の手順の順序

既存の手順5（プラグイン）を `plugins/*` のループにし、その直後に通知のコマンドのsymlinkを置く。
ユーザー層の設定は、手順8（ユーザー層CLAUDE.md）の前に置く。LaunchAgentの入れ直しは最後に置く。
同じsyncの中で、通知のhookはプラグインから入り、settings.jsonの古いhookは消える。

### make verify

- `SCRIPT_DIRS` に `plugins/uskn-notify/bin` を足す。shellcheckに渡すファイルは、実行権限ではなくshebangで選ぶ（bashかshのものだけ）
- `claude plugin validate --strict` を `plugins/*` のループにする
- batsに、設定断片がJSONとして読めることと、`hooks` と `modelSettings` を持たないことの検査を足す
- `sync` と `doctor` のbatsは、既存の `USKN_HARNESS_STUB_NET` と一時的な `HOME` を使う。確かめるのは、マージ、3方向の片付け、effortの消去、初回の写し、読めないJSON、`--dry-run`、`--remove` である

### スキル

cleanupとset-workspace-themeは英訳して `skills/cleanup/` と `skills/set-workspace-theme/` に置く。
set-workspace-themeの説明文は今436文字なので、`skill-invocation` の200文字以内に縮める。
cleanupは、dotfilesで説明文が4時間、本文が2時間と食い違っていた。実際に動いていた本文の2時間に揃える。

### bootstrap

bootstrapの正本を `run_after_` のスクリプトに置き換える。
新しい正本は `templates/chezmoi/run_after_uskn-harness.sh.tmpl` に置く。
古い `templates/chezmoi/run_once_install-uskn-harness.sh.tmpl` は消す。
中身は今と同じく、参照点を用意してから `exec "$H/bin/uskn-harness" sync` を実行する。
`run_after_` にするのは、dotfilesの片付けのスクリプト（`run_onchange_before_`）とファイルの適用の後に、syncがsymlinkを置けるようにするためである。

### dotfiles 側

- `dot_claude/skills/` の4つを外す。chezmoi-mergeとsync-claude-settingsは、リポジトリ直下の `.claude/skills/` に移す。chezmoiはリポジトリの中で名前が `.` で始まるパスを配らないので、`$HOME` には出ない
- `.claude/settings.json`（プロジェクト層）を新しく置き、`PowerShell(git *)` と `PowerShell(chezmoi …)` の3つを持たせる
- Windowsだけに配るものは4つ。`dot_claude/settings.json.tmpl`、通知のコマンド、`dot_config/claude-notify/`、set-workspace-themeのWindows用のコピー
- `.chezmoiignore` は、Windows以外で `.claude/` を丸ごと除外する。通知のコマンドの名前と `.config/claude-notify/` も、Windows以外で除外する
- 片付けのスクリプトに、4つのスキルの名前と通知のコマンドの名前を足す。消すのは実ディレクトリと実ファイルだけで、symlinkは残す
- `.chezmoiremove` は使わない。applyのたびに消すので、syncが同じパスに置くsymlinkまで消える
- run_onceを消し、ハーネスの `run_after_` の写しを置く
- `setup` から `INSTALL_VOICEVOX` と `INSTALL_NOTIFY_DAEMON` の節を消し、ハーネスの文書を案内する
- `README.md` と `CLAUDE.md` の該当節を、ハーネスへの案内とWindowsの凍結の説明に置き換える
- `openspec/changes/add-telegram-notify-transport/` を消す

## Risks / Trade-offs

- WindowsとUnixで設定の中身が別々に変わる → dotfilesの写しは凍結し、変えるのはハーネスの設定断片だけにする。READMEに凍結を明記する
- 設定断片からキーを消すと、端末が変えた値も消える → 残したい値は端末別設定に書くよう、文書に明記する
- 端末別設定を書いていない端末では、端末固有のallowが初回のsyncで消える → 移行の前に `uskn-harness sync --dry-run` で消える要素を確かめる。消えたallowは、許可を求められたときに足し直せる
- `.chezmoiignore` の名前が漏れると、chezmoiがsyncのsymlinkを実ファイルで上書きする → doctorの通知のコマンドの検査が `warn` を出す。Linuxで `chezmoi diff` が空になることをtasksで確かめる
- dotfilesを先にコミットすると、hookが消えたスクリプトを指す → ハーネスのPRのマージを、dotfilesのコミットの前提にする
- applyのたびにsyncが走り、2秒ほどとハーネスのfetchが足される → 受け入れる。オフラインではfetchを飛ばして導入を続ける
- 動いているClaude Codeのセッションは、settings.jsonの書き換えを読み直す → 中身が変わるときだけ書き、一時ファイルからの `mv` で途中の状態を見せない

## Migration Plan

1. ハーネスのPRを実装し、`make verify` を通してmainへマージする
2. このWSL端末で `uskn-harness sync --dry-run` を実行し、消える要素を確かめる。要るものは端末別設定に書く
3. dotfilesの変更をmasterへコミットし、`chezmoi apply` を実行する。片付けのスクリプト、ファイルの適用、`run_after_` のsyncの順に走る
4. `uskn-harness doctor` が `warn` を出さないことと、通知が1回だけ鳴ることを確かめる
5. ほかの端末は `chezmoi update` で移る。macOSでは、syncがLaunchAgentを入れ直したことを出力で確かめる

戻すときは、dotfilesのコミットをrevertして `chezmoi apply` する。`run_after_` が無くなり、chezmoiが再びsettings.jsonを描画する。
ハーネスのsymlinkと設定は、`uskn-harness sync --remove` で外せる。

## Open Questions

- 初回用の写し `templates/user/settings-seed.json` を消す時期。すべての端末に適用記録ができた後なら消せるが、端末の数と移行の進み具合はハーネスから分からない
