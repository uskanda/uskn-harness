# grilling 記録: add-dir-records-allow

ルートの外で作業するときにユーザーが打つ `/allow-repo` と `/add-dir` を、`/add-dir` の1つにまとめる（issue #6）。
grillingの前に、`allow-repo.sh`、write-guardとbash-guardの拒否の理由、`allow-repo-skill` の仕様を読んだ。
Claude Codeの振る舞いは、文書（hooks、permissions）とCHANGELOGで調べた。調べて分かったことは次のとおり。

- PreToolUseのhookの入力に、追加ディレクトリの欄は無い。追加ディレクトリを表す環境変数も無い
- `DirectoryAdded` のhook（2.1.219から）は、`/add-dir` か、SDKを使うアプリの `register_repo_root` がディレクトリを足した後に呼ばれる。入力は共通の欄と `directory`（絶対パス）と `source` である
- Claude Codeはこのhookの終わりを待たず、hookは追加を止められない。起動時の `--add-dir` と、`/permissions` のWorkspaceのタブでの追加では呼ばれない
- モデルが自分で `/add-dir` を実行する手段は、文書に無い

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| `/add-dir` 1つで許可を記録するか | `DirectoryAdded` のhookを足し、追加されたディレクトリをセッションの許可ファイルに記録する。`/allow-repo` スキルは削除する。chezmoiの拒否を解くのも、chezmoiのsource directoryへの `/add-dir` で行う | 第1ラウンド #6 Q1 |
| 記録する `source` | `slash_command` と `register_repo_root` の両方。どちらもユーザーかアプリの操作で、モデルの操作ではない | 第1ラウンド #6 Q2 |
| changeの名前とブランチ | `add-dir-records-allow`。`change/adopt-bash-sandbox` から `change/add-dir-records-allow` を切る | 最終確認 |
| sandboxの設定 | `excludedCommands` から `allow-repo.sh` を外す。hookはsandboxの外で動く | 最終確認 |
| 拒否の理由 | write-guardとbash-guardの「`/allow-repo <path>` を実行する」を、「ユーザーが `/add-dir <path>` を実行する」に変える | 最終確認 |
| 最低版 | `DirectoryAdded` が入った2.1.219は、`deps.json` の最低版2.1.281より古いので、最低版は変えない | 最終確認の後に調べた事実 |
| 仕様とADR | `allow-repo-skill` を削除し、`directory-added-hook` を足す。`write-guard`、`bash-guard`、`claude-plugin-packaging`、`user-settings` を変える。ADR-0010に決定を残す | 最終確認 |

## 後回しにしたもの

- `/permissions` のWorkspaceのタブで足したディレクトリの記録。このhookが呼ばれないため

## 状態

frontierは空。共有理解は2026-10-24に確認済み。
