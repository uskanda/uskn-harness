## Why

`push` は未コミットの変更があるたびに、保護判定のため `AGENTS.md` や `CLAUDE.md` を読み、明記が無ければホストのAPIを呼ぶ。保護の方針はリポジトリごとに決まっていてほとんど変わらないのに、`CLAUDE.md` に「保護されていない」と書いても読み込みの手順は毎回走る。

## What Changes

- `AGENTS.md` の `## Branch model` のyamlに `protected` キーを足す。値は `none`（保護ブランチ無し）か、保護ブランチのglobパターンを `,` で区切った並び（例：`main, release/*`）。
- `session-start.sh` がこのキーを読み、`<repo-context>` と `--json` に保護ブランチの宣言と根拠を出す。宣言が無ければ「宣言無し」と出す。`--plain branches` の4行は変えない。
- `push` は `<repo-context>` に宣言があれば、ファイルの読み込み、API、名前の推定をせず、宣言だけで判定する。宣言が無いリポジトリは今の順序で判定する。
- `templates/repo/AGENTS.md` の `## Branch model` の例と説明、`onboard-harness` の案内に `protected` を加える。

## Capabilities

### New Capabilities

無し。

### Modified Capabilities

- `branch-model`: 上書きのキーに `protected` を加え、値の形式と既定（宣言無し）を定める。
- `session-context-hook`: `<repo-context>` と `--json` に保護ブランチの宣言を含める。
- `git-workflow-skills`: `push` の保護判定で、`<repo-context>` の宣言を最優先にし、宣言があれば他の判定手段を使わない。

## Impact

- `plugins/uskn-harness/hooks/scripts/session-start.sh`
- `plugins/uskn-harness/hooks/tests/session-start.bats`
- `skills/git/push/SKILL.md`
- `templates/repo/AGENTS.md`、`skills/onboard-harness/SKILL.md`、`templates/user/CLAUDE.md`
- `openspec/glossary.yml`（「保護ブランチ」を足す）
- 既存のプロダクトリポジトリは、`## Branch model` に `protected` を書くまで今の判定のまま動く。書き足しはこの変更に含めない
