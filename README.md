# uskn-harness

個人プロダクト群で共用する、エージェントコーディング用ハーネス。
スキル、hook、テンプレート、配布用インストーラをこのリポジトリに集約する。
各プロダクトのリポジトリには `AGENTS.md` `CLAUDE.md` `openspec/` `DESIGN.md` `PRODUCT.md` だけを置く。

## 状態

Phase 4（`onboard-harness` とプロダクト repo への導入）まで完了。
monolith と uskn75-kb には draft PR を出してある。マージは他作業の目処が立ってから。
決定は [docs/adr/0001-harness-architecture.md](docs/adr/0001-harness-architecture.md) と [docs/adr/0002-plugin-distribution-via-skills-dir.md](docs/adr/0002-plugin-distribution-via-skills-dir.md) にある。
進行中の change は `openspec/changes/` を見る。

- `skills/git/`: git ワークフローのスキル 11 個（commit、push、pr、rebase、release ほか）。旧名は 1 行のエイリアスで残す
- `plugins/uskn-harness/`: hook だけを載せた Claude Code プラグイン。SessionStart で `<repo-context>`（hosting とブランチモデル）を注入する
- `skills/spec/`: `/spec <idea>` が grilling を回し、`grilling.md` を残してから OpenSpec 成果物を作る。schema `uskn`（`schemas/uskn/`）が grilling を proposal の前提にする
- `skills/journal/` と `skills/recall/`: セッションごとの journal を private repo `uskanda/ai-sessions` に貯める。事実は hook、判断はエージェントが書く。SessionEnd で commit と push を行い、SessionStart で直近 3 件を注入する。コミットには `Session: <sid8>` トレーラが付く
- `skills/allow-repo/` と PreToolUse hook `write-guard` / `bash-guard`: ルート外への書き込みを止める。`chezmoi apply` と他 repo への git 操作も止める。ユーザーが明示したときだけ `/allow-repo <path>` で解除する。解除はそのセッションに限る
- `skills/verify/` と Stop hook `verify-gate`: セッションで作業ツリーが変わったとき検証規約を実行する。規約は `make verify`、無ければ `pnpm run verify` / `npm run verify`。失敗している間は終了させない。`USKN_SKIP_VERIFY=1` で回避できる
- `skills/ja-writing/` と PostToolUse hook `textlint-check`: 日本語を含む Markdown を書くたびに textlint が走る。設定は `skills/ja-writing/textlintrc.json`
- `skills/en-writing/`: 人が読む英語の文章に agent-style の 21 ルールと humanizer を当てる。エージェント向け文書は `writing-for-agents` に任せる
- `skills/ui-guidelines/` と `templates/repo/DESIGN.md`: UI の正本は Google DESIGN.md 形式と PRODUCT.md。Impeccable は評価と改善のコマンドだけ使う
- `skills/test-driven-development/` ほか 3 件: obra/superpowers から fork した方法論スキル。TDD、系統的デバッグ、完了前検証、git worktree を扱う
- `skills/onboard-harness/` と `uskn-harness onboard-check`: プロダクト repo に何を置くかを決めて draft PR で渡す。点検は読み取り専用
- `docs/handoffs/`: 他 repo へ渡した手順書。draft PR の本文と同じ内容を残す

## 読む順番

1. [AGENTS.md](AGENTS.md): エージェント向けの入口と制約
2. [docs/adr/0001-harness-architecture.md](docs/adr/0001-harness-architecture.md): 全体構成と決定
3. [docs/proposal-2026-09.md](docs/proposal-2026-09.md): 2026年9月時点のトレンド調査と grilling の記録

## 導入

新しいマシンでは dotfiles を適用すると、run_once が mise を入れて `~/.local/share/uskn-harness` を用意する。続けて `uskn-harness sync` が走る。
この checkout がある開発機では、次のコマンドを使う。

```bash
~/repos/uskn-harness/bin/uskn-harness sync --dry-run   # 予定を確認
~/repos/uskn-harness/bin/uskn-harness sync             # 参照点、mise、npm の CLI、symlink、ユーザー層 CLAUDE.md
uskn-harness doctor                                    # 状態レポート。問題があれば終了コード 1
```

`sync` は冪等で、既存の実ディレクトリ（chezmoi 管理のスキルなど）は `conflict` として触らない。
`sync --remove` でハーネス由来の symlink と管理コピーだけを取り除ける。

## 開発

```bash
mise install      # Node 24、bats、shellcheck（mise.toml）
make verify       # openspec validate、shellcheck、bats、SKILL.md 検査、claude plugin validate、textlint、design.md lint
```
