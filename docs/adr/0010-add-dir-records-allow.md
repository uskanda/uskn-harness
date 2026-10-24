# ADR-0010: ルートの外への書き込みの許可は /add-dir の1つにする

- 状態：採用（2026-10-24）。ADR-0009の決定7を差し替える
- 決定者：uskanda（change `add-dir-records-allow` のgrilling。第1ラウンドのQ1とQ2）
- 関連：issue #6、ADR-0009

## 文脈

ADR-0009の後、ルートの外で作業するとき、ユーザーは2つのコマンドを打っていた。
`/allow-repo <path>` は、write-guardとbash-guardが読むセッションの許可ファイルに記録する。`/add-dir <path>` は、sandboxの中のBashの書き込み先を足す。
PreToolUseのhookの入力には追加ディレクトリの欄が無いため、write-guardは `/add-dir` の結果を直接読めない。
Claude Code（2.1.219から）の `DirectoryAdded` のhookは、`/add-dir` の後に、追加したディレクトリの絶対パスを入力に入れて呼ばれる。
モデルが自分で `/add-dir` を実行する手段は、文書に無い。

## 決定

1. `DirectoryAdded` のhook `directory-added.sh` が、追加されたディレクトリを `allow-repo.sh` でセッションの許可ファイルに記録する。`source` が `slash_command` と `register_repo_root` のどちらでも記録する
2. `/allow-repo` スキルを削除する。`allow-repo.sh` は、記録と `--list` のために残す
3. write-guardとbash-guardの拒否の理由は、ユーザーに `/add-dir <path>` を打ってもらうよう案内する
4. 設定断片の `sandbox.excludedCommands` から `allow-repo.sh` を外す。hookはsandboxの外で動く

## 検討した代替案

| 案 | 退けた理由 |
|---|---|
| `/allow-repo` も残す | 許可の入口が2つになり、どちらを打つかをユーザーが迷う |
| `/allow-repo` が `/add-dir` を実行する | スキルから組み込みのコマンドを実行する手段が、文書に無い |
| write-guardが追加ディレクトリを直接読む | PreToolUseのhookの入力にも環境変数にも、追加ディレクトリが無い |
| `/add-dir` の記録だけにし、`register_repo_root` は記録しない | どちらもユーザーかアプリの操作で、モデルの操作ではない |

## 結果

- 良い点：ユーザーが打つのは `/add-dir` だけになる。許可ファイルに書くのは、ハーネスのhookだけのままである
- 引き受けるコスト：Claude Codeはhookの終わりを待たないので、`/add-dir` の直後の書き込みが、記録の前に拒否されることがある。`/permissions` のWorkspaceのタブで足したディレクトリは、記録されない
- 後回し：追加を取り消したときの許可の取り消し。取り消しのイベントが無いため、許可はセッションが終わるまで残る
