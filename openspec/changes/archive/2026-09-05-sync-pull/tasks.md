## 1. テスト（TDD）

- [x] 1.1 `bin/tests/uskn-harness.bats` に fixture を足す。一時の bare origin と clone を作り、clone に `deps.json` を置くヘルパー。単体で読み込めることを確認する
- [x] 1.2 スクリプトを `USKN_HARNESS_SOURCED=1` で読み込み、更新関数の分岐を検証するテストを書く。検証は 3 つ。遅れた clean な clone で HEAD を進める。dirty・detached・upstream 無し・分岐のそれぞれで HEAD を動かさず理由を出す。`USKN_HARNESS_REEXEC=1` では何もしない。先に走らせて失敗を確認する
- [x] 1.3 CLI 経由のテストを書く。stub のログに `pull --ff-only` が出ること。`--tools`、`--remove`、`--no-pull` では出ないこと。`--dry-run` が予定だけを出すこと。先に走らせて失敗を確認する

## 2. 実装

- [x] 2.1 `bin/uskn-harness` に `--no-pull` と `ORIG_ARGV`、更新関数を足し、`cmd_sync` に組み込む。1.2 と 1.3 のテストが通ることを確認する
- [x] 2.2 usage のヘッダに更新の手順と `--no-pull` を書く。`uskn-harness --help` の出力に現れることを確認する
- [x] 2.3 `make verify-shell` が通ることを確認する（shellcheck と bats）

## 3. 文書と検証

- [x] 3.1 `docs/setup-new-machine.md` の更新手順を「`sync` が pull する」に直す。textlint が通ることを確認する
- [x] 3.2 `make verify` が通ることを確認する
- [x] 3.3 このマシンで `uskn-harness sync --dry-run` を実行し、更新の予定行が出ることを確認する
