## Why

Claude Codeはv2.1.277から、`CLAUDE.md` の無いプロジェクトで `AGENTS.md` を読む。
v2.1.281からは、Amazon Bedrock、Google Vertex AI、Microsoft Foundry、LLM gateway、telemetryを無効にしたセッションでも読む。
`@AGENTS.md` の1行だけを持つ `CLAUDE.md` は役目を終えたので、新しいプロダクトリポジトリは `AGENTS.md` だけで完結させる。

## What Changes

- **BREAKING** `templates/repo/CLAUDE.md` を削除する。`templates/repo/AGENTS.md` に、Claude固有の記述を書く任意の `## Claude Code` 節を案内する。
- `onboard-harness` スキルは `CLAUDE.md` を置かない。`CLAUDE.md` が正本の既存リポジトリでは、中身を `AGENTS.md` へ移して `CLAUDE.md` を削除する。
- `onboard-harness` スキルが置くファイルの列挙を「上限」と呼ぶ記述を、ADR-0001と同じ「現時点の内訳で、上限ではない」に直す。
- `onboard-check` は `CLAUDE.md` が無い状態をokとする。`CLAUDE.md` か `.claude/CLAUDE.md` があって `@AGENTS.md` を含まないときはwarnを出す。
- `onboard-check` は、`CLAUDE.md` と `.claude/CLAUDE.md` のどちらも無いのに `CLAUDE.local.md` があるときもwarnを出す。
- `doctor` は、PATHの `claude` とVS Code拡張のインストールごとに版を検査する。`deps.json` の最低版（2.1.281）より古いものごとにwarnを出す。
- `deps.json` の `runtimes` に `claude-code` を足す。`sync` はインストールせず、版のピンもしない。最低版は下限で、最新版の利用を妨げない。
- このリポジトリの `CLAUDE.md` を削除し、OpenSpecの1行を `AGENTS.md` へ移す。`AGENTS.md` のhard constraintから `CLAUDE.md` を外す。
- ADR-0003を書き、ADR-0001の該当箇所に置き換えの注記を足す。

既存のプロダクトリポジトリの `CLAUDE.md` と、ユーザー層の `~/.claude/CLAUDE.md` は変えない。

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

- `repo-templates`: `CLAUDE.md` テンプレートの要件を削除し、`AGENTS.md` テンプレートがClaude固有の節を案内する要件を足す。
- `onboard-skill`: 置くものの判定から `CLAUDE.md` を外す。`CLAUDE.md` が正本のリポジトリでは移設後に削除する。
- `onboard-check`: `CLAUDE.md` の点検を「無ければok、あれば `@AGENTS.md` の参照を確認」に変える。`.claude/CLAUDE.md` も対象にする。`AGENTS.md` に頼るリポジトリの `CLAUDE.local.md` をwarnにする。
- `harness-doctor`: Claude Codeの最低版の検査を足す。対象はPATHのCLIとVS Code拡張。
- `harness-sync`: `sync` がClaude Codeをインストールせず、版をピンしない要件を足す。

## Impact

- `templates/repo/CLAUDE.md`（削除）、`templates/repo/AGENTS.md`
- `skills/onboard-harness/SKILL.md`
- `bin/uskn-harness`（`cmd_onboard_check`、`cmd_doctor`）、`bin/tests/uskn-harness.bats`
- `deps.json`
- `AGENTS.md`、`CLAUDE.md`（削除）、`README.md`、`docs/adr/0001-harness-architecture.md`、`docs/adr/0003-*.md`（新規）

各マシンのClaude Code（PATHのCLIとVS Code拡張）がv2.1.281以上であることを前提とする。
対応版でも、組み込みの `agents-md` プラグインを `/plugin` で無効にすると `AGENTS.md` は読まれない。
v2.1.276以前から更新した直後の最初のセッションでも、読まれないことがある。
作業ディレクトリか上位に `CLAUDE.md`、`.claude/CLAUDE.md`、`CLAUDE.local.md` のどれかがあるときも読まれない。
