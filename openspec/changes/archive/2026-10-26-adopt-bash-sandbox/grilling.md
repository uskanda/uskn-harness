# grilling 記録: adopt-bash-sandbox

bash-guardがコマンドの文字列から推測しているルート外への書き込みの検査を、Claude Codeのsandboxで置き換える（issue #5）。
grillingの前に、`bash-guard.sh` と `openspec/specs/bash-guard/spec.md`、`user-settings` の仕様を読んだ。
sandboxの振る舞いは、Claude Codeの文書（sandboxing、settings-reference、permission-modes）で調べた。この端末には `bwrap` と `socat` が無く、実機では確かめていない。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| sandboxの採否と範囲 | 全端末でsandboxを有効にする。bash-guardのwarnパターンは削除し、denyパターン（別のリポジトリへのgitの書き込み、chezmoi、許可ファイル、verify gateの状態ファイル）は残す | 第1ラウンド Q1 |
| ネットワークの許可 | 設定断片の `permissions.allow` に `WebFetch(domain:*)` を足す。Bashの接続先にも全ホストが許可されるかを最初のtaskで確かめ、許可されなければホストの一覧を `sandbox.network.allowedDomains` に足す。ユーザーの希望は、調査などの外部への接続を明示の許可なしに行うこと | 第2ラウンド Q2（ユーザーの質問を受けて選択肢を作り直した） |
| `allowUnsandboxedCommands` | `true`（既定）のままにし、sandboxの外での再実行をauto modeのclassifierに判定させる | 第2ラウンド Q3 |
| ルートの外に書くハーネスのコマンド | `allow-repo.sh`、`uskn-harness`、`chezmoi` を `excludedCommands` に並べる。`chezmoi` は、`/allow-repo` が無ければ今と同じくbash-guardが拒否する | 第2ラウンド Q4 |
| キャッシュのディレクトリ | `~/.npm`、`~/.cache`、`~/.local/share/mise` を `sandbox.filesystem.allowWrite` に足す。要らないものは最初のtaskで外す | 第2ラウンド Q5 |
| `bwrap` の無い端末 | sandboxが有効なのに `bwrap` か `socat` の無いLinuxとWSL2の端末で、doctorが `warn` を出す。syncはインストールしない。`failIfUnavailable` は `false` にする | 第2ラウンド Q6 |
| ユーザーの指示でルートの外を書き換える作業 | `/allow-repo` を実行した後に、`/add-dir <path>` を続けて打つようユーザーに案内する。2つを1つにまとめるのはissue #6で行う | 第2ラウンド Q7（ユーザーの質問を受けてQ4から分けた） |
| changeの名前とブランチ | `adopt-bash-sandbox`。mainから `change/adopt-bash-sandbox` を切る | 第3ラウンド（最終確認） |
| 変える仕様 | `bash-guard`、`user-settings`、`harness-doctor`、`allow-repo-skill` | 第3ラウンド（最終確認） |
| ADR | ADR-0009に、決定と捨てた案を残す。ADR-0008はnotify-via-telegramが使う | 第3ラウンド（最終確認） |
| sandboxの配列のマージ | `allowWrite`、`excludedCommands`、`allowedDomains` は、今のsyncの規則どおり設定断片の値で置き換える。集合として扱うのは `permissions` の下の4つの配列だけのままにする | 第3ラウンド（最終確認） |
| `.git/config` に書くgitのコマンド | sandboxの中では作業ディレクトリのリポジトリの `.git/config` に書けないため、`git push`、`git switch`、`git checkout`、`git branch`、`git config`、`git remote` を `excludedCommands` に足す。別のリポジトリへの書き込みは、今と同じくbash-guardが拒否する | 実装中の確認（実機で見つかった問題への対処。ユーザーがAを選んだ） |
| 実機での確認の前提 | 最初のtaskで、ユーザーがこの端末に `bubblewrap` と `socat` を入れる | 第3ラウンド（最終確認） |

## 後回しにしたもの

- `/allow-repo` と `/add-dir` を1つにまとめること（issue #6）
- `allowUnsandboxedCommands: false` による、sandboxの外での再実行の禁止

## 状態

frontierは空。共有理解は2026-10-23に確認済み。
