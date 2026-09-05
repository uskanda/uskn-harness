## 1. sync --tools（TDD）

- [x] 1.1 `bin/tests/uskn-harness.bats` に `sync --tools` のテストを書く。stub ログに mise と openspec の導入が記録され、schema symlink が作られること。skills・CLAUDE.md・参照点・sessions repo の clone が無いこと。`--tools --remove` が終了コード 2 になること。先に走らせて失敗を確認する
- [x] 1.2 `bin/uskn-harness` に `--tools` を実装し、1.1 のテストが通ることを確認する。`make verify-shell` も通す

## 2. Makefile の strict モード（TDD）

- [x] 2.1 `bin/tests/makefile.bats` を書く。道具の無い PATH で `make verify-design VERIFY_STRICT=1` が非ゼロで終わり、出力に `VERIFY_STRICT` を含むこと。`VERIFY_STRICT` 無しでは 0 で終わり、`skipped` を含むこと。先に走らせて失敗を確認する
- [x] 2.2 Makefile に `VERIFY_STRICT` と `skip` マクロを足し、7 つの skip 分岐を置き換える。対象は openspec、schema、shellcheck、bats、plugin、textlint、designmd。2.1 のテストと `make verify` が通ることを確認する

## 3. workflow と文書

- [ ] 3.1 `.github/workflows/verify.yml` を書く。中身はトリガー 3 つ、concurrency、timeout 15 分、mise-action。続けて `sync --tools`、claude CLI の導入と reshim、`make verify VERIFY_STRICT=1`。`gh workflow list` に verify が現れることを確認する
- [x] 3.2 README の「開発」に CI の 1 行、AGENTS.md の「How work happens here」3 に CI が strict で同じターゲットを走らせる旨を足す。textlint が通ることを確認する

## 4. 検証

- [x] 4.1 `make verify` がローカルで通ることを確認する
- [ ] 4.2 commit して push し、`gh run watch` で workflow が緑になることを確認する。plugin validate が CI で落ちたら design.md の対処に従って免除に切り替え、spec と grilling を更新する
