## Why

git ワークフロー系のスキル（commit, push, mr 系, rebase, release など 13 個）は `~/.claude/skills` に散在し、`develop` / `main` / `qa` というひとつのプロジェクトのブランチ運用や Issue 番号の履歴が本文に固定されている。ハーネスの正本として集約し、どのリポジトリでも同じ名前で使えるようにする。あわせて、各スキルが依存しているホスティング判定（`claude-hosting-hook`）を Claude Code プラグインの SessionStart hook として配布できる形に移す。

## What Changes

- `skills/git/` に 11 個のスキルを新設する: `commit` `push` `pr` `sync-base` `switch-base` `rebase` `cleanup-merged` `pre-merge` `fix-ci` `release` `nessun-dorma`。本文は英語、Agent Skills 仕様準拠
- `mr` `mr-main` `mr-qa` `merge-develop` `switch-develop-branch` を 1 行のエイリアススキル（`disable-model-invocation: true`）として残す
- ブランチ名の固定を廃止し、「自動検出 + AGENTS.md の `## Branch model` fenced yaml で上書き」に置き換える
- `plugins/uskn-harness/` を新設し、`hooks/hooks.json` の SessionStart で `session-start.sh` を実行する。`session-start.sh` は既存 `claude-hosting-hook` の判定にブランチモデルの判定を加え、`<repo-context>` ブロックを注入する。`--plain` の CLI モードを維持し、hosting と branches を機械可読で返す
- `templates/repo/AGENTS.md` に `## Branch model` の記述例を置く
- プロジェクト履歴への言及（Issue #349、`mr-staging` の経緯）を削除する
- **BREAKING**（ユーザー個人環境のみ）: `~/.claude/skills` の同名スキルと `claude-hosting-hook` は dotfiles の PR #10 で撤去される。撤去までは同名が併存するため、`sync` は既存があればスキップする（`harness-installer` change 側）

## Capabilities

### New Capabilities
- `session-context-hook`: SessionStart で作業リポジトリのホスティング（GitHub / GitLab）とブランチモデルを判定し、`<repo-context>` として注入する hook。`--plain` の CLI モードを持つ
- `branch-model`: 既定ブランチ・統合ブランチ・QA ブランチ・リリースタグ形式の解決規則と、AGENTS.md による上書き形式
- `git-workflow-skills`: 移管する 11 スキルと 5 エイリアスの外形的な振る舞い（引数、対象ブランチ、auto-merge、ソースブランチの扱い、出力言語）
- `claude-plugin-packaging`: `plugins/uskn-harness/` が skills-dir プラグインとして読み込まれ、`claude plugin validate --strict` を通ること

### Modified Capabilities
（なし。既存の main spec は無い）

## Impact

- 新規: `skills/git/**`, `plugins/uskn-harness/**`, `templates/repo/AGENTS.md`, `plugins/uskn-harness/hooks/tests/*.bats`
- 変更: `Makefile`（`verify-skills` の探索深さ、`claude plugin validate --strict` の追加）
- 依存: bash, jq, git, gh / glab（実行時）、bats と shellcheck（検証時、mise 管理）
- 他リポジトリ: dotfiles（撤去は `harness-installer` の PR #10 に含める。本 change では触れない）
