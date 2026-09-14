## 1. テスト（TDD）

- [x] 1.1 `journal-end.bats` を直す。`origin` があってもbareリポジトリの履歴が変わらないことを確かめるテストに変え、push失敗のテストは消す。走らせて失敗を確認する
- [x] 1.2 `uskn-harness.bats` を直す。新しいマシンの `sync` で `~/.ai-sessions/.git` ができ、テストが記録したコマンドに `git clone` が無いことを確かめる。既存リポジトリのテストは残す。走らせて失敗を確認する

## 2. 実装

- [x] 2.1 `journal-end.sh` からpushとpull --rebaseを消し、冒頭のコメントを直す。1.1とshellcheckが通ることを確認する
- [x] 2.2 `bin/uskn-harness` の `ensure_sessions_repo` をcloneから `git init` に変え、先頭の手順コメント（6b）を直す。1.2が通ることを確認する
- [x] 2.3 `deps.json` からsessionsリポジトリの項目を消す。`repos` を読む箇所を `grep` で確かめ、JSONとして読めることを確認する

## 3. 文書

- [x] 3.1 ADR-0001 §10を「各端末のローカルgitにcommitし、pushしない」に書き換え、`docs/proposal-2026-09.md` のQ19とQ39に注記を足す。textlintが通ることを確認する
- [x] 3.2 README.mdの「記録」の行と `docs/setup-new-machine.md` を直す。privateリポジトリの認証の記述を消し、古い端末では `git remote remove origin` をしてよいと1行足す。textlintが通ることを確認する
- [x] 3.3 `skills/journal/SKILL.md` の「commits and pushes it」を「commits it locally」に直す。`recall` スキルとユーザー層CLAUDE.mdに、端末をまたぐ記述が無いことを確認する
- [x] 3.4 `~/.ai-sessions/README.md` を、ローカルだけで扱う前提に書き換える

## 4. 検証

- [x] 4.1 `make verify` が通ることを確認する
- [ ] 4.2 commitとpushの後、CIが緑になることを確認する

## 5. 移行（外部操作）

- [ ] 5.1この端末の `~/.ai-sessions` で未コミットの分をcommitし、`git fetch` と `git pull --rebase` でGitHub上の分を取り込む。`git status` がoriginより遅れていないことを確認する
- [ ] 5.2 `git bundle create` で `~/.ai-sessions` の退避をscratchpadに作り、`git bundle verify` が通ることを確認する
- [ ] 5.3ユーザーに確認を取ってから `gh repo delete uskanda/ai-sessions --yes` を実行する。`gh repo view uskanda/ai-sessions` が失敗することを確認する
- [ ] 5.4 archiveのあと、`openspec/specs/journal-sync/spec.md` のPurposeから「pushによってマシン間で共有する」を消す
