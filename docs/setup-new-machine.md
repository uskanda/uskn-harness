# 新しい端末へのハーネス導入

macOS、Ubuntu、WSL2（Ubuntu）の端末にuskn-harnessを入れる手順。
導入の実体は、dotfilesの `chezmoi apply` のたびに走るbootstrapのスクリプトと、その中の `uskn-harness sync` にある。
ここでは順番と、OSごとに違う点と、確認方法をまとめる。

## 仕組み

1. dotfiles（`uskanda/dotfiles`）をchezmoiで適用するたびに、bootstrapのスクリプトがファイルの適用の後に走る。正本は `templates/chezmoi/run_after_uskn-harness.sh.tmpl`
2. スクリプトは、miseと `~/.local/share/uskn-harness` が無ければ用意する。miseは `~/.local/bin/mise` に入れる。`~/repos/uskn-harness` にcheckoutがあればsymlink、無ければGitHubからcloneする
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

- 設定断片 `templates/user/settings.json` のキーは、syncのたびにハーネスの値で上書きする。`/model` や `/config` で変えた値も、次のsyncで戻る
- 設定断片に無いキーは残す。Claude Codeが書いたキーや、端末で足した `permissions.allow` の要素がこれに当たる
- `/effort` が `modelSettings` に書いた値は、syncのたびに消す。effortの既定値は、設定断片のtop-levelの `effortLevel` である
- 設定断片から消したキーと要素は、syncが適用記録と比べてliveからも消す。適用記録は `~/.local/state/uskn-harness/settings-applied.json` にある

1台の端末だけで使う値は、端末別設定 `~/.config/uskn-harness/settings.json` に書く。端末別設定はリポジトリに入らない。
書き方は設定断片と同じで、syncは設定断片の後に端末別設定をマージする。

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
| `notify command <name>: ... is a real directory or file` | `~/.local/bin` に、dotfilesが以前配った通知のコマンドの実ファイルが残っている | dotfilesを更新して `chezmoi apply` を実行する。片付けのスクリプトが実ファイルを消す |
| `user settings: sync would ...` | liveのsettings.jsonが、syncの書く値と違う。`/effort` や `/model` の後に出る | `uskn-harness sync` |
| `user settings: ... is not a JSON object` | settings.jsonか端末別設定をJSONとして読めない。syncは何も書かない | ファイルを直してから `uskn-harness sync` |
