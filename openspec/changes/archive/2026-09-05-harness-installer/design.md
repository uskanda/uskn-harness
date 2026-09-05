## Context

- 参照点、symlink 配布、skills-dir プラグイン、mise のグローバル既定は ADR-0002 で決定済み。本 change はその実装
- `~/.claude/skills` と `settings.json` は chezmoi 管理。chezmoi はコピー方式なので、管理下の実ディレクトリが symlink と同名で存在しうる。`chezmoi add ~/.claude` で symlink を取り込まないよう `.chezmoiignore` に列挙する
- openspec は project-level 生成しか持たない。ユーザー層で使うには一時ディレクトリで `openspec init --tools claude` を実行して生成物をコピーする（現在の `~/.claude/skills/openspec-*` も同じ手法で作られていた）
- `npx skills add <ローカルパス>` はコピーするので自作スキルには使わない。GitHub 上のサードパーティにだけ使う
- このマシンには nvm も pyenv も無く、Node は mise 経由でしか無い。`bin/uskn-harness` は Node に依存できない（bash + jq）

## Goals / Non-Goals

**Goals:**
- `sync` と `doctor` を bash 1 ファイルで実装し、HOME を差し替えた bats テストで検証する
- dotfiles PR #10 に必要な変更を、ライブの `~/dotfiles` に触れずに積む
- このマシンで `sync` を実行し、旧スキルと併存する状態でも壊れないことを確認する

**Non-Goals:**
- Codex / Gemini 向けの導入（アダプタの置き場だけ残す）
- Windows 対応
- `sync` によるハーネス自身の自動更新（`git pull`）は managed clone のときだけ行い、開発 checkout では行わない

## Decisions

1. **`bin/uskn-harness` は bash 単一ファイル、サブコマンドは関数**。`main "$@"` を末尾に置き、`USKN_HARNESS_SOURCED=1` のときは main を呼ばない（bats から関数を直接テストする）。代替: Node 製 CLI。bootstrap 時に Node が無いので不採用
2. **書き込みはすべて `do_link` / `do_copy` / `do_run` の 3 関数を経由**し、`--dry-run` はこの 3 関数でだけ分岐する。報告行は `printf '%-8s %s\n' "$status" "$what"`
3. **導入元の決定順**: `USKN_HARNESS_DIR` → `sync` 自身の実体の位置（`$0` を realpath で解決した checkout）。`~/.local/bin/uskn-harness` → 参照点 → checkout と symlink を辿っても実体は checkout 内なので、これが最も確実な手掛かりになる。checkout が無いマシンで clone するのは run_once（machine-bootstrap）の責務で、`sync` は clone しない
4. **mise のグローバル既定は `mise use -g node@24 jq@1.7`**。`mise.toml` の pin と `deps.json` の runtimes を単一の真実にするため、`sync` は `deps.json` の `runtimes.node.version` を読んで渡す。jq は macOS 既定に無いので mise で入れる（OS の jq があればそれを優先し、無いときだけ）
5. **openspec の導入は `mise exec -- npm install -g @fission-ai/openspec@<version>`**。version 判定は `openspec --version` の文字列比較
6. **OpenSpec ユーザー層スキルの生成**: `mktemp -d` で `openspec init --tools claude --language ja --no-animation` を実行し、`.claude/skills/openspec-*` と `.claude/commands/opsx/*` を `~/.claude/skills` と `~/.claude/commands/opsx` に `cp -R` し、各ディレクトリに `.uskn-harness-managed` を置く。上書きはこの印があるときだけ（`generatedBy:` は chezmoi 管理の旧コピーにもあるので印にならない）。ハーネス repo 自身の `.claude/skills/openspec-*` は削除し、ユーザー層に一本化する（プロダクト repo と同じ形になる）
7. **衝突の定義**: 目的の symlink 先が、(a) 実ディレクトリ・実ファイル、(b) ハーネス外を指す symlink、のいずれかなら `conflict`。上書きしない。`doctor` では (a) を `warn`（chezmoi 撤去待ち）、(b) を `fail` とする
8. **ユーザー層 CLAUDE.md はコピー**（symlink ではない）。Cowork 系のセッションが symlink の `~/.claude/CLAUDE.md` を読まない制約があるため。先頭の管理印で「ハーネス管理か手書きか」を判定する
9. **run_once は薄く保つ**（20 行以内）: 前提確認、mise 導入、参照点の用意、`bin/uskn-harness sync` の exec。ロジックはすべて `sync` 側。chezmoi テンプレートで `{{ if ne .chezmoi.os "windows" }}` に包む
10. **dotfiles PR #10 の作業は scratchpad の別クローンで行い、`harness/mise-shims` ブランチに積む**。zshrc の nvm / pyenv ブロックは削除し、PNPM_HOME のブロックは残す（`pnpm add -g` の出力先は mise と無関係）。`.chezmoiignore` には `.claude/skills/uskn-harness`、移管する各スキル名、`openspec-*`、`.claude/commands/`、`.claude/CLAUDE.md` を列挙する
11. **テスト**: `bin/tests/uskn-harness.bats`。`HOME` を一時ディレクトリにし、`USKN_HARNESS_DIR` を repo に向け、ネットワークを使う手順（mise 導入、npm、npx skills、clone）はスタブ関数で差し替える（`USKN_HARNESS_STUB_NET=1` のとき `do_run` が記録だけ行う）。検証対象は symlink の作成、衝突スキップ、冪等性、dry-run、doctor の終了コード

## Risks / Trade-offs

- [`chezmoi apply` が管理下スキルを再展開して symlink と衝突する] → `.chezmoiignore` と `dot_claude/skills` からの削除を同じ PR に入れる。撤去前は `conflict` としてスキップされるだけで壊れない
- [`~/.claude/CLAUDE.md` を新設することで全リポジトリの指示が変わる] → 内容は 60 行以内の方針だけに絞り、リポジトリ固有の指示は入れない
- [mise の導入スクリプトをネットワークから実行する] → `https://mise.run` の公式手順。checksum 検証は mise 側に任せ、`sync` は導入後に `mise --version` を確認する
- [openspec の生成物をコピーする方式は openspec の更新で形が変わりうる] → `generatedBy` の印で上書き可否を判定し、`doctor` が version 不一致を報告する

## Migration Plan

1. `sync` を実装しテストが通ったら、このマシンで `sync --dry-run` → `sync` を実行する（旧スキルは `conflict` でスキップ）
2. PR #10 に dotfiles 側の変更を積む。ユーザーがマージして `chezmoi apply` → `sync` を再実行 → `doctor` が 0
3. 戻す場合: PR #10 を revert して `chezmoi apply`、`~/.claude/skills` のハーネス symlink を `sync --remove`（本 change で実装）で消す
