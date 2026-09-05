## 1. session-baseline（TDD）

- [x] 1.1 `session-baseline.bats` を書く: git リポジトリで baseline / project / started が作られる、非 git では何も作らない、同じ session_id では上書きしない、出力は空。RED を確認する
- [x] 1.2 `session-baseline.sh` を実装し GREEN、shellcheck 警告ゼロ

## 2. verify-gate（TDD）

- [x] 2.1 `verify-gate.bats` を書く: 変更なしで無出力、Makefile の verify 成功で無出力かつ verified 記録、失敗で block と reason（コマンド、出力）、成功後の再実行なし、`stop_hook_active` / `USKN_SKIP_VERIFY=1` / `agent_type` / 非 git / 規約なしで無出力、package.json + pnpm-lock で `pnpm run verify` が選ばれる（PATH 上の偽 pnpm で記録）。RED を確認する
- [x] 2.2 `verify-gate.sh` を実装し GREEN、shellcheck 警告ゼロ
- [x] 2.3 `hooks.json` に SessionStart（baseline）と Stop（timeout 600）を追加し、`claude plugin validate --strict` が通る

## 3. スキルと記録

- [x] 3.1 `skills/verify/SKILL.md` を書き、frontmatter 検査が通る
- [x] 3.2 このリポジトリで `verify-gate.sh` を手で実行（変更ありの状態）し、`make verify` が走って通ることを確認する
- [x] 3.3 README を更新し、`openspec validate verify-gate --strict` と `make verify` が通ることを確認してコミットする
