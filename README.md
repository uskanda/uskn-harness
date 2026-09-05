# uskn-harness

個人プロダクト群で共用する、エージェントコーディング用ハーネス。
スキル、hook、テンプレート、配布用インストーラをこのリポジトリに集約し、各プロダクトのリポジトリには
`AGENTS.md` `CLAUDE.md` `openspec/` `DESIGN.md` `PRODUCT.md` だけを置く。

## 状態

Phase 0（骨格）。実装フェーズと決定事項は [docs/adr/0001-harness-architecture.md](docs/adr/0001-harness-architecture.md) を参照。

## 読む順番

1. [AGENTS.md](AGENTS.md): エージェント向けの入口と制約
2. [docs/adr/0001-harness-architecture.md](docs/adr/0001-harness-architecture.md): 全体構成と決定
3. [docs/proposal-2026-09.md](docs/proposal-2026-09.md): 2026年9月時点のトレンド調査と grilling の記録

## 開発

```bash
mise install      # Node 24（mise.toml）
make verify       # 検証。hook も同じターゲットを呼ぶ
```
