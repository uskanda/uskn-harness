# ADR-0009: Bashのルートの外への書き込みはClaude Codeのsandboxで制限する

- 状態：採用（2026-10-23）。ADR-0001 §7のPreToolUse Bashの行のうち、「他のパターンは警告」を差し替える
- 決定者：uskanda（change `adopt-bash-sandbox` のgrilling。第1ラウンドのQ1、第2ラウンドのQ2からQ7）
- 関連：issue #5、#6

## 文脈

bash-guardは、Bashのコマンドを単語と演算子に分け、別のリポジトリへのgitの書き込みと、ハーネスの状態ファイルへの書き込みを拒否する。
ルートの外へのそれ以外の書き込みには、`additionalContext` で警告を出していた。
警告の判定はコマンドの文字列からの推測で、`$` で始まる語、スクリプトの中の書き込み、`make` などが間接に書く場合を見逃す。
見つけた場合も警告するだけで、書き込みは止めなかった。

Claude Code（2.1.296で確認）のsandboxは、Bashの書き込み先をOSの仕組みで制限する。
既定で書けるのは、作業ディレクトリ、`$TMPDIR` の下の `claude-<uid>`、`/add-dir` などで追加したディレクトリである。
LinuxとWSL2では `bwrap` と `socat` を使い、macOSではOSに付属するSeatbeltを使う。
hook、Write、Editはsandboxの外で動く。

## 決定

1. 設定断片で、全端末のsandboxを有効にする。`failIfUnavailable` は `false`、`allowUnsandboxedCommands` は `true` にする
2. bash-guardから、ルートの外への書き込みの警告を削除する。denyパターン（別のリポジトリへのgitの書き込み、chezmoi）と、許可ファイルとverify gateの状態ファイルの保護は残す
3. `excludedCommands` で、2種類のコマンドをsandboxの外で動かす。1つ目は、ルートの外へ書くハーネスのコマンド（`allow-repo.sh`、`uskn-harness`、`chezmoi`）である。2つ目は、`.git/config` に書くgitの下位コマンド（`push`、`switch`、`checkout`、`branch`、`config`、`remote`）である。sandboxの中では、作業ディレクトリのリポジトリの `.git/config` に書けないため
4. `npx` のキャッシュ `~/.npm` は、`sandbox.filesystem.allowWrite` で書けるようにする。状態ディレクトリは含めない
5. ネットワークは、`permissions.allow` の `WebFetch(domain:*)` で、ドメインごとの確認なしに通す。sandboxはこのルールを、Bashの接続先にも全ホストの許可として使う（2026-10-24に実機で確認）
6. `bwrap` か `socat` の無いLinuxの端末では、doctorが `warn` を出す。syncはどちらもインストールしない
7. `/allow-repo` は、許可を記録した後に `/add-dir <path>` を打つようユーザーに案内する。2つを1つにまとめる作業はissue #6で行う。この決定はADR-0010が差し替えた（`/add-dir` の1つにまとめる）

ADR-0001 §7の表のうち、差し替える行は次のとおり。ほかの行はそのまま。

| イベント | 役割 |
|---|---|
| PreToolUse Bash | `chezmoi apply|add`、他 repo への `git push` などの典型と、ハーネスの状態ファイルへの書き込みを拒否。ルートの外へのそれ以外の書き込みは sandbox が制限する |

## 検討した代替案

| 案 | 退けた理由 |
|---|---|
| 別のリポジトリへのgitの書き込みの拒否も削除し、sandboxに任せる | sandboxの外での再実行と、`bwrap` の無い端末で、何も止まらなくなる |
| sandboxを有効にし、bash-guardの警告も残す | 推測による警告と、sandboxによる制限が重なる。警告は間接の書き込みを見逃す |
| sandboxを採用しない | ルートの外への書き込みを、推測による警告でしか扱えないままになる |
| 状態ディレクトリを `allowWrite` に足す | 許可ファイルとverify gateの状態ファイルへのBashの書き込みを、OSの仕組みで止められなくなる |
| `allowUnsandboxedCommands: false` | 予想していない道具が動かなくなるたびに、設定を足す必要がある |
| `failIfUnavailable: true` | `bwrap` を入れる前の新しい端末で、Claude Codeが起動しなくなる |
| 許可するドメインを空にし、セッションごとに承認する | auto modeでは、許可の無いホストへの接続が拒否される。調査で外部へ接続するたびに止まる |

## 結果

- 良い点：Bashのルートの外への書き込みは、推測でなくOSの仕組みで止まる。間接の書き込みも止まる
- 引き受けるコスト：LinuxとWSL2の端末には、ユーザーが `bubblewrap` と `socat` を入れる。sandboxと相性の悪い道具は、端末別設定の `excludedCommands` に足す。sandboxの外での再実行はauto modeのclassifierが判定し、classifierが通した書き込みは止まらない。この端末自身のIPに解決されるホストへは、sandboxの中から接続できない
- 後回し：`/allow-repo` と `/add-dir` を1つにまとめること（issue #6）。sandboxの外での再実行の禁止
