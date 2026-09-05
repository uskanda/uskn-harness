# uskn-harness

個人プロダクト群で共用する、エージェントコーディング用ハーネス。
スキル、hook、テンプレート、配布用インストーラをこのリポジトリに集約し、各プロダクトのリポジトリには
`AGENTS.md` `CLAUDE.md` `openspec/` `DESIGN.md` `PRODUCT.md` だけを置く。

## 状態

Phase 1（installer と既存スキルの移管）を実装中。決定事項は [docs/adr/0001-harness-architecture.md](docs/adr/0001-harness-architecture.md) と [docs/adr/0002-plugin-distribution-via-skills-dir.md](docs/adr/0002-plugin-distribution-via-skills-dir.md)、進行中の change は `openspec/changes/` を参照。

- `skills/git/`: commit / push / pr / sync-base / switch-base / rebase / cleanup-merged / pre-merge / fix-ci / release / nessun-dorma と旧名エイリアス
- `plugins/uskn-harness/`: SessionStart で `<repo-context>`（hosting とブランチモデル）を注入する hook

## 読む順番

1. [AGENTS.md](AGENTS.md): エージェント向けの入口と制約
2. [docs/adr/0001-harness-architecture.md](docs/adr/0001-harness-architecture.md): 全体構成と決定
3. [docs/proposal-2026-09.md](docs/proposal-2026-09.md): 2026年9月時点のトレンド調査と grilling の記録

## 導入

新しいマシン: dotfiles を適用すると run_once が mise を入れ、`~/.local/share/uskn-harness` を用意して `uskn-harness sync` を実行する。
開発機（この checkout がある場合）:

```bash
~/repos/uskn-harness/bin/uskn-harness sync --dry-run   # 予定を確認
~/repos/uskn-harness/bin/uskn-harness sync             # 参照点、mise、openspec、symlink、ユーザー層 CLAUDE.md
uskn-harness doctor                                    # 状態レポート。問題があれば終了コード 1
```

`sync` は冪等で、既存の実ディレクトリ（chezmoi 管理のスキルなど）は `conflict` として触らない。
`sync --remove` でハーネス由来の symlink と管理コピーだけを取り除ける。

## 開発

```bash
mise install      # Node 24, bats, shellcheck（mise.toml）
make verify       # openspec validate / shellcheck / bats / SKILL.md 検査 / claude plugin validate
```
