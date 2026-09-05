## Why

ADR-0001 §9 は superpowers の 4 スキルを MIT 表記付きで fork すると決めた。
対象は test-driven-development、systematic-debugging、verification-before-completion、using-git-worktrees。
ユーザー層の「失敗するテストを先に書く」「検証してから完了と言う」は指示だけで、手順を持つスキルが無い。
fork したうえで、verify 規約、Stop hook、cross-repo ガード、OpenSpec に合わせる。

## What Changes

- obra/superpowers v6.3.0 から 4 スキルを取り込む。`test-driven-development` は SKILL.md と writing-good-tests.md。`systematic-debugging` は SKILL.md と支援文書 3 つ、例と bisect スクリプト。残る 2 つは SKILL.md だけ
- 各ディレクトリに upstream の MIT ライセンスを置き、frontmatter に `license: MIT` を入れる
- superpowers 固有の参照（`superpowers:` プレフィックス、writing-skills）をハーネスのスキル名に置き換える
- verification-before-completion に検証規約を足す。規約は `make verify` → `pnpm run verify` / `npm run verify` で、Stop hook も同じものを走らせる。OpenSpec の tasks.md との突き合わせも足す
- using-git-worktrees の worktree をプロジェクトルート内に限る。置き場は native ツールか `.worktrees/`
- ルート外は write guard で止まるため、`/allow-repo` を先に実行する。baseline の確認は verify 規約に寄せる
- superpowers の skill テスト用ファイル（CREATION-LOG、test-*.md）は取り込まない
- `deps.json` の `forks` を `vendored` にし、取り込み日と変更点を記録する
- ユーザー層 `CLAUDE.md` の TDD と検証の行をスキル名で指す

## Capabilities

### New Capabilities
- `methodology-skills`: 4 つの fork スキルの外形（名前、出所表記、ハーネスへの適合点）

### Modified Capabilities
- `user-layer-instructions`: TDD / デバッグ / 検証 / worktree の行をスキル名で指す

## Impact

- 新規: `skills/test-driven-development/` と `skills/systematic-debugging/`
- 新規: `skills/verification-before-completion/` と `skills/using-git-worktrees/`
- 変更: `deps.json`、`templates/user/CLAUDE.md`、README
- `sync` は `skills/` 配下を自動で symlink するので installer の変更は不要
