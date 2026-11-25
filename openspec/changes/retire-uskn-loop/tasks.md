# Tasks

## 1. 差分の検査のコマンド

- [x] 1.1 `plugins/uskn-harness/hooks/tests/diff-check.bats` を書き、失敗することを確かめる。扱うのは `diff-check` のspecの各シナリオと、コミット済みの削除、skipの無いテストの変更である
- [x] 1.2 `plugins/uskn-harness/hooks/scripts/diff-check.sh` をdesign.mdのD3のとおりに書く。判定の関数は `loop/lib/sensors.sh` から移す。`bats plugins/uskn-harness/hooks/tests/diff-check.bats` が通ることを確かめる
- [x] 1.3 `plugins/uskn-harness/hooks/tests/plugin-bin.bats` の一覧を更新する。`uskn-diff-check` が元のスクリプトと同じ出力と終了コードを返すテストを足す。`plugins/uskn-harness/bin/uskn-diff-check` を足し、テストが通ることを確かめる

## 2. verifyスキル

- [x] 2.1 `bin/tests/verify-skill.bats` に、本文が `uskn-diff-check` と `--allow-from` を名指しすることを確かめるテストを足し、失敗することを確かめる
- [x] 2.2 `skills/verify/SKILL.md` にdesign.mdのD4の節を足し、2.1のテストと `make verify-skills` が通ることを確かめる

## 3. auditスキル

- [x] 3.1 `bin/tests/audit-skill.bats` を書き、失敗することを確かめる。扱うのは次のとおり
  - frontmatterの `context: fork`、`background: false`、`allowed-tools`
  - 参照ファイルの存在
  - 本文が `uskn-diff-check` と `uskn-archive-check` を名指しすること
- [x] 3.2 design.mdのD5のとおりに、`skills/audit/SKILL.md` と参照ファイル2つを書く。参照ファイルは `skills/audit/references/auditor.md` と `skills/audit/references/verdict.schema.json` である。3.1のテスト、`bin/tests/skill-fork-policy.bats`、`make verify-skills` が通ることを確かめる

## 4. uskn-loopとspec-prの撤去

- [x] 4.1 `bin/tests/uskn-harness.bats` を改め、失敗することを確かめる。`sync` が `~/.local/bin/uskn-loop` を作らないこと、残ったsymlinkを消すこと、通常のファイルを残すことを扱う。`doctor` が残ったsymlinkに `warn` を出すことも扱う
- [x] 4.2 `bin/uskn-harness` の `sync` と `doctor` を改め、4.1のテストが通ることを確かめる
- [x] 4.3 `bin/tests/user-settings.bats` を10個の道具に改め、`templates/user/settings-admin.json` から `uskn-loop *` を外す。分ける前の設定断片との比較は、`uskn-loop *` を除いて比べる。テストが通ることを確かめる
- [x] 4.4 `bin/tests/makefile.bats` からループのテストの対応を外し、スキルの参照ファイルの対応を確かめるテストに替える。`Makefile` の `FAST_BATS` を改め、テストが通ることを確かめる
- [x] 4.5 `bin/uskn-loop`、`loop/`、`bin/tests/uskn-loop.bats`、`bin/tests/fixtures/loop-bin/` を消す。`bin/tests/bats-portability.bats` と `bin/tests/skill-commands.bats` の参照を直し、`bats bin/tests` が通ることを確かめる
- [x] 4.6 `skills/spec-pr/` と `bin/tests/spec-pr-skill.bats` を消す。`bin/tests/confined-push-skills.bats` の対象からも外す。`skills/spec/SKILL.md` の終わりの案内から `/spec-pr` を外し、`bin/tests/spec-skill.bats` で確かめる。`make verify-skills` と `bats bin/tests` が通ることを確かめる

## 5. 文書

- [x] 5.1 `openspec/glossary.yml` の監査役の定義を、ループの外でも通じる形に改める。textlintとterms-checkが通ることを確かめる
- [x] 5.2 `README.md`、`AGENTS.md`、`docs/setup-new-machine.md` から `uskn-loop` と `spec-pr` の記述を外し、`audit` と差分の検査を足す。textlintとterms-checkが通ることを確かめる
- [x] 5.3 `docs/adr/0016-loop-outside-harness.md` を書き、`docs/adr/0007-loop-runner.md` の状態の行に置き換えを書く。`docs/adr/0011-narrow-sandbox-scope.md` の状態の行にも書く。textlintとterms-checkが通ることを確かめる

## 6. 統合の確認

- [ ] 6.1 `make verify VERIFY_STRICT=1` と `openspec validate --all --strict` が終了コード0で終わることを確かめる
- [ ] 6.2 `grep -rn uskn-loop` を実行し、残る場所を確かめる。残ってよいのは、ADR、`docs/loop-engineering-2026-09.md`、`openspec/changes/archive/`、このchangeだけである
- [ ] 6.3 `archive-push` の手順で、レビューの承認のあとにこの変更をarchiveする
