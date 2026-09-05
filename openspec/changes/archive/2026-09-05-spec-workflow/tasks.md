## 1. schema と導入

- [x] 1.1 `schemas/uskn/schema.yaml` に `grilling` アーティファクトとテンプレートを追加し、`openspec schema validate uskn` が通ることを確認する
- [x] 1.2 `bin/uskn-harness` の sync / doctor / --remove に schema の symlink を加え、bats が通ることを確認する。`openspec schema which uskn` が `Source: user` を返す
- [x] 1.3 `Makefile` の `verify-openspec` に `openspec schema validate uskn`（解決できるときだけ）を加え、`make verify` が通ることを確認する

## 2. grilling-guard（TDD）

- [x] 2.1 `plugins/uskn-harness/hooks/tests/grilling-guard.bats` を先に書く: 記録なしの proposal / design / tasks / specs への Write と Edit が deny、記録ありで無出力、`grilling.md` 自身と archive と `openspec/specs/` と change 外は無出力、相対パス、壊れた stdin で exit 0。RED を確認する
- [x] 2.2 `grilling-guard.sh` を実装して GREEN、shellcheck が警告ゼロ
- [x] 2.3 `hooks.json` に PreToolUse（`Write|Edit|MultiEdit|NotebookEdit`）を追加し、`claude plugin validate --strict` が通る。sandbox の `CLAUDE_CONFIG_DIR` で `claude plugin details` に PreToolUse が 1 件現れる

## 3. spec スキル

- [x] 3.1 `skills/spec/SKILL.md` を書く（引数、インタビュー先行、記録、生成ループ、`--step`、継続、停止）。frontmatter 検査と 500 行以内を確認する
- [x] 3.2 `templates/user/CLAUDE.md` の「Deciding what to build」を `/spec` 前提に更新し、`sync` で `~/.claude/CLAUDE.md` が更新されることを確認する

## 4. 記録

- [x] 4.1 `README.md` と `AGENTS.md` の作業手順を `/spec` に更新し、`openspec validate spec-workflow --strict` と `make verify` が通ることを確認してコミットする
