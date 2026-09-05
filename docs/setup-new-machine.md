# 新しい端末へのハーネス導入

macOS、Ubuntu、WSL2（Ubuntu）の端末にuskn-harnessを入れる手順。
導入の実体はdotfilesの `chezmoi apply` が呼ぶrun_onceスクリプトと、その中の `uskn-harness sync` にある。
ここでは順番と、OSごとに違う点と、確認方法をまとめる。

## 仕組み

1. dotfiles（`uskanda/dotfiles`）をchezmoiで適用すると、`run_once_install-uskn-harness.sh` が1回だけ走る
2. スクリプトはmiseを `~/.local/bin/mise` に入れ、`~/.local/share/uskn-harness` を用意する。`~/repos/uskn-harness` にcheckoutがあればsymlink、無ければGitHubからcloneする
3. 最後に `uskn-harness sync` が走り、6つを揃える。miseのNodeとjq、ピンしたCLI、スキルとプラグインのsymlink、OpenSpec schema、sessionsリポジトリ、ユーザー層CLAUDE.md
4. 以後の更新は `git pull` と `uskn-harness sync` の再実行。syncは冪等で、手で置いたものは `conflict` として触らない

run_onceはWindowsでは何もしない（spec `machine-bootstrap`）。WindowsはWSL2の中でLinuxの手順を踏む。

## 事前に要るもの（全 OS 共通）

- git
- GitHubの認証。`uskanda/uskn-harness` と `uskanda/ai-sessions` はprivate。cloneの前に `gh auth login` と `gh auth setup-git` を済ませる。認証が無いとrun_onceは「clone failed」で止まる。その場合は認証後に `~/.local/share/uskn-harness/bin/uskn-harness sync` を手で実行する
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

`./setup` の中の `chezmoi apply` がrun_onceを走らせる。終わったら新しいシェルを開く。
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

Brewfileがgit、gh、jqを入れる。miseはrun_onceが `~/.local/bin/mise` に入れる。
hookスクリプトはmacOSのBSD系コマンドに対応している。`date -j`、`shasum`、`realpath -m` が無いときのpython3へのフォールバックを持つ。
`timeout` コマンドはmacOSに無いので、verify gateの検証は時間制限なしで走る。

### Windows（ネイティブ）

推奨しない。WSL2を使う。ネイティブで試す場合の既知の論点を挙げる。

- run_onceはWindowsで何もしないので、cloneと `bash bin/uskn-harness sync` をGit Bashで手動実行する
- syncとhookはsymlinkを前提にする。Git Bashでは開発者モードを有効にし、`MSYS=winsymlinks:nativestrict` を設定しないとコピーになる
- Windowsの `timeout.exe` はGNUのtimeoutと互換が無い。verify gateとtextlint hookは `timeout` を見つけると使うので、PATHの順序によっては失敗する
- mise for Windowsのshimsの場所は `~/.local/share/mise/shims` と異なる。Makefileとverify gateはこの場所をPATHの先頭に足す
- jqはwingetなどで別途入れる

ネイティブWindowsで動かすなら、まず上の4点を検証し、結果をこの文書に追記する。

## 確認

```bash
uskn-harness doctor                     # 0 problem を確認する。warn は内容を読む
ls -la ~/.claude/skills | head          # ハーネスのスキルが symlink になっている
ls -la ~/.claude/skills/uskn-harness    # plugins/uskn-harness への symlink
claude plugin list                      # uskn-harness@skills-dir が出る
```

続けて任意のgitリポジトリでClaude Codeのセッションを始める。最初の応答の前に `<repo-context>` が注入されていればSessionStart hookが動いている。
Stop hookとSessionEnd hookの確認方法はREADMEの「hookの発火を確かめる」にある。

## 更新

```bash
chezmoi update                          # dotfiles の更新。run_once は再実行されない
uskn-harness sync && uskn-harness doctor
```

`sync` は最初にcheckoutをfast-forwardする。実行するのはcleanなcheckoutで、branchにupstreamがあり、fast-forwardできるときだけ。
作業中のcheckout（開発機など）ではスキップして理由を出し、導入は続ける。`--no-pull` で止められる。
更新でHEADが動いたときは、新しい `bin/uskn-harness` を同じ引数で実行し直す。

## 取り除く

```bash
uskn-harness sync --remove              # ハーネス由来の symlink と管理コピーだけを消す
```

`~/.ai-sessions`、mise、npm globalのCLIは残る。

## よくある warn

| doctor の表示 | 意味 | 対処 |
|---|---|---|
| `conflict: ... exists without .uskn-harness-managed` | 同名の実ディレクトリがある。chezmoi が以前配ったスキルのコピーなど | dotfiles の run_onchange が旧コピーを消す。残っていれば中身を確認して手で消し、`sync` を再実行 |
| `stale symlink` / `missing` | symlink が古いか無い | `uskn-harness sync` |
| `<cli> (have 'none', want '<ver>')` | npm global の CLI が未導入か版が違う | `uskn-harness sync`。ネットワークを確認 |
| `openspec schema uskn: missing` | schema の symlink が無い | `uskn-harness sync` |
