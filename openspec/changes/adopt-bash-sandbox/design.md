# Design

## Context

動機はproposal.mdのWhyを見ること。ここには、方式を決めるのに要る現状と制約だけを書く。

- `bash-guard.sh` は、書き込み先のパスを1つずつ取り出し、3つの判定に使っている。許可ファイルの保護、verify gateの状態ファイルの保護、ルートの外への警告である。前の2つは残るので、パスを取り出す解析は残る。削除するのは警告の判定と出力だけである
- Claude Codeのsandboxは、Bash、PowerShell、Monitorだけを制限する。Write、Edit、hookはsandboxの外で動く。write-guardとverify gateは影響を受けない
- sandboxで書ける場所の既定は3つある。作業ディレクトリとその下、`$TMPDIR` の下の `claude-<uid>`、追加したディレクトリである。追加したディレクトリとは、`/add-dir` と `permissions.additionalDirectories` で足したものを指す。読み取りは、一部の拒否されたディレクトリを除き、ファイルシステム全体に許される
- Linux（WSL2を含む）のsandboxは `bwrap` と `socat` を使う。無いとき、`failIfUnavailable` が `false` なら警告なしにsandboxなしで動く。macOSはOSに付属するSeatbeltで動く
- Linuxでは、`*`、`?`、`[` を含む `allowWrite` の要素は無視される。キャッシュの要素は、これらの記号を使わずに書く
- `excludedCommands` のパターンが、コマンドの先頭の語と照合されるのか、絶対パスで起動したコマンドにも当たるのかは、文書に無い。`/allow-repo` は `allow-repo.sh` を絶対パスで起動する
- sandboxが `WebFetch(domain:*)` を、Bashの接続先として全ホストの許可に読み替えるかは、文書に無い
- syncは設定断片をliveへキーごとにマージし、`permissions` の下の4つの配列だけを集合として扱う。`sandbox` の下の配列は、設定断片の値で置き換わる
- この端末には `bwrap` と `socat` が無い。実機での確認は、ユーザーが2つを入れた後に行う

## Goals / Non-Goals

**Goals:**

- sandboxを有効にしたまま、ハーネスの日常の操作が今と同じに動く。対象は `make verify`、`git push`、`gh`、`glab`、`openspec`、`npx`、`uskn-harness sync`、`/allow-repo` である
- 設定は設定断片の1か所に置き、端末別設定で端末ごとに切れる

**Non-Goals:**

- sandboxでsandboxの外での再実行を禁じること
- `/allow-repo` と `/add-dir` を1つにまとめること（issue #6）

## Decisions

### D1: 設定断片の形

```json
{
  "permissions": { "allow": ["WebFetch(domain:*)", "..."] },
  "sandbox": {
    "enabled": true,
    "failIfUnavailable": false,
    "allowUnsandboxedCommands": true,
    "excludedCommands": ["*/allow-repo.sh *", "uskn-harness *", "chezmoi *",
                         "git push *", "git switch *", "git checkout *", "git branch *", "git config *", "git remote *"],
    "filesystem": { "allowWrite": ["~/.npm", "~/.cache/gh"] }
  }
}
```

`excludedCommands` のパターンの書き方は、最初のtaskの実機の確認で決める。
`allow-repo.sh` の絶対パスが `allow-repo.sh *` に当たらないときは、`*/allow-repo.sh *` を試す。
それも当たらなければ、`allow-repo` スキルの起動のしかたを、PATHにあるpluginのコマンドに変える案をユーザーに相談する。

捨てた案は次のとおり。

| 捨てた案 | 理由 |
|---|---|
| 状態ディレクトリを `allowWrite` に足す | 許可ファイルとverify gateの状態ファイルへのBashの書き込みを、OSのレベルで止められなくなる |
| sandboxの外での再実行に任せる | `/allow-repo` と `sync` を実行するたびに、いったん失敗してから再実行する |
| `allowUnsandboxedCommands: false` | 予想していない道具が動かなくなるたびに、設定を足す必要がある |
| `failIfUnavailable: true` | `bwrap` を入れる前の新しい端末で、Claude Codeが起動しなくなる |

### D2: ネットワーク

`WebFetch(domain:*)` を `permissions.allow` に足す。WebFetchは、これでドメインごとの確認を求めなくなる。
最初のtaskで、sandboxの中から `curl -sI https://example.com` を実行し、Bashの接続先も全ホストになるかを確かめる。
ならなかったときは、`sandbox.network.allowedDomains` に次のホストを並べる。

- gitのホスティング：`github.com`、`api.github.com`、`*.githubusercontent.com`、`gitlab.com`、`gl.uskan.dev`
- パッケージの取得元：`*.npmjs.org`、`pypi.org`、`files.pythonhosted.org`

一覧に無いホストへのBashの接続は、sandboxの外での再実行に任せる。

捨てた案は、許可するドメインを空にしてセッションごとに承認することである。auto modeでは、許可の無いホストへの接続が拒否される。

### D3: bash-guard

`outside "$p" && add_warn "$p"` の判定と、`additionalContext` の警告の出力を削除する。
パスを取り出す解析、許可ファイルと状態ファイルの保護、denyパターンは変えない。
冒頭の説明から `warn` の行を削除し、ルートの外への書き込みはsandboxが制限すると書く。

捨てた案は次のとおり。

| 捨てた案 | 理由 |
|---|---|
| denyパターンの別のリポジトリへのgitの書き込みも削除する | sandboxの外での再実行と、`bwrap` の無い端末で、何も止まらなくなる |
| bash-guardを今のまま残す | 推測による警告と、sandboxによる制限が重なる。警告は間接の書き込みを見逃す |

### D4: doctor

`check_user_settings` の後に `check_sandbox_deps` を足す。
liveの `sandbox.enabled` が `true`、かつ `host_os` が `Linux` のときだけ、`bwrap` と `socat` を `have` で調べて1行報告する。
`USKN_HARNESS_OS` でOSを差し替え、PATHを絞ってbatsで確かめる。

### D5: allow-repo スキル

手順3の報告に、`/add-dir <resolved path>` を打つ案内を足す。`--list` のときは足さない。
スキルは `disable-model-invocation` のままにし、`/add-dir` を自分で実行しない。

### D6: ADR-0009

`docs/adr/0009-bash-sandbox.md` に、sandboxを採用した理由、bash-guardに残すものと削除するもの、D1からD3の捨てた案を書く。
ADR-0001の §7（hook）に、ADR-0009でwarnパターンを置き換えた旨の注記を足す。

## Risks / Trade-offs

- `bwrap` の無い端末では、警告なしにBashの書き込みが制限されない → doctorの `warn` で知らせる。denyパターンは残る
- Ubuntu 24.04以降では、`bwrap` を実行するにはAppArmorの設定を足す場合がある → 最初のtaskで確かめる。設定が要るなら、`docs/setup-new-machine.md` に手順を書く
- sandboxの外での再実行は、auto modeのclassifierが判定する。classifierが通すと、ルートの外への書き込みは止まらない → 書き込み先が別のリポジトリのgitの操作なら、bash-guardが拒否する。それ以外は受け入れる
- `uskn-loop` の実装役（`claude -p`）がsandboxの中で動くかは、文書に無い → 実装役はルートの中のworktreeで作業するので、どちらでも動く。pushは `uskn-loop` 自身がsandboxの外で行う
- `docker` など、sandboxと相性の悪い道具が動かない → 端末別設定の `excludedCommands` に足す。端末別設定の配列は設定断片の配列を置き換えるので、3つのパターンも書き写す必要がある。この手間は `docs/setup-new-machine.md` に書く

## Migration Plan

1. ユーザーが、Linuxの端末に `bubblewrap` と `socat` を入れる
2. この変更をmainへマージした後、各端末で `uskn-harness sync` を実行する。doctorの `ok` を確かめる
3. 戻すときは、端末別設定で `sandbox.enabled` を `false` にしてsyncを実行する。全端末で戻すときは、設定断片から `sandbox` を消す。syncの3方向の片付けがliveから消す

## 実機の確認（2026-10-24、Ubuntu 24.04、Claude Code 2.1.296）

`claude -p --settings <file>` に設定を渡し、sandboxの中のBashで確かめた。結果は次のとおり。

- `bwrap` はAppArmorに拒否された（`setting up uid map: Permission denied`）。`/etc/apparmor.d/bwrap` に `userns` を許すAppArmorの規則を置き、`apparmor_parser -r` で読み込むと動いた
- ルートの外と状態ディレクトリへの書き込みは `Read-only file system` で失敗した。ルートの中と `/tmp`（`permissions.additionalDirectories`）には書けた
- `npx` は `~/.npm` に書けないと失敗し、`~/.npm` を `allowWrite` に足すと動いた。`~/.cache` と `~/.local/share/mise` は要らなかった。`allowWrite` は `~/.npm` だけにする
- `WebFetch(domain:*)` を許可しただけで、Bashからexample.com、api.github.com、`gh api`、github.comへの `git ls-remote` が通った。`sandbox.network.allowedDomains` は要らない
- `gl.uskan.dev` は、この端末自身のIPに解決されるため、sandboxが拒否した（`resolved to one of this host's addresses`）。`allowedDomains` に足しても通らなかった。この端末からのGitLabへの接続は、sandboxの外での再実行に任せる
- `excludedCommands` の `*/sbx-writer.sh *` は、絶対パスで起動したコマンドに当たった。`sbx-writer.sh *` は当たらなかった。`allow-repo.sh` のパターンは `*/allow-repo.sh *` にする
- ルートの中の `make verify` は通った。`git commit` も通った

## 実機の確認（2026-10-24、sandboxを有効にした後のセッション）

syncでこの端末のsandboxを有効にした後、このセッションのBashで次のことが分かった。

- 作業ディレクトリのリポジトリの `.git/config` は、sandboxの中では書けない。`$TMPDIR` のリポジトリの `.git/config` には書けた。`allowWrite` でも外せない
- そのため、`git switch -c <branch> origin/main`、`git push -u`、`git branch --set-upstream-to` が失敗する。`git switch -c` は作業ツリーを切り替えた後、HEADを動かさずに止まった
- 対処として、`.git/config` に書くgitの下位コマンドを `excludedCommands` に足す（grilling.mdの該当の行）。`claude -p` で、`git config --local` の書き込みと取り消しがsandboxの外で通り、`~/` への書き込みは拒否されたままであることを確かめた
- `excludedCommands` は、コマンドの先頭がパターンに当たるときだけ、そのコマンドをsandboxの外で動かす。`cd <dir> && uskn-harness sync` はsandboxの中で動いて失敗し、`uskn-harness sync` だけなら外で動いた
- sandboxの中のセッションから起動した `claude -p` は、外側のsandboxの中で動く。内側の `excludedCommands` は外側の制限を外せない
- sandboxは、作業ディレクトリの `.bashrc`、`.gitconfig`、`.mcp.json` などに空のファイルを被せる。sandboxの中の `git add -A` は、それを足そうとして失敗する。`commit` スキルのとおり、`git add <paths>` で足す
- `gh run view --log-failed` は `~/.cache/gh` にログを置くため、sandboxの中では失敗した。`allowWrite` に `~/.cache/gh` を足す
- sandboxが被せる空のファイルは、terms-checkの名前の検査にも見える。sandboxの中では、実在しない `.mcp.json` が実在すると判定され、手元の検査が通ってCIで落ちた。sandboxの外のCIの結果を正とする
