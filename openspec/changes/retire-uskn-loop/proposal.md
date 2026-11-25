# Proposal

## Why

`uskn-loop` は段階1（手元から手動で起動）のまま使われておらず、issueを起点に動く外側のループは、ハーネスの外の製品が担うようになった。
一方、ユーザーは外側のループを置かない端末でも開発するため、ハーネスは外側のループに依存してはならない。
ループの実行器をハーネスから外し、ループが持っていた検査のうち、セッションの中でも役に立つものだけをハーネスに残す（grilling.md）。

## What Changes

- **BREAKING** `uskn-loop` を廃止する。`bin/uskn-loop`、`loop/`、そのテストを消す。`sync` は `~/.local/bin/uskn-loop` を作らず、残っていれば取り除く
- **BREAKING** `spec-pr` スキルを廃止する。`/spec` の出口の案内は `/opsx:apply <name>` だけにする
- 差分の検査をハーネスのコマンド `uskn-diff-check` にする。テストファイルの削除、skipの追加、検証の設定の変更を、基底ブランチとの差分から見つける
- `verify` スキルが、完了の報告とPRの前に `uskn-diff-check` を実行し、見つかったものを報告する
- 監査のスキル `audit` を足す。呼び出した会話の文脈を持たないforkとして動き、変更のspecsの各シナリオをテストで確かめ、判定を返す
- 設定断片の `sandbox.excludedCommands` から `uskn-loop *` を外す
- ADR-0016に、ハーネスと外側のループの境界を残す。ADR-0007を置き換える

対象外は次のとおり。verify gateへの差分の検査の組み込み、`archive-push` からの `audit` の呼び出し、外側のループの製品の側の変更。

## Capabilities

### New Capabilities

- `diff-check`: 基底ブランチとの差分から、テストファイルの削除、skipの追加、検証の設定の変更を見つけるコマンド
- `audit-skill`: OpenSpecの変更を、実装と別の文脈で、specsと検証の結果に照らして判定するスキル

### Modified Capabilities

- `verify-skill`: 完了の報告とPRの前に、差分を検査する
- `spec-skill`: 終了時の案内から `/spec-pr` を外す
- `claude-plugin-packaging`: `bin/` に `uskn-diff-check` を足す
- `harness-sync`: `~/.local/bin/uskn-loop` を作らず、残っているものを取り除く
- `harness-doctor`: `uskn-loop` のsymlinkを検査しない。残っているときは知らせる
- `user-settings`: 管理者の環境のsandboxの外で動かす道具から `uskn-loop` を外し、10個にする。分ける前の設定断片と比べるシナリオも、`uskn-loop *` を除いて比べる形に改める
- `verify-fast`: `bin/uskn-loop` と `loop/` からテストを選ぶ規則を外す
- `loop-run`: 能力ごと廃止する
- `loop-criteria`: 能力ごと廃止する。検査の一部は `diff-check` と `audit-skill` へ移す
- `loop-progress-comment`: 能力ごと廃止する
- `spec-pr-skill`: 能力ごと廃止する。閉じた環境のコミットで止まる要件も、スキルとともに消える

## Impact

- 削除するループ：`bin/uskn-loop`、`loop/`、`bin/tests/uskn-loop.bats`、`bin/tests/fixtures/loop-bin/`
- 削除するスキル：`skills/spec-pr/`、`bin/tests/spec-pr-skill.bats`。`bin/tests/confined-push-skills.bats` の対象からも外す
- 新しい検査：`plugins/uskn-harness/hooks/scripts/diff-check.sh`、`plugins/uskn-harness/bin/uskn-diff-check`
- 新しい検査のテスト：`plugins/uskn-harness/hooks/tests/diff-check.bats`
- 新しいスキル：`skills/audit/`、`bin/tests/audit-skill.bats`
- インストーラ：`bin/uskn-harness` と `bin/tests/uskn-harness.bats`
- スキル：`skills/verify/SKILL.md`、`skills/spec/SKILL.md` と、そのテスト
- 設定：`templates/user/settings-admin.json` と `bin/tests/user-settings.bats`
- 検証：`Makefile` と `bin/tests/makefile.bats`
- 文書：`README.md`、`AGENTS.md`、`docs/setup-new-machine.md`、`openspec/glossary.yml`、`docs/adr/0007-loop-runner.md`
- ADR：`docs/adr/0016-loop-outside-harness.md`（新規）
