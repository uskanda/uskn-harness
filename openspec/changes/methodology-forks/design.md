## Context

- superpowers v6.3.0 の 4 スキルは SKILL.md と支援文書の Markdown（一部 TypeScript の例と bash の bisect スクリプト）。`superpowers:` プレフィックスの参照が systematic-debugging に 2 か所、writing-good-tests に 1 か所ある。SessionStart で注入される `using-superpowers` には依存しない
- superpowers の `test-*.md` と `CREATION-LOG.md` はスキルの圧力テスト用で、実行時には読まれない
- `sync` は `skills/` 配下の SKILL.md を持つディレクトリをすべて symlink する。`make verify` は name とディレクトリ名の一致と 500 行以内を検査する
- Claude Code には native の `EnterWorktree` ツールがあり、worktree は repo 内に作られる。write guard はルート外の書き込みを拒否する

## Goals / Non-Goals

**Goals:**
- 4 スキルを改変最小で取り込み、ハーネスの仕組みと矛盾する箇所だけ直す

**Non-Goals:**
- 内容の再設計（upstream の更新に追従しやすくするため）
- superpowers marketplace 経由の導入

## Decisions

1. **ディレクトリ名は upstream と同じ**（`test-driven-development` など）。§12.2 の木にある `tdd/` は使わない。upstream の差分が追いやすく、mattpocock の `tdd` と名前が衝突しない
2. **ライセンスは各ディレクトリに `LICENSE`**（MIT、Jesse Vincent）。スキルは 1 つずつ symlink されるので、1 か所にまとめると届かない
3. **変更点は SKILL.md 本文の先頭に 1 段落**（出所、版、変更の要約）。frontmatter の `description` は upstream のまま
4. **verification-before-completion の追記は「Key Patterns」と「When To Apply」に限る**。verify 規約と Stop hook、tasks.md の突き合わせを足す
5. **using-git-worktrees の変更は Step 1b と Step 3**。ルート外の worktree ディレクトリの選択肢を消し、baseline は verify 規約で確認する
6. support ファイルは実行時に読まれるものだけ取り込む。
   対象は root-cause-tracing、defense-in-depth、condition-based-waiting とその例。
   find-polluter.sh と writing-good-tests も取り込む。

## Risks / Trade-offs

- [upstream の更新に追従しにくい] → 変更は最小で `deps.json` に列挙。更新時は upstream の差分を当ててから変更点を再適用する
- [TDD スキルの「コードを消してやり直す」がユーザーの意図と衝突する] → upstream のまま。例外はユーザーに聞く
