## Why

監査で、役目を終えたスキルが4つ見つかった。`nessun-dorma` はClaude Codeのネイティブの `/goal` が代わり、`using-git-worktrees` はネイティブのworktreeが代わる。
`verification-before-completion` と `pre-merge` は `verify` と役割が重なる。
OpenSpecのユーザー層は、同じワークフローをスキル（`openspec-*`）とコマンド（`/opsx:*`）の2通りで配っていて、一覧が二重になっている。
残しておくと、どれを使うかの判断と保守の手間が増える。

## What Changes

- **BREAKING** スキル `nessun-dorma`、`using-git-worktrees`、`verification-before-completion`、`pre-merge` を削除する。`deps.json` の `forks` から後の2つを外す
- `verify` スキルに、実行したコマンドと結果を示してから完了と言う規則を足す。検証規約が無いときは、CIの設定から確認コマンドを導いて実行する手順も足す
- `sync` は、ハーネスの `skills/` を指していて実体の無いsymlinkを `~/.claude/skills` から消す。`doctor` はそれを `warn` と報告する
- **BREAKING** OpenSpecのユーザー層はcommands（`/opsx:*`）だけにする。`sync` は `XDG_CONFIG_HOME` をその場だけ一時ディレクトリに差し替え、commandsだけを生成する。ユーザー全体のOpenSpecの設定は変えない
- `sync` は、ハーネスが入れた `~/.claude/skills/openspec-*`（管理印のあるもの）を消す。`doctor` は `~/.claude/commands/opsx/` の6つのコマンドを検査する
- `archive-push` は、archiveに `openspec-archive-change` ではなく `opsx:archive` を呼ぶ
- OpenSpecを1.13.2に上げる。上流 `spec-driven` の案内文の改善を `uskn` schemaに移す
- chezmoiの移行スクリプトを `templates/chezmoi/` から削除する。対象は `run_onchange_before_remove-migrated-claude-skills.sh.tmpl`。
  dotfilesのコピーはfresh cloneからdraft PRで消す
- 削除したスキルへの参照を外す。対象はユーザー層の `CLAUDE.md`、`fix-ci`、`verify`、`systematic-debugging` の各スキル。
  README、ADR-0001、`docs/setup-new-machine.md` も直す
- エイリアス `mr`、`mr-main`、`mr-qa`、`merge-develop`、`switch-develop-branch` は残す

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

- `methodology-skills`: 対象を2つ（TDD、系統的デバッグ）に減らし、完了前検証とworktreeの要件を外す
- `git-workflow-skills`: スキルの集合から `pre-merge` と `nessun-dorma` を外す
- `verify-skill`: 完了の根拠を示す規則と、規約が無いときにCIの設定から確認コマンドを導く手順を足す
- `user-layer-instructions`: 方法論スキルへの導線を `verify` とネイティブのworktreeに向ける
- `harness-sync`: OpenSpecのユーザー層をcommandsだけにし、旧スキルと実体の無いsymlinkを消す
- `harness-doctor`: OpenSpecのcommandsと、実体の無いsymlinkを検査する
- `uskn-schema`: 上流 `spec-driven` 1.13.2の案内文を取り込む

## Impact

- スキル：`skills/git/` の `nessun-dorma` と `pre-merge` を削除する。
  `skills/using-git-worktrees/` と `skills/verification-before-completion/` も削除する。
  `skills/verify/`、`skills/archive-push/`（archiveを呼ぶ1行）、`skills/git/fix-ci/`、`skills/systematic-debugging/`（参照だけ）を変える
- インストーラ：`bin/uskn-harness` の `sync` と `doctor`。テストは `bin/tests/uskn-harness.bats`
- schema：`schemas/uskn/schema.yaml` と `schemas/uskn/templates/`
- ピン：`deps.json` の `clis` にあるopenspecの版と、`forks`
- 配布物：`templates/user/CLAUDE.md`。`templates/chezmoi/` から移行スクリプトを消す
- 文書：README、`docs/adr/0001-harness-architecture.md`、`docs/setup-new-machine.md`、`openspec/known-names.txt`
- 別リポジトリ：dotfilesにある移行スクリプトのコピーは、draft PRで消す
- 各マシン：次の `sync` で旧スキルのsymlinkと `openspec-*` が消える。プロダクトリポジトリの `openspec update` はユーザー全体の設定に従うので、影響は無い
