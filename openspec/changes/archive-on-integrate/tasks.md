# Tasks

## 1. 判定のコマンド

- [x] 1.1 `plugins/uskn-harness/hooks/tests/archive-check.bats` を書き、失敗することを確かめる。扱うのは次のとおり
  - 該当なし、該当あり、`.archive-later` あり、archive済み
  - 手を付けていない既存の変更、比べる先が無いとき
  - `.archive-later` を置いた変更で `openspec validate` が通り、archiveでファイルが一緒に移ること
- [x] 1.2 `plugins/uskn-harness/hooks/scripts/archive-check.sh` をdesign.mdのD1のとおりに書く。`bats plugins/uskn-harness/hooks/tests/archive-check.bats` が通ることを確かめる
- [x] 1.3 `plugins/uskn-harness/hooks/tests/plugin-bin.bats` の一覧を更新する。`uskn-archive-check` が元のスクリプトと同じ出力と終了コードを返すテストを足す。`plugins/uskn-harness/bin/uskn-archive-check` を足し、テストが通ることを確かめる

## 2. bash-guard

- [x] 2.1 `plugins/uskn-harness/hooks/tests/bash-guard.bats` にテストを足し、失敗することを確かめる。扱うのは次のとおり
  - `gh pr merge`、`glab mr merge`
  - mainへの `git push`、作業ブランチへの `git push`
  - 宣言があるとき、比べる先が無いとき
- [x] 2.2 `plugins/uskn-harness/hooks/scripts/bash-guard.sh` にdesign.mdのD3の判定を足し、冒頭の説明を更新する。`bats plugins/uskn-harness/hooks/tests/bash-guard.bats` が通ることを確かめる

## 3. スキル

- [x] 3.1 `bin/tests/` にスキルのテストを書き、失敗することを確かめる
  - `bin/tests/archive-push-skill.bats`：`disable-model-invocation` が無いことを確かめる形に変える
  - `bin/tests/skill-archive-on-integrate.bats`：`pr` と `push` の手順に、3つの名前があることを確かめる
  - 3つの名前とは、`uskn-archive-check`、`archive-push`、`.archive-later` である
- [x] 3.2 `skills/archive-push/SKILL.md` のfrontmatterと冒頭を改め、`.archive-later` のある変更を選ばないことを書く
- [x] 3.3 `skills/git/pr/SKILL.md` と `skills/git/push/SKILL.md` に、design.mdのD4の手順を足す。3.1のテストと `make verify-skills` が通ることを確かめる

## 4. CIの確認

- [x] 4.1 `bin/tests/makefile.bats` に `verify-archive` のテストを足し、失敗することを確かめる。扱うのは次のとおり
  - pull requestの外、draft
  - 該当あり、該当なし、判定できないとき（strict）
- [x] 4.2 `Makefile` に `verify-archive` をdesign.mdのD5のとおりに足し、`verify` から呼ぶ。4.1のテストが通ることを確かめる

## 5. 文書

- [ ] 5.1 `openspec/glossary.yml` に「統合の操作」と「archive保留の宣言」を足す。textlintとterms-checkが通ることを確かめる
- [ ] 5.2 `README.md` の仕様づくりの行と、`docs/loop-engineering-2026-09.md` の未決の項目を更新する。textlintとterms-checkが通ることを確かめる
- [ ] 5.3 `docs/adr/0014-archive-on-integrate.md` を書き、textlintとterms-checkが通ることを確かめる

## 6. 残っている変更のarchive

- [ ] 6.1 doctor-probe-nested-usernsを、`archive-push` の手順でarchiveする。手順は、verify、archiveとspecの同期、verify、1つのコミットである
- [ ] 6.2 sandbox-rules-revisitの9.2を「（archive-pushで完了とみなした）」と注記し、同じ手順でarchiveする

## 7. 統合の確認

- [ ] 7.1 `make verify VERIFY_STRICT=1` と `openspec validate --all --strict` が終了コード0で終わることを確かめる
- [ ] 7.2 `archive-push` の手順で、この変更をarchiveする。その後、`openspec/changes/` にactiveな変更が残っていないことを確かめる
- [ ] 7.3 `uskn-archive-check --base origin/main` が終了コード0を返すことを確かめる
