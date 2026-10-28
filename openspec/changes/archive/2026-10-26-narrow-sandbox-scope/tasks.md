# Tasks

## 1. 設定断片と sync（user-settings）

- [x] 1.1 `bin/tests/user-settings.bats` のsandboxのテストを先に書き換える。11個の道具のパターンがあることを確かめる。gitの下位コマンドの個別のパターンと、中身を読めない実行のパターンが無いことも確かめる。`allowWrite` の5つと、`denyWrite` の状態ディレクトリも確かめる。端末別設定の `sandbox.excludedCommands` と `allowWrite` が、sync後もliveに残るテストも足す。走らせて失敗することを確かめる
- [x] 1.2 `templates/user/settings.json` を、design.mdのD1とuser-settingsの仕様のとおりに書き換える。`bin/uskn-harness` の `is_set` に、design.mdのD2の2つのパスを足す。1.1が通ることを確かめる

## 2. sandbox-exclude の下位コマンド（harness-sync）

- [x] 2.1 `bin/tests/uskn-harness.bats` に、`sandbox-exclude` のテストを先に足す。足す、既にあるものを足さない、`*` と空を拒否する、`--list` の表示、`--remove`、既定値の `--remove` の拒否を確かめる。走らせて失敗することを確かめる
- [x] 2.2 `bin/uskn-harness` に、design.mdのD3のとおりに `sandbox-exclude` を足し、冒頭の説明に書く。2.1が通ることを確かめる

## 3. sandbox-exclude スキル（sandbox-exclude-skill）

- [x] 3.1 `bin/tests/sandbox-exclude-skill.bats` を先に書く。`disable-model-invocation: true` と `argument-hint` を持つことを確かめる。`uskn-harness sandbox-exclude` を名指しすることと、中身を読めない実行の確認の節があることも確かめる。走らせて失敗することを確かめる
- [x] 3.2 `skills/sandbox-exclude/SKILL.md` を、design.mdのD4のとおりに英語で書く。worked exampleを1つ入れる。3.1と `bin/tests/skill-*.bats` が通ることを確かめる

## 4. bash-guard の知らせ（bash-guard）

- [x] 4.1 `plugins/uskn-harness/hooks/tests/bash-guard.bats` に、仕様の4つのシナリオのテストを先に足す。liveの設定は `CLAUDE_CONFIG_DIR` を一時ディレクトリへ向けて置く。denyとの組み合わせでは知らせが出ないことも確かめる。走らせて失敗することを確かめる
- [x] 4.2 `bash-guard.sh` に、design.mdのD5のとおりに知らせを足し、冒頭の説明を直す。4.1と残りのbatsが通り、`make verify-shell` が通ることを確かめる

## 5. terms-check（terminology-guard）

- [x] 5.1 `plugins/uskn-harness/hooks/tests/terms-check.bats` に、通常のファイルでない未追跡の項目を実在と数えないテストを先に足す。項目には、`/dev/null` の写しの代わりに、テストで作れる名前付きパイプを使う。走らせて失敗することを確かめる
- [x] 5.2 `terms-check.sh` を、design.mdのD6のとおりに直す。5.1が通ることを確かめる

## 6. 文書

- [x] 6.1 `<docs/adr/0011-narrow-sandbox-scope.md>` を、design.mdのD7のとおりに書く。ADR-0009の決定3と4に注記を足す。textlintとterms-checkが通ることを確かめる
- [x] 6.2 `docs/setup-new-machine.md` のsandboxの節を、外に出す道具の既定値と `/sandbox-exclude` の使い方に書き直す。`README.md` の機能の表に、`sandbox-exclude` スキルを足す。textlintとterms-checkが通ることを確かめる

## 7. 統合

- [x] 7.1 `openspec validate narrow-sandbox-scope --strict` が通ることを確かめる。sandboxの外で `make verify VERIFY_STRICT=1` が通ることも確かめる
- [x] 7.2 `uskn-harness sync` の後、liveの `sandbox.excludedCommands` に11個の道具があることを確かめる。新しいセッションで `/sandbox-exclude terraform` を実行し、`terraform *` が加わることを確かめる。確かめた後に `--remove` で外す（archive-pushの手順で完了とみなした）
- [x] 7.3 `adopt-bash-sandbox` と `add-dir-records-allow` をarchiveした後に、PRをmainへマージする（archive-pushの手順で完了とみなした）
