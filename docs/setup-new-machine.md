# 新しい端末へのハーネス導入

macOS、Ubuntu、WSL2（Ubuntu）の端末に uskn-harness を入れる手順。
導入の実体は dotfiles の `chezmoi apply` が呼ぶ run_once スクリプトと、その中の `uskn-harness sync` にある。
ここでは順番と、OS ごとに違う点と、確認方法をまとめる。

## 仕組み

1. dotfiles（`uskanda/dotfiles`）を chezmoi で適用すると、`run_once_install-uskn-harness.sh` が 1 回だけ走る
2. スクリプトは mise を `~/.local/bin/mise` に入れ、`~/.local/share/uskn-harness` を用意する。`~/repos/uskn-harness` に checkout があれば symlink、無ければ GitHub から clone する
3. 最後に `uskn-harness sync` が走り、6 つを揃える。mise の Node と jq、ピンした CLI、スキルとプラグインの symlink、OpenSpec schema、sessions repo、ユーザー層 CLAUDE.md
4. 以後の更新は `git pull` と `uskn-harness sync` の再実行。sync は冪等で、手で置いたものは `conflict` として触らない

run_once は Windows では何もしない（spec `machine-bootstrap`）。Windows は WSL2 の中で Linux の手順を踏む。

## 事前に要るもの（全 OS 共通）

- git
- GitHub の認証。`uskanda/uskn-harness` と `uskanda/ai-sessions` は private。clone の前に `gh auth login` と `gh auth setup-git` を済ませる。認証が無いと run_once は「clone failed」で止まる。その場合は認証後に `~/.local/share/uskn-harness/bin/uskn-harness sync` を手で実行する
- ネットワーク。mise、Node、npm global の CLI、サードパーティスキルをダウンロードする
- Claude Code 本体（デスクトップアプリか CLI）。ハーネスは Claude Code を入れない。導入と login は公式手順に従う

## 手順

### Ubuntu / WSL2（Ubuntu）

```bash
sudo apt install -y git curl
gh auth login && gh auth setup-git      # gh が無ければ先に apt で入れる
git clone https://github.com/uskanda/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./setup                # apt update、chezmoi、chezmoi init --apply、zsh
```

`./setup` の中の `chezmoi apply` が run_once を走らせる。終わったら新しいシェルを開く。
zshrc が `mise activate zsh --shims` を評価し、`~/.local/share/mise/shims` が PATH に載る。

WSL2 では、Windows 側ではなく WSL の Ubuntu で上を実行する。Claude Code も WSL 側で動かす（CLI、または VS Code の WSL 拡張）。
dotfiles の WezTerm 設定は既定で WSL ドメインを開くので、ターミナルは WezTerm でよい。

### macOS

```bash
xcode-select --install                  # git を含む Command Line Tools。dotfiles の setup は入れない
gh auth login && gh auth setup-git      # gh が無ければ brew install gh を先に
git clone https://github.com/uskanda/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./setup                # Homebrew、chezmoi、chezmoi init --apply、zsh
```

Brewfile が git、gh、jq を入れる。mise は run_once が `~/.local/bin/mise` に入れる。
hook スクリプトは macOS の BSD 系コマンドに対応している。`date -j`、`shasum`、`realpath -m` が無いときの python3 へのフォールバックを持つ。
`timeout` コマンドは macOS に無いので、verify gate の検証は時間制限なしで走る。

### Windows（ネイティブ）

推奨しない。WSL2 を使う。ネイティブで試す場合の既知の論点を挙げる。

- run_once は Windows で何もしないので、clone と `bash bin/uskn-harness sync` を Git Bash で手動実行する
- sync と hook は symlink を前提にする。Git Bash では開発者モードを有効にし、`MSYS=winsymlinks:nativestrict` を設定しないとコピーになる
- Windows の `timeout.exe` は GNU の timeout と互換が無い。verify gate と textlint hook は `timeout` を見つけると使うので、PATH の順序によっては失敗する
- mise for Windows の shims の場所は `~/.local/share/mise/shims` と異なる。Makefile と verify gate はこの場所を PATH の先頭に足す
- jq は winget などで別途入れる

ネイティブ Windows で動かすなら、まず上の 4 点を検証し、結果をこの文書に追記する。

## 確認

```bash
uskn-harness doctor                     # 0 problem を確認する。warn は内容を読む
ls -la ~/.claude/skills | head          # ハーネスのスキルが symlink になっている
ls -la ~/.claude/skills/uskn-harness    # plugins/uskn-harness への symlink
claude plugin list                      # uskn-harness@skills-dir が出る
```

続けて任意の git リポジトリで Claude Code のセッションを始める。最初の応答の前に `<repo-context>` が注入されていれば SessionStart hook が動いている。
Stop hook と SessionEnd hook の確認方法は README の「hook の発火を確かめる」にある。

## 更新

```bash
chezmoi update                          # dotfiles の更新。run_once は再実行されない
uskn-harness sync && uskn-harness doctor
```

`sync` は最初に checkout を fast-forward する。実行するのは clean な checkout で、branch に upstream があり、fast-forward できるときだけ。
作業中の checkout（開発機など）ではスキップして理由を出し、導入は続ける。`--no-pull` で止められる。
更新で HEAD が動いたときは、新しい `bin/uskn-harness` を同じ引数で実行し直す。

## 取り除く

```bash
uskn-harness sync --remove              # ハーネス由来の symlink と管理コピーだけを消す
```

`~/.ai-sessions`、mise、npm global の CLI は残る。

## よくある warn

| doctor の表示 | 意味 | 対処 |
|---|---|---|
| `conflict: ... exists without .uskn-harness-managed` | 同名の実ディレクトリがある。chezmoi が以前配ったスキルのコピーなど | dotfiles の run_onchange が旧コピーを消す。残っていれば中身を確認して手で消し、`sync` を再実行 |
| `stale symlink` / `missing` | symlink が古いか無い | `uskn-harness sync` |
| `<cli> (have 'none', want '<ver>')` | npm global の CLI が未導入か版が違う | `uskn-harness sync`。ネットワークを確認 |
| `openspec schema uskn: missing` | schema の symlink が無い | `uskn-harness sync` |
