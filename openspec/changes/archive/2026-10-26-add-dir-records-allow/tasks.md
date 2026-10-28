# Tasks

## 1. DirectoryAdded の hook（directory-added-hook、claude-plugin-packaging）

- [x] 1.1 `plugins/uskn-harness/hooks/tests/directory-added.bats` を先に書く。仕様のシナリオのとおり、記録、重複しない記録、`systemMessage`、JSONでない入力、存在しないディレクトリ、状態ディレクトリの無いセッションを確かめる。`hooks-json.bats` に、`DirectoryAdded` のhookが1つでmatcherと `if` が無いことのテストを足す。走らせて失敗することを確かめる
- [x] 1.2 `plugins/uskn-harness/hooks/scripts/directory-added.sh` を、design.mdのD1のとおりに書き、`hooks.json` に登録する。1.1が通り、`make verify-shell` が通ることを確かめる

## 2. allow-repo の削除とガードの理由（allow-repo-skill、write-guard、bash-guard）

- [x] 2.1 `write-guard.bats` と `bash-guard.bats` の、拒否の理由に `/allow-repo` を求めるテストを、`/add-dir` を求めるテストに書き換える。走らせて失敗することを確かめる
- [x] 2.2 `write-guard.sh` と `bash-guard.sh` の拒否の理由と冒頭の説明を、design.mdのD3のとおりに直す。`allow-repo.sh` の冒頭の説明を、hookが呼ぶ形に直す。2.1と残りのbatsが通ることを確かめる
- [x] 2.3 `skills/allow-repo/` と `bin/tests/allow-repo-skill.bats` を削除する。README、`docs/setup-new-machine.md`、`templates/user/CLAUDE.md` の `/allow-repo` を `/add-dir` に直す。ADRと調査の記録は当時の記録なので直さない。`bin/tests/skill-*.bats` が通ることを確かめる

## 3. 設定断片（user-settings）

- [x] 3.1 `bin/tests/user-settings.bats` の `excludedCommands` のテストを書き換える。2つのパターンを持ち、`allow-repo.sh` のパターンを持たないことを確かめる。走らせて失敗することを確かめる
- [x] 3.2 `templates/user/settings.json` から `*/allow-repo.sh *` を外す。3.1が通ることを確かめる

## 4. 文書

- [x] 4.1 `docs/adr/0010-add-dir-records-allow.md` を、design.mdのD4のとおりに書く。ADR-0009の決定7に、ADR-0010で差し替えた旨の注記を足す。textlintとterms-checkが通ることを確かめる

## 5. 統合

- [x] 5.1 `openspec validate add-dir-records-allow --strict` と `make verify VERIFY_STRICT=1` が通ることを確かめる
- [x] 5.2 `uskn-harness sync` を実行した後の新しいセッションで、ユーザーが `/add-dir <ルートの外のディレクトリ>` を実行する。WriteとBashの両方で、そこへ書けることを確かめる。デスクトップアプリの画面でディレクトリを足したときに記録されるかも確かめ、結果をdesign.mdに追記する（archive-pushの手順で完了とみなした）
- [x] 5.3 `adopt-bash-sandbox` をarchiveした後に、PRをmainへマージする（archive-pushの手順で完了とみなした）
