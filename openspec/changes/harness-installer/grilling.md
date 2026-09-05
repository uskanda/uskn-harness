# grilling 記録: harness-installer

本 change に効く決定は、ハーネス全体の grilling（`docs/proposal-2026-09.md` §10 第1〜5ラウンド）で確定済み。
該当箇所の抜粋。

| 決定 | 出典 |
|---|---|
| 配布: `skills/` を正本、Claude には `~/.claude/skills/` へ symlink（プレフィックスなし）。hook はプラグイン。マシン間は chezmoi の run_once | Q2, Q14 |
| ランタイムは mise（Node + Python）。shims を通す。グローバル既定 `mise use -g node@24` が必要 | Q13, Q26, 第5ラウンド事実 |
| 参照点は `~/.local/share/uskn-harness`（開発機は symlink、他端末は clone、`USKN_HARNESS_DIR` で上書き） | Q32 |
| Claude プラグインは skills-dir 方式のみ。marketplace は作らない | Q33（ADR-0002） |
| 自作スキルは `sync` が symlink。`npx skills add <owner/repo> --skill <name> -g -a claude-code` はサードパーティ専用 | Q35 |
| このマシンで `sync` を実行してよい。chezmoi 管理の同名スキルはスキップして警告 | Q37 |
| dotfiles への変更は PR #10 一本に積む（nvm/pyenv 削除、run_once、.chezmoiignore、移管スキルと hosting hook の撤去） | Q38（ユーザー判断で一本化） |
| 外部スキルは `deps.json` にピン。`doctor` が ref の不一致を警告 | Q3, 第5ラウンド前提 |
| `sync` は冪等。`init` は別名。`doctor` は状態レポートのみ | 第5ラウンド前提 |
| ユーザー層の指示は `templates/user/` から `~/.claude/CLAUDE.md` へ | Q4（ADR-0001 §5） |
| 作業ディレクトリ外のプロジェクトを直接編集しない。dotfiles はライブの作業ツリーに触れず別クローンから PR | §11 |

frontier は空。共有理解は 2026-09-05 に確認済み。
