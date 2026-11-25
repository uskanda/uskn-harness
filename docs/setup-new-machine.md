# 新しい端末へのハーネス導入

macOS、Ubuntu、WSL2（Ubuntu）の端末にuskn-harnessを入れる手順。
導入の実体は、dotfilesの `chezmoi apply` のたびに走るbootstrapのスクリプトと、その中の `uskn-harness sync` にある。
ここでは順番と、OSごとに違う点と、確認方法をまとめる。

## 仕組み

1. dotfiles（`uskanda/dotfiles`）をchezmoiで適用するたびに、bootstrapのスクリプトがファイルの適用の後に走る。正本は `templates/chezmoi/run_after_uskn-harness.sh.tmpl`
2. スクリプトは、miseと `~/.local/share/uskn-harness` が無ければ用意する。miseは `~/.local/bin/mise` に入れる。開発用のcheckoutがあればsymlink、無ければGitHubからcloneする。開発用のcheckoutの既定の置き場は `~/repos/uskn-harness` で、変え方は「開発用のcheckoutの置き場」の節にある
3. 最後に `uskn-harness sync` が走り、6つを揃える。miseのNodeとjq、ピンしたCLI、スキルとプラグインのsymlink、OpenSpec schema、ユーザー層CLAUDE.md、ユーザー層のsettings.json。
   あわせて、ハーネスから削除したスキルのsymlinkと、30日より長く更新されていないセッションの状態を消す
4. 2回目以降の `chezmoi apply` でも、スクリプトはsyncまで走る。syncは冪等で、手で置いたものは `conflict` として触らない

bootstrapのスクリプトはWindowsでは何もしない（spec `machine-bootstrap`）。WindowsはWSL2の中でLinuxの手順を踏む。

## 事前に要るもの（全 OS 共通）

- git
- GitHubの認証。`uskanda/uskn-harness` と `uskanda/dotfiles` はpublicで、cloneに認証は要らない。
  `pr` や `fix-ci` などのスキルが `gh` を使うので、`gh auth login` と `gh auth setup-git` は済ませておく
- ネットワーク。mise、Node、npm globalのCLI、サードパーティスキルをダウンロードする
- Claude Code本体（デスクトップアプリかCLI）。ハーネスはClaude Codeを入れない。導入とloginは公式手順に従う

## 手順

### Ubuntu / WSL2（Ubuntu）

```bash
sudo apt install -y git curl
gh auth login && gh auth setup-git      # gh が無ければ先に apt で入れる
git clone https://github.com/uskanda/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./setup                # apt update、chezmoi、chezmoi init --apply、zsh
```

`./setup` の中の `chezmoi apply` がbootstrapのスクリプトを走らせる。終わったら新しいシェルを開く。
zshrcが `mise activate zsh --shims` を評価し、`~/.local/share/mise/shims` がPATHに載る。

WSL2では、Windows側ではなくWSLのUbuntuで上を実行する。Claude CodeもWSL側で動かす（CLI、またはVS CodeのWSL拡張）。
dotfilesのWezTerm設定は既定でWSLドメインを開くので、ターミナルはWezTermでよい。

### macOS

```bash
xcode-select --install                  # git を含む Command Line Tools。dotfiles の setup は入れない
gh auth login && gh auth setup-git      # gh が無ければ brew install gh を先に
git clone https://github.com/uskanda/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./setup                # Homebrew、chezmoi、chezmoi init --apply、zsh
```

Brewfileがgit、gh、jqを入れる。miseはbootstrapのスクリプトが `~/.local/bin/mise` に入れる。
hookスクリプトはmacOSのBSD系コマンドに対応している。`date -j`、`shasum`、`realpath -m` が無いときのpython3へのフォールバックを持つ。
`timeout` コマンドはmacOSに無いので、verify gateの検証は時間制限なしで走る。

### Windows（ネイティブ）

推奨しない。WSL2を使う。ネイティブで試す場合の既知の論点を挙げる。

- bootstrapのスクリプトはWindowsで何もしないので、cloneと `bash bin/uskn-harness sync` をGit Bashで手動実行する
- syncとhookはsymlinkを前提にする。Git Bashでは開発者モードを有効にし、`MSYS=winsymlinks:nativestrict` を設定しないとコピーになる
- Windowsの `timeout.exe` はGNUのtimeoutと互換が無い。verify gateとtextlint hookは `timeout` を見つけると使うので、PATHの順序によっては失敗する
- mise for Windowsのshimsの場所は `~/.local/share/mise/shims` と異なる。Makefileとverify gateはこの場所をPATHの先頭に足す
- jqはwingetなどで別途入れる

ネイティブWindowsで動かすなら、まず上の4点を検証し、結果をこの文書に追記する。

## ユーザー層の設定

`sync` は `~/.claude/settings.json` を丸ごと置かず、ハーネスの設定断片をマージする（spec `user-settings`）。

設定断片は `templates/user/` の5つのファイルに分かれる。syncは次の順に重ねた合成を、liveへマージする。

1. 共通の `settings.json`。両方の環境の種類と両方のOSで同じキーを持つ
2. 環境の種類別の `settings-admin.json` か `settings-confined.json`。sandboxを緩めるキーは管理者の環境用にある
3. OS別の設定断片の `settings-linux.json` か `settings-darwin.json`。Linuxだけで意味を持つ許可はLinux用にある。ほかのOSでは重ねない
4. 端末別設定 `~/.config/uskn-harness/settings.json`

配列は集合の和として重ねるので、後のファイルは要素を足せるが、消せない。
合成は `uskn-harness print-settings` で標準出力に出せる。このコマンドは、liveの設定と適用記録を書き換えない。

- 設定断片のキーは、syncのたびにハーネスの値で上書きする。`/model` や `/config` で変えた値も、次のsyncで戻る
- 設定断片に無いキーは残す。Claude Codeが書いたキーや、端末で足した `permissions.allow` の要素がこれに当たる
- `/effort` が `modelSettings` に書いた値は、syncのたびに消す。effortの既定値は、設定断片のtop-levelの `effortLevel` である
- 設定断片から消したキーと要素は、syncが適用記録と比べてliveからも消す。適用記録は `~/.local/state/uskn-harness/settings-applied.json` にある

1台の端末だけで使う値は、端末別設定 `~/.config/uskn-harness/settings.json` に書く。端末別設定はリポジトリに入らない。
書き方は設定断片と同じで、syncは3つの設定断片の後に端末別設定を重ねる。

```json
{
  "model": "sonnet",
  "permissions": { "allow": ["Bash(sudo pvs)"] }
}
```

### dotfiles から移る端末

dotfilesが配っていた `~/.claude/settings.json` がある端末では、初回のsyncが次のものを消す。

- 読み上げ通知のhook。通知はプラグインuskn-notifyが配る
- `modelSettings` と、superpowersのmarketplace
- 設定断片に無い `permissions.allow` の要素。`sudo pvs` やcrontabの参照など、端末固有の要素も含む

消える要素は、先に `uskn-harness sync --dry-run` で確かめる。残したい要素は、端末別設定に書いてから `chezmoi apply` を実行する。

## Bash の sandbox

ユーザー層のsettings.jsonは、Claude Codeのsandboxを有効にする（ADR-0009、ADR-0011、ADR-0012、ADR-0013）。
この節は管理者の環境の設定を説明する。sandboxを緩めるキーは、管理者の環境用の設定断片 `settings-admin.json` にある。
閉じた環境ではこれらのキーを持ち込まない（ADR-0015、「閉じた環境」の節）。

sandboxに残るのは、中身を前もって読めない実行（`npm`、`make`、`python` など）である。
`git`、`gh`、`glab`、`docker`、`mise`、`claude`、`uskn-harness`、`chezmoi`、`ssh`、`scp` は、sandboxの外で動く。
sandboxの中のBashが書けるのは、作業ディレクトリ、一時ディレクトリ、`/add-dir` で追加したディレクトリ、設定断片の挙げるキャッシュとツールのデータだけである。
Unixソケットは許す。D-Busを使う `systemctl --user` や `secret-tool` も、sandboxの中で動く。

- UbuntuとWSL2では、`sudo apt install -y bubblewrap socat` で2つを入れる。無い端末では、Bashが制限なしで動き、doctorが `warn` を出す
- Ubuntu 24.04以降では、AppArmorが `bwrap` のユーザー名前空間を拒否する（`bwrap: setting up uid map: Permission denied`）。次の2つで `bwrap` に許可を与える

```bash
printf 'abi <abi/4.0>,\ninclude <tunables/global>\n\nprofile bwrap /usr/bin/bwrap flags=(unconfined) {\n  userns,\n  include if exists <local/bwrap>\n}\n' | sudo tee /etc/apparmor.d/bwrap
sudo apparmor_parser -r /etc/apparmor.d/bwrap
```

- Ubuntu 26.04以降では、`apparmor` パッケージの `bwrap-userns-restrict` が、同じ名前の `bwrap` のプロファイルを定義する。こちらが上のプロファイルより優先される
- そのため `bwrap` の中で、ユーザー名前空間を入れ子に作れない。sandboxの中のBashは、全て `apply-seccomp: ... nested userns is capability-restricted` で失敗する。上の2つに続けて、次の4つで `bwrap-userns-restrict` を外す（ADR-0013）

```bash
sudo mkdir -p /etc/apparmor.d/disable
sudo ln -s /etc/apparmor.d/bwrap-userns-restrict /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/bwrap-userns-restrict
sudo apparmor_parser -r /etc/apparmor.d/bwrap
```

- 26.04には `/etc/apparmor.d/disable/` が最初から無いので、先に作る。`apparmor_parser` が `disable/` の中を読み飛ばすので、再起動の後も外れたままになる
- 確認は、次のコマンドが終了コード0で終わること。sandboxと同じく、`bwrap` の中でユーザー名前空間を入れ子に作る。`bwrap` 単体の確認は、26.04のsandboxが使えない端末でも終了コード0で終わるので、確認にならない。sandboxの外の `uskn-harness doctor` も、同じ確認をする

```bash
bwrap --ro-bind / / --dev /dev --proc /proc --unshare-user -- unshare --user --map-root-user true
```
- この端末自身のIPに解決されるホスト（同じ端末で動かすGitLabなど）へは、そのままではsandboxの中から接続できない。ユーザーが `/sandbox-allow-host <host>` を打つと、端末別設定の `sandbox.network.allowedDomains` に足され、接続できるようになる。一覧は `uskn-harness sandbox-allow-host --list`、外すのは `--remove <host>` で行う
- macOSでは、何も入れなくてよい
- ルートの外で作業するときは、ユーザーが `/add-dir <path>` を打つ。hookがセッションの許可ファイルにも記録する（ADR-0010）
- sandboxの中で動かない道具を見つけたら、ユーザーが `/sandbox-exclude <tool>` を打つ。その端末の端末別設定 `~/.config/uskn-harness/settings.json` に足され、syncの後も残る。一覧は `uskn-harness sandbox-exclude --list`、外すのは `--remove <pattern>` で行う
- `excludedCommands` は、1つの単純なコマンドだけから成り、先頭がパターンと一致するコマンドだけを、sandboxの外で動かす。`cd <dir> && uskn-harness sync` や `git push | tail` はsandboxの中で動くので、単独で実行する。bash-guardは、sandboxの中で失敗すると分かっている形（`git push` や `git fetch`、`glab`、`docker` など）を拒否し、ほかの形は知らせるだけにする。gitに `-C` や `-c`、`--git-dir` を付けても、sandboxの中で動く。作業ツリーの中では、gitを選択肢なしで実行する。別のディレクトリでは、先に `cd <dir>` だけを実行する
- sandboxのコマンドの実行中は、作業ディレクトリの直下の `.bashrc` や `.claude/agents` などに、0バイトの仮ファイルが置かれる。実行が終わると消える。verify gateの指紋と `verify-fast` は、仮ファイルを数えない。`git status` に出たときは、commitせず、消さない
- 端末でsandboxを切るときは、端末別設定で `sandbox.enabled` を `false` にしてsyncを実行する

## 閉じた環境

環境の種類には、管理者の環境と閉じた環境の2つがある（ADR-0015）。
閉じた環境では、エージェントを動かすOSのユーザーが、ハーネスのcheckoutと道具を書き換えられない。
sandboxの最低線は、端末の土台が `--settings` で固定する。
ここまでの節は管理者の環境の手順で、この節は閉じた環境で違う点をまとめる。

### 環境の印

環境の種類は、checkoutの直下の環境の印 `.uskn-environment` だけで決まる。引数や環境変数では変わらない。
印が無ければ管理者の環境である。印は `key=value` の行から成り、管理者がrootの持ち物の読み取り専用のファイルとして置く。

```text
kind=confined
tools=<共有の置き場の絶対パス>
secrets=<秘密の置き場の絶対パス>
```

- `kind` には `confined` だけを書く。ほかの値の印と読めない印は、閉じた環境として扱われ、doctorが `fail` を出す
- `tools` には、共有の置き場を書く
- `secrets` には、トークンなどを置くディレクトリを書く。hookの規則が、その下の読み書きを禁じる。書かなくてもよい
- `.uskn-environment` は `.gitignore` にあり、リポジトリに入らない

### 導入の順番

1. 管理者が、閉じた環境のOSのユーザーの書けない場所にcheckoutを置き、その直下に印を置く
2. 管理者が `uskn-harness install-shared <tools>` を実行し、共有の置き場を作る
3. 端末の土台が、閉じた環境のOSのユーザーとして `uskn-harness sync --no-pull` を実行する
4. 端末の土台が、`uskn-harness print-settings` の出力を、自分の持ち物の設定として置く
5. 閉じた環境のOSのユーザーとして `uskn-harness doctor` を実行し、終了コードが0になることを確かめる

checkoutの更新は管理者が行う。閉じた環境のsyncは、`--no-pull` が無くてもcheckoutの更新を飛ばす。

### 共有の置き場

共有の置き場は、管理者が `uskn-harness install-shared <dir>` で作る。中身は `deps.json` のピンどおりである。

| パス | 中身 |
|---|---|
| `<dir>/bin/` | node、npm、npx、jq、ピンしたnpmのCLIへのsymlink |
| `<dir>/mise/` | miseの入れたnodeとjq |
| `<dir>/npm/` | ピンしたnpmのCLI |
| `<dir>/skills/<name>/` | サードパーティスキル |
| `<dir>/installed.json` | 入れた版とrefの記録 |

- 版とrefが記録と同じ項目は入れ直さない。`--dry-run` を付けると、予定だけを出す
- 環境の種類を見ず、ユーザー層の設定を書き換えない
- 置き場の持ち主とモードは変えない。閉じた環境のOSのユーザーが読めて書けない状態にするのは、端末の土台の仕事である
- `deps.json` のピンを変えたら、管理者がもう一度実行する。それまでは、閉じた環境のsyncとdoctorが版の違いを `warn` で知らせる

### 閉じた環境のsync

- miseとnpmとskills CLIを実行しない。共有の置き場の記録を `deps.json` と比べて報告する
- サードパーティスキルは、`~/.claude/skills/<name>` から `<tools>/skills/<name>` へのsymlinkにする
- `/opsx:*` は、共有の置き場のopenspecで作る
- 読み上げ通知のプラグインuskn-notify、通知のコマンド、LaunchAgentを入れない。管理者の環境だけのスキル（`cleanup`、`set-workspace-theme`）も入れない。既にあるsymlinkは消す
- ユーザー層の設定には、閉じた環境の合成を使う。端末別設定にあるsandboxを緩めるキーは持ち込まず、外したキーを `warn` で報告する
- `sandbox-exclude` と `sandbox-allow-host` は、`--list` 以外を終了コード2で断る。sandboxの外で動かす道具と接続先は、端末の土台が決める

### hookの規則

閉じた環境のhookは、PATHの先頭に `<tools>/bin` だけを足す。miseのshimsや `~/.local/bin` など、ホームの下の道具は使わない。
hookは、リポジトリのコードを `sandbox-exec` の規則の中で動かす。規則のファイルは `plugins/uskn-harness/hooks/scripts/lib/confined.sb` である。
対象は3種類ある。verify gateの検証規約、textlint-checkのtextlint、hookが実行するgitである。
規則が禁じるのは次の2つで、ほかの操作は閉じた環境のOSのユーザーの権限に任せる。

- 印の `secrets` の下の読み書き
- 外への接続。検証のテスト用のサーバーのため、`localhost` への接続は許す。Unixソケットへの接続は許さない

規則を使えないとき、hookはコマンドを動かさずに知らせる。verify gateは `systemMessage` で、textlint-checkは `additionalContext` で知らせる。
Linuxの閉じた環境は対象外である。`sandbox-exec` はmacOSだけにあるので、Linuxのhookはリポジトリのコードを動かさず、doctorは `fail` を出す。

### gitの範囲

閉じた環境のセッションは、ローカルのcommitまでを行う。pushとPRは外側が行う。

- `push`、`pr`、`release`、`archive-push` は、リモートへ書く前に `uskn-environment` を実行する。出力が `confined` なら、ブランチとcommitを報告して止まる
- bash-guardは、`git push`、`gh pr create`、`glab mr create` を拒否する。`git commit` は拒否しない
- 無人の実行（起動スクリプトを通した `claude -p`）は、ルートの外への書き込みを拒否されると、そこで止まる。拒否は `/add-dir` を前提にしており、ハーネスは別の手段を用意しない
- switchboardは、閉じた環境では動かさない。閉じた環境では、`claude -p --permission-mode auto` の権限モードがdefaultに戻るため

## 読み上げ通知

`sync` はプラグインuskn-notifyを `~/.claude/skills/uskn-notify` に置き、通知のコマンドを `~/.local/bin` にsymlinkする。
Claude Codeが確認を求めたときとturnの終わりに、手元の端末が読み上げる。WSLでは、Windows側の声で読み上げる。

- リモートからの転送の設定は `~/.config/claude-notify/config.env` に書く。syncはこのファイルを作らず、変更しない
- macOSの受信の常駐とVOICEVOX ENGINEは、ユーザーがコマンドで入れる。syncは新しく入れない
- 受信のLaunchAgentを入れた端末では、コマンドが変わるたびにsyncが入れ直す。dotfilesから移る端末もこれで移る

キーとコマンドの一覧は `plugins/uskn-notify/README.md` にある。WindowsネイティブはdotfilesにあるWindows用の写しを使う（ADR-0006）。

## 確認

```bash
uskn-harness doctor                     # 0 problem を確認する。warn は内容を読む
ls -la ~/.claude/skills | head          # ハーネスのスキルが symlink になっている
ls -la ~/.claude/skills/uskn-harness    # plugins/uskn-harness への symlink
claude plugin list                      # uskn-harness@skills-dir と uskn-notify@skills-dir が出る
ls -la ~/.local/bin/claude-notify       # plugins/uskn-notify/bin への symlink
```

続けて任意のgitリポジトリでClaude Codeのセッションを始める。最初の応答の前に `<repo-context>` が注入されていればSessionStart hookが動いている。
Stop hookの確認方法はREADMEの「hookの発火を確かめる」にある。

## 更新

```bash
chezmoi update                          # dotfiles の更新。apply の最後に uskn-harness sync も走る
uskn-harness doctor
```

ハーネスだけを更新するときは、`uskn-harness sync` を直接実行する。

`sync` は最初にcheckoutをfast-forwardする。実行するのはcleanなcheckoutで、branchにupstreamがあり、fast-forwardできるときだけ。
作業中のcheckout（開発機など）ではスキップして理由を出し、導入は続ける。`--no-pull` で止められる。
更新でHEADが動いたときは、新しい `bin/uskn-harness` を同じ引数で実行し直す。

## 開発用のcheckoutの置き場

bootstrapのスクリプトとdoctorは、開発用のcheckoutの置き場を `~/.config/uskn-harness/dev-checkout` の1行目から読む。
1行目には、絶対パスか `~` で始まるパスを書く。ファイルが無いときは `~/repos/uskn-harness` を使う。

```bash
mkdir -p ~/.config/uskn-harness
echo '~/src/uskn-harness' > ~/.config/uskn-harness/dev-checkout
```

参照点がまだ無い端末では、bootstrapのスクリプトが、そのパスに `.git` があれば参照点をそこへのsymlinkにする。
参照点が既にmanaged cloneの端末では、syncもbootstrapのスクリプトも参照点を置き換えない。
doctorが `warn` で手順を示す。次のコマンドを手で実行し、置き換える。

```bash
mv ~/.local/share/uskn-harness ~/.local/share/uskn-harness.old
ln -s <開発用のcheckout> ~/.local/share/uskn-harness
uskn-harness sync
```

`uskn-harness doctor` でその `warn` が消えたことを確かめてから、`~/.local/share/uskn-harness.old` を消す。

## 取り除く

```bash
uskn-harness sync --remove              # ハーネス由来の symlink と管理コピーだけを消す
```

mise、npm globalのCLI、状態ディレクトリは残る。

## journal を使っていた端末

セッションjournalの仕組みは2026-09-25に廃止した（ADR-0004）。
以前から使っていた端末には `~/.ai-sessions` が残る。
ハーネスはこのディレクトリを作らず、検査せず、hookから書き込まない。要らなければ消してよい。

## よくある warn

| doctor の表示 | 意味 | 対処 |
|---|---|---|
| `conflict: ... exists without .uskn-harness-managed` | 同名の実ディレクトリがある。chezmoi が以前配ったスキルのコピーなど | 中身を確認して手で消し、`sync` を再実行 |
| `stale symlink` / `missing` | symlink が古いか無い | `uskn-harness sync` |
| `<cli> (have 'none', want '<ver>')` | npm global の CLI が未導入か版が違う | `uskn-harness sync`。ネットワークを確認 |
| `openspec schema uskn: missing` | schema の symlink が無い | `uskn-harness sync` |
| `openspec commands opsx: missing ...` | `~/.claude/commands/opsx/` が無いか、コマンドが欠けている | `uskn-harness sync`。ネットワークを確認 |
| `stale skill link <name>` | ハーネスから消したスキルの symlink が残っている | `uskn-harness sync` が消す |
| `retired loop runner link ...` | 以前のsyncが作った `~/.local/bin/uskn-loop` が残っている。ループのコマンドは2026-11に廃止した（ADR-0016） | `uskn-harness sync` が消す |
| `notify command <name>: ... is a real directory or file` | `~/.local/bin` に、dotfilesが以前配った通知のコマンドの実ファイルが残っている | dotfilesを更新して `chezmoi apply` を実行する。片付けのスクリプトが実ファイルを消す |
| `sandbox: bwrap missing ...` / `sandbox: socat missing ...` | sandboxを有効にしたLinuxの端末に、`bwrap` か `socat` が無い。Bashは制限なしで動く | `sudo apt install -y bubblewrap socat` |
| `sandbox: bwrap cannot create a nested user namespace ...` | `bwrap` の中でユーザー名前空間を入れ子に作れない。sandboxの中のBashは全て失敗する。Ubuntu 26.04の `bwrap-userns-restrict` が原因 | 上のsandboxの節の4つのコマンドで、`bwrap-userns-restrict` を外す |
| `user settings: sync would ...` | liveのsettings.jsonが、syncの書く値と違う。`/effort` や `/model` の後に出る | `uskn-harness sync` |
| `user settings: ... is not a JSON object` | settings.jsonか端末別設定をJSONとして読めない。syncは何も書かない | ファイルを直してから `uskn-harness sync` |
| `environment: confined, but the marker ... is not trustworthy` | 環境の印の値が誤りか読めない。または、持ち主がrootでないか、閉じた環境のOSのユーザーが書ける | 管理者が印を直し、rootの持ち物の読み取り専用のファイルにする |
| `confined: <user> can write ...` | 閉じた環境のOSのユーザーが、checkoutか共有の置き場に書ける。エージェントがhookや道具を書き換えられる | 端末の土台が、持ち主とモードを直す |
| `sandbox-exec: not on Linux ...` / `sandbox-exec missing ...` | 閉じた環境のhookが、リポジトリのコードを動かせない。Linuxの閉じた環境は対象外 | macOSの端末で使う |
| `shared tools: ... has no tools= line` / `shared tools: ... does not exist` | 環境の印に `tools` が無いか、共有の置き場が無い。syncは道具とサードパーティスキルを扱えない | 管理者が印に `tools` を書き、`uskn-harness install-shared <dir>` を実行する |
| `<cli>: the shared tools record has ...` / `third-party <name>: the shared tools record has ...` | 共有の置き場の記録の版が、`deps.json` のピンと違う | 管理者が `uskn-harness install-shared <dir>` を実行する |
| `user settings: the confined environment does not carry these keys of ...` | 端末別設定に、sandboxを緩めるキーがある。閉じた環境のsyncは持ち込まない | 端末別設定からそのキーを消す。要る値は、端末の土台の最低線で決める |
| `stable path: ... is a managed clone, while the dev checkout is ...` | 参照点がmanaged cloneのままで、開発用のcheckoutが別にある | 「開発用のcheckoutの置き場」の節の手順で、手で置き換える |
