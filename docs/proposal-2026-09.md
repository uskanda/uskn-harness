# uskn-harness 構成案（ドラフト v0.1 / 2026-09-05）

個人プロダクト群で共用する「エージェントコーディング用ハーネス」の構成案。
2026年9月時点のトレンド調査（§1）→ 設計原則（§2）→ 全体構成（§3〜§7）→ 未決事項（§9）の順。
未決事項は grilling で確定してから実装に入る。

---

## 0. 要約

- **正本は中立形式、ツール固有は薄いアダプタ**。スキルは Agent Skills 標準（`SKILL.md`）、指示は `AGENTS.md`、hook はツール非依存スクリプト + ツール別アダプタ、外部連携は MCP。
- **ワークフローは grilling → OpenSpec（propose）→ TDD（apply）→ 検証 → archive**。grilling は必須ゲートとして推論的（スキル）と計算的（hook）の両方で担保する。
- **リポジトリに置くのは 5 点のみ**: `AGENTS.md` / `CLAUDE.md`（`@AGENTS.md` の 1 行 + Claude 固有）/ `openspec/` / `DESIGN.md` / `PRODUCT.md`。他は本リポジトリからプラグイン・`npx skills`・chezmoi で配布。
- **チャット履歴はセッション要約 Markdown を自動生成し git 管理、全文はリポジトリ外にローカル保存**。
- **UI は Google DESIGN.md + Impeccable、ライティングは textlint（日本語）+ agent-style/humanizer（英語）**。
- 各コンポーネントは「役割 → 採用 → 代替」の表（§5）と ADR で管理し、差し替え可能に保つ。

---

## 1. 2026年9月時点のトレンド調査

### 1.1 ハーネスエンジニアリングの定義とメンタルモデル

| 出典 | 要点 |
|---|---|
| OpenAI / Ryan Lopopolo「Harness engineering」(2026-02-11) | 約 100 万行・1,500 PR を手書き 0 行で出荷。`AGENTS.md` は短い目次にとどめ `docs/` を知識ベース化、エージェントが読めるエラーを出すカスタム linter、依存方向を lint で強制、エントロピー回収（GC）エージェント。「Humans steer. Agents execute.」 |
| Martin Fowler / Birgitta Böckeler (2026-04-02) | ハーネス = **feedforward（guides: 事前に導く）+ feedback（sensors: 事後に検知して自己修正）**。それぞれ **computational（決定的・高速・安価: lint/型/テスト）** と **inferential（LLM: 遅い・非決定的）** に分かれる。速い検知は左に、重い検知は統合後に。 |
| Addy Osmani (2026-04-19) | 「Agent = Model + Harness」。構成要素: 指示ファイル、skills/MCP、サンドボックス、git を耐久状態として使う、hook、コンテキスト圧縮、自己検証ループ、planner/generator/evaluator 分離、Ralph loop、memory、subagent、worktree 分離。 |
| LangChain / Anthropic 各記事 | 2026 の主要投資先。「間違いを見つけたら二度と起きない仕組みを作る」が合言葉。 |

### 1.2 標準化の到達点（デファクト候補）

| 領域 | 状況（2026-09） | 本ハーネスでの扱い |
|---|---|---|
| **AGENTS.md** | Linux Foundation 傘下 AAIF が管理。6 万以上のリポジトリ、Codex/Cursor/Copilot/Windsurf/Zed 等が読む。**Claude Code は 2.1.246 現在も未対応**。公式は `CLAUDE.md` に `@AGENTS.md` を書くか symlink を推奨。 | 正本を `AGENTS.md` にする |
| **Agent Skills**（agentskills.io） | Anthropic が 2025-12 公開、90 日で 32 ツール、現在 40 超。`SKILL.md`（`name`/`description` 必須）+ `scripts/` `references/` `assets/`。中立配置は `.agents/skills/`（Codex, Zed 等）。`npx skills add` は 73 エージェントの配置先へ symlink。 | 正本形式として採用 |
| **MCP** | 全主要エージェントが対応。1 設定でどのツールでも動く。 | 外部連携はすべて MCP 経由 |
| **Hooks** | Claude Code（`settings.json` / plugin `hooks.json`）、Codex CLI（`.codex/hooks.json`、SessionStart/UserPromptSubmit/PreToolUse/PostToolUse、0.129 以降 `/hooks`）、Gemini CLI（`settings.json`、BeforeTool/AfterTool/SessionStart/AfterAgent 等）。**イベント語彙は収束、設定形式は非互換**。 | 本体はスクリプト、設定は各ツール向けアダプタ |
| **DESIGN.md**（Google Labs） | YAML front matter にトークン、本文に根拠。`lint`（WCAG 対比・参照整合）/`diff`/`export`（Tailwind, W3C DTCG）。**alpha**。 | プロダクトごとのデザイン正本 |
| **Claude Code プラグイン** | `.claude-plugin/plugin.json` + `skills/ agents/ hooks/ .mcp.json .lsp.json bin/`。marketplace は GitHub repo 指定で追加。`claude plugin validate`、`plugin eval`、`/skill-doctor` あり。 | hook をリポジトリに置かず配る唯一の手段として併用 |

### 1.3 Spec Driven Development: OpenSpec

- 最新 **v1.12.0（2026-09-03）**。`openspec/specs/`（現行仕様）と `openspec/changes/<name>/`（proposal / design / specs 差分 / tasks）→ `archive` で差分を specs にマージ。
- コマンド: 既定プロファイルは `/opsx:explore` `/opsx:propose` `/opsx:apply` `/opsx:archive`、拡張は `new/continue/ff/verify/sync/bulk-archive/onboard`。
- **schemas**（ワークフロー定義のフォーク・独自アーティファクト追加）、**profiles**、**stores**（複数リポジトリで仕様を共有）、`spec diff`。
- 出力先は 40 ツール。Claude Code は `.claude/skills/openspec-*/`、Codex/Zed/中立ターゲットは **`.agents/skills/`**。
- 手元では `~/.claude/skills/openspec-*` が openspec 1.3.1 生成のまま（chezmoi 管理）。更新が必要。

### 1.4 方法論スキル（プロセスの部品）

| プロジェクト | 版 | 中身 | 注意 |
|---|---|---|---|
| mattpocock/skills | 2026-09-04 更新 | **grilling**（設計木をラウンドで尋問、推奨回答付き、事実は自分で調べる）、grill-me（ユーザー起動ラッパ）、tdd、diagnosing-bugs、writing-for-agents、handoff、wayfinder、to-spec/to-tickets | `npx skills add mattpocock/skills --skill=grilling` |
| obra/superpowers | v6.3.0（2026-08-12） | brainstorming → writing-plans → executing-plans、TDD、systematic-debugging、verification-before-completion、using-git-worktrees | SessionStart で独自パイプラインを注入。**OpenSpec と計画フェーズが二重化**しやすいと複数記事が指摘 |
| hoangnb24/harness-experimental | 1.2k★ | `AGENTS.md` を入口に `HARNESS.md` `FEATURE_INTAKE.md`（tiny/normal/high-risk の 3 段階受付）、decisions log、`docs/plans/active|completed/` | 「受付段階でリスク分類」「判断を将来のエージェントに継承」の設計が参考になる |
| lopopolo/harness-engineering | CC BY 4.0 | 上記 OpenAI 記事の著者による anthology + playbooks + evals | 参考文献として `docs/` から参照 |

### 1.5 記憶・チャット履歴

| 手段 | 重さ | 特徴 |
|---|---|---|
| Claude Code auto memory | 最軽量（内蔵） | `~/.claude/projects/<repo>/memory/MEMORY.md`（200 行 / 25KB）+ トピックファイル。**マシンローカル、Claude 専用** |
| mattpocock `handoff` スキル | 軽量 | 会話を引き継ぎ文書に圧縮。ツール非依存、Markdown |
| gammons/ai-session | 軽量（bash+jq） | 全文を `~/.ai-sessions/<project>/` に保存、コミットに `Claude-Session` トレーラ、PR に表を注入。**Claude 専用・4★** |
| daaain/claude-code-log | 軽量 | JSONL → HTML/Markdown 変換 CLI |
| obra/episodic-memory | 中量（Node, SQLite+sqlite-vec, ローカル埋め込み） | 全文アーカイブ + 意味検索を MCP/CLI で提供。**Claude Code + Codex 対応** |
| claude-mem | 重量 | hook + 常駐ワーカー + SQLite。観察を圧縮して注入 |

### 1.6 UI デザイン指針

| 手段 | 状況 |
|---|---|
| Anthropic `frontend-design`（公式プラグイン） | 「AI slop」回避の汎用指針。React + Tailwind 前提 |
| Impeccable（Paul Bakaus） | **cli-v4.0.1（2026-09-04）**、26 万インストール。`PRODUCT.md` / `DESIGN.md` を正本に 23 コマンド（`audit` `critique` `polish` `bolder` `quieter`…）、**61 個の決定的検出ルール**、ライブブラウザループ。Claude Code / Codex / Gemini / Cursor / OpenCode 等 16 ツール |
| Google DESIGN.md | 上記 §1.2。Impeccable と同名ファイルを扱うが Impeccable 側は独自形式。**要すり合わせ** |
| expo/skills | Expo 公式。React Native / Expo 向け（monolith に直接効く） |

### 1.7 ライティング指針

| 手段 | 状況 |
|---|---|
| blader/humanizer | 42.8k★。Wikipedia「AI 文体の兆候」35 パターンを除去、文体サンプル対応。**英語中心** |
| yzhao062/agent-style | 21 ルール（古典 12 + LLM 観察 9）。Claude Code / AGENTS.md / Cursor / Copilot 用アダプタ、`/style-review`。コミットメッセージ・エラーメッセージも対象。**英語** |
| obra/elements-of-style | Strunk の古典。superpowers marketplace 配布 |
| **textlint-ja** | `preset-ja-technical-writing`（技術文書の定番）+ **`preset-ai-writing`**（AI らしい日本語パターン検出、2025-06〜、**MCP 対応**）。計算的センサーとして CI / hook に載る |

### 1.8 自律ループ

- Ralph loop（Geoffrey Huntley 発、Anthropic 公式プラグイン化）: Stop hook + 完了合言葉で終了を制御。
- Claude Code 内蔵の `/goal`（評価モデルが条件判定）、`/loop`（間隔実行）、`/batch`（worktree 並列）で多くのケースを代替可能。
- 既存の `nessun-dorma` スキルはこの系譜。将来 `/goal` + 検証 hook に寄せられる。

---

## 2. 設計原則

1. **正本は中立形式**: `SKILL.md`（agentskills.io 準拠）、`AGENTS.md`、MCP、DESIGN.md。ツール固有物（`CLAUDE.md`、plugin manifest、`hooks.json`）は生成物か 1 行ラッパ。
2. **Guides と Sensors を対で持つ**: 指針（スキル・AGENTS.md）を書いたら、対応する検知（hook・lint・テスト）を可能な限り computational で用意する。
3. **リポジトリ依存物は 5 点まで**: `AGENTS.md` `CLAUDE.md` `openspec/` `DESIGN.md` `PRODUCT.md`。hook・スキル・MCP 設定はリポジトリに置かない。
4. **差し替え可能**: 役割ごとに「採用 / 代替」を §5 と `docs/adr/` に記録。外部スキルはバージョンをピン止め。
5. **Progressive disclosure**: 常時ロードは目次と規則のみ。手順はスキルへ、詳細は `references/` へ（mattpocock `writing-for-agents` の規律に従う）。
6. **エージェントが自分で調べられることは書かない**: 環境（package.json、`--help`）が正本。文書には「書かれていない慣習・理由・落とし穴」だけを置く。

---

## 3. 全体アーキテクチャ（レイヤ）

```
L5 配布      uskn-harness repo ──→ Claude Code plugin marketplace
                              ├──→ npx skills add（.agents/skills へ symlink）
                              └──→ chezmoi run_once（マシン間同期・グローバル導入）
L4 記憶      auto memory（ローカル）＋ セッション要約（git）＋ openspec/archive（決定の履歴）
L3 Sensors   hooks: verify-before-stop / textlint / design lint / grilling ガード、CI
L2 Workflow  grilling → openspec propose → TDD apply → verify → archive → handoff
L1 Guides    AGENTS.md 階層 / rules / skills / DESIGN.md・PRODUCT.md / openspec/specs
L0 実行系    Claude Code 2.1.246（主）／ Codex CLI・Gemini CLI・OpenCode（副）
```

## 4. 本リポジトリの構成案

```
uskn-harness/
├── AGENTS.md                 # このリポジトリ自身の入口（ドッグフーディング）
├── CLAUDE.md                 # @AGENTS.md + Claude 固有
├── README.md
├── docs/
│   ├── principles.md         # §2 の正式版
│   ├── adr/                  # 採用・差し替えの判断記録
│   ├── portability-matrix.md # ツール別の対応表（§7）
│   └── trends/2026-09.md     # 本調査（§1）
├── skills/                   # ★正本。agentskills.io 準拠、ツール非依存、英語
│   ├── harness-onboard/      # 新リポジトリへの導入手順（templates を展開）
│   ├── spec/                 # grilling → openspec propose のラッパ（必須ゲート）
│   ├── tdd/                  # fork or 参照（§9 で決定）
│   ├── verify/               # 完了前検証（テスト・lint・型・textlint）
│   ├── session-journal/      # セッション要約の生成規則
│   ├── handoff/              # 参照（mattpocock）
│   ├── ui-guidelines/        # DESIGN.md/PRODUCT.md の書き方と Impeccable の使い分け
│   ├── ja-writing/           # 日本語ライティング規則（textlint と対）
│   └── en-writing/           # agent-style / humanizer への導線
├── deps.json                 # 外部スキルの出所とピン（grilling, humanizer, impeccable, expo/skills…）
├── hooks/
│   ├── scripts/              # ツール非依存の本体（stdin JSON → 判定）
│   │   ├── verify-before-stop.sh
│   │   ├── session-journal.sh
│   │   ├── grilling-guard.sh
│   │   └── textlint-on-write.sh
│   └── adapters/
│       ├── claude/hooks.json
│       ├── codex/hooks.json
│       └── gemini/settings.hooks.json
├── templates/repo/           # 新規リポジトリへ置く 5 点 + .textlintrc + harness.yaml
│   ├── AGENTS.md
│   ├── CLAUDE.md
│   ├── DESIGN.md
│   ├── PRODUCT.md
│   └── openspec/config.yaml
├── plugins/                  # Claude Code 向け薄いラッパ（skills/ と hooks/adapters/claude を参照）
│   └── uskn-core/.claude-plugin/plugin.json
├── .claude-plugin/marketplace.json
└── bin/uskn-harness          # init / doctor / sync
```

## 5. コンポーネント採用案と差し替え候補

| 役割 | 採用案 | 代替 / 差し替え候補 | ロックイン |
|---|---|---|---|
| 指示ファイル | `AGENTS.md` 正本、`CLAUDE.md` は import | GEMINI.md 等は生成 | なし |
| スキル形式 | Agent Skills（`SKILL.md`） | なし（事実上の標準） | なし |
| 配布 | plugin marketplace + `npx skills` + chezmoi | rulesync / agent_sync 系 | 低 |
| 仕様決定 | mattpocock **grilling**（必須） | superpowers brainstorming | 低 |
| SDD | **OpenSpec** v1.12 | Spec Kit、Kiro specs | 中（`openspec/` 構造） |
| TDD | superpowers `test-driven-development` を fork、または mattpocock `tdd` | 自作 | 低 |
| デバッグ | superpowers `systematic-debugging` or mattpocock `diagnosing-bugs` | — | 低 |
| 完了検証 | 自作 `verify` スキル + Stop hook | superpowers `verification-before-completion` | 低 |
| 履歴 | 自作 session-journal（要約 Markdown）+ ローカル全文 | episodic-memory（意味検索が要るとき）、ai-session | 低 |
| UI | Google **DESIGN.md** + **Impeccable** + expo/skills | Anthropic frontend-design | 低 |
| 日本語文章 | **textlint**（ja-technical-writing + ai-writing）+ `ja-writing` スキル | — | なし |
| 英語文章 | agent-style 21 ルール + humanizer | elements-of-style | なし |
| 自律実行 | Claude `/goal` + verify hook | Ralph loop plugin、nessun-dorma | 中（Claude 依存部分はスキル側で吸収） |
| 外部連携 | MCP | — | なし |

## 6. 1 機能の流れ（想定）

1. `/spec <idea>`: grilling がラウンド形式で設計木を潰す → 結果を `openspec/changes/<name>/grilling.md` に保存 → `/opsx:propose` 相当で proposal / design / specs / tasks を生成（日本語）。
2. `/opsx:apply`: tasks を TDD で消化。RED → GREEN → REFACTOR を `tdd` スキルが強制。
3. 終了時: Stop hook が `harness.yaml`（仮）の検証コマンド（test / lint / typecheck / textlint）を実行、失敗なら終了させない。
4. `/opsx:archive`: specs に差分をマージ。決定の履歴が `openspec/archive` に残る。
5. セッション終了 hook が要約 Markdown（目的・決定・変更ファイル・未解決）を書き出し、次回 SessionStart で直近数件の要約を注入。

## 7. 移植性マトリクス（実装前の見立て）

| 要素 | Claude Code | Codex CLI | Gemini CLI | OpenCode |
|---|---|---|---|---|
| AGENTS.md | `@AGENTS.md` 経由 | ネイティブ | GEMINI.md（生成） | ネイティブ |
| skills | `.claude/skills`（symlink） | `.agents/skills` | `.gemini/skills` | `.opencode/skills` |
| hooks | plugin `hooks.json` | `.codex/hooks.json` | `settings.json` | 未確認 |
| OpenSpec | 対応 | 対応 | 対応 | 対応 |
| MCP | 対応 | 対応 | 対応 | 対応 |

## 8. チャット履歴の 3 案

| 案 | 内容 | 長所 | 短所 |
|---|---|---|---|
| A 要約のみ | Stop/SessionEnd hook で Markdown 要約を生成し git 管理 | 最軽量、grep 可能、マシン間同期は git | 詳細は失われる |
| B 全文 | JSONL → Markdown 全文を保存 | 完全 | 重い、機密混入リスク |
| **C 要約 + ローカル全文** | 要約は git、全文は `~/.ai-sessions` 相当にローカル保存（`Session:` トレーラでコミットと紐付け） | 軽さと追跡性の両立 | 全文はマシン間で同期されない |

置き場所（プロダクト repo 内 `docs/sessions/` か、別 repo か）と検索手段（grep か episodic-memory か）は §9 で決める。

## 9. 未決事項（設計木）

grilling で確定する。太字は第 1 ラウンドの frontier。

- A 配布: **A1 導入モデル** → A2 プラグイン粒度 → **A3 外部スキルの取り込み方**
- B 指示ファイル: **B1 階層** / **B3 言語**
- C SDD: **C1 grilling ゲートの強制** → C2 プロファイル → C3 schema フォーク → C4 stores / **C5 superpowers**
- D TDD: **D1 強制レベル** → D2 検証コマンドの置き場
- E 履歴: **E1 粒度** → E2 置き場所・同期 → E3 検索
- F UI: **F1 スタック** → F2 RN/Expo 向け調整
- G 文章: **G1 スタックと適用範囲**
- H 移植: **H1 対象ツール** → H2 hook スクリプトの言語
- I リポジトリ側の許容物（A1・D の後）
- K **ハーネス自身の運営**

---

## Sources

- https://openai.com/index/harness-engineering/
- https://martinfowler.com/articles/harness-engineering.html
- https://addyosmani.com/blog/agent-harness-engineering/
- https://github.com/ai-boost/awesome-harness-engineering
- https://github.com/lopopolo/harness-engineering
- https://github.com/hoangnb24/harness-experimental
- https://agentskills.io/specification
- https://github.com/vercel-labs/skills
- https://code.claude.com/docs/en/plugins
- https://code.claude.com/docs/en/memory
- https://github.com/anthropics/claude-code/issues/50778
- https://github.com/Fission-AI/OpenSpec （docs/cli.md, docs/supported-tools.md, changelog）
- https://github.com/mattpocock/skills （grilling / grill-me / writing-for-agents）
- https://www.aihero.dev/skills-grilling
- https://github.com/obra/superpowers
- https://github.com/obra/episodic-memory
- https://github.com/gammons/ai-session
- https://github.com/daaain/claude-code-log
- https://github.com/pbakaus/impeccable
- https://github.com/google-labs-code/design.md
- https://github.com/expo/skills
- https://github.com/blader/humanizer
- https://github.com/yzhao062/agent-style
- https://github.com/textlint-ja/textlint-rule-preset-ja-technical-writing
- https://github.com/textlint-ja/textlint-rule-preset-ai-writing
- https://claude.com/plugins/ralph-loop
- https://codex.danielvaughan.com/2026/04/15/codex-cli-hooks-complete-guide-events-policy-patterns/
- https://geminicli.com/docs/hooks/
- https://github.com/PanisHandsome/ai-rules-sync , https://github.com/yelmuratoff/agent_sync

---

## 10. 決定記録

### 第1ラウンド（2026-09-05）

| # | 論点 | 決定 |
|---|---|---|
| Q1 | 実機検証の対象 | **Claude Code のみ動作保証**。他ツールは構造上の移植可能性を保つ（アダプタは用意、検証はしない） |
| Q2 | 配布モデル | `skills/` を正本に `npx skills add -g` で導入。Claude 向けプラグインは hook 配布のために併用。マシン間同期は chezmoi の run_once から |
| Q3 | 外部スキル | 混在。改変しないもの（grilling, humanizer, Impeccable, expo/skills）は参照 + ピン、改変するもの（TDD, 検証）は fork してベンダリング |
| Q4 | 指示ファイル | `AGENTS.md` 正本、`CLAUDE.md` は `@AGENTS.md` + Claude 固有。手順はスキルへ |
| Q5 | 言語 | スキル・内部文書は英語。チャット、コミット、PR、OpenSpec 成果物は日本語 |
| Q6 | grilling ゲート | ラッパスキル（導線）+ hook（ガード）。結果は `openspec/changes/<name>/grilling.md` |
| Q7 | superpowers | 丸ごとは採用しない。TDD / systematic-debugging / verification-before-completion / using-git-worktrees の 4 つを fork |
| Q8 | TDD・検証 | スキル + Stop hook。検証コマンドは機械可読な場所に置く（置き場は第2ラウンド） |
| Q9 | 履歴の粒度 | 要約 Markdown を git 管理 + 全文はリポジトリ外にローカル保存、コミットにセッション ID トレーラ |
| Q10 | UI | Google DESIGN.md + Impeccable + Expo 公式 skills（形式の衝突は第2ラウンド） |
| Q11 | 文章 | 日本語は textlint + ja-writing スキル、英語は agent-style + humanizer。対象はコミット/PR/仕様/ドキュメント/UI 文言 |
| Q12 | 運営 | 本 repo を OpenSpec + grilling でドッグフーディング、ADR、CalVer、validate を CI |

### 第2ラウンドの前提となる確認済み事実

- このマシンには **Node が入っていない**（nvm も未導入）。OpenSpec、textlint、`npx skills`、Impeccable はすべて Node を要する。hook は非対話シェルで動くため PATH の扱いが要る
- 既存 hook（`claude-notify-hook` 等）は **bash** 実装
- `npx skills add -g` は正本をホーム配下に置き、Claude には `~/.claude/skills/`、Codex には `~/.codex/skills/` へ symlink。private repo は gh 認証で可
- Impeccable の `DESIGN.md` は **独自の自由形式で Google 仕様と互換なし**、Web（CSS）専用、`init` が同名ファイルを生成する
- OpenSpec のカスタム schema は **user-level `~/.local/share/openspec/schemas/`** にも置ける（repo を汚さずに済む）。選択は `openspec/config.yaml` の `schema:`
- monolith は GitHub **private**。`uskanda/uskn-harness` は未作成

### 第2ラウンド（2026-09-05）

| # | 論点 | 決定 |
|---|---|---|
| Q13 | Node 供給 | **mise** を採用。`mise activate --shims` を zprofile に置き、非対話シェル（hook）でも解決。installer が mise と Node LTS を bootstrap |
| Q14 | Claude 側の届け方 | プラグインは hook（必要なら agents / MCP）だけの 1 個。スキルは全ツール `npx skills add -g`、Claude では `~/.claude/skills/` に symlink、名前はプレフィックスなし |
| Q15 | 既存スキル | git ワークフロー系（commit, push, pr/mr, mr-main, mr-qa, rebase, merge-develop, switch-develop-branch, cleanup-merged, pre-merge, fix-ci, release, nessun-dorma）をハーネスへ移管。**移管時にプロジェクト固有の前提（develop/main/qa 固定、Issue 番号への言及など）を汎用化する**。chezmoi-merge, sync-claude-settings, set-workspace-theme, cleanup は dotfiles に残す。`openspec-*` は CLI 生成物に置き換え |
| Q16 | OpenSpec schema | `spec-driven` を `uskn` としてフォークし `grilling` アーティファクトを proposal の前提に追加。schema は user-level `~/.local/share/openspec/schemas/uskn/` に配置、repo は `config.yaml` の `schema: uskn` のみ |
| Q17 | 検証コマンド | 規約ベース。`make verify` → `pnpm run verify` / `npm run verify` → 無ければ警告のみ |
| Q18 | 要約の生成 | ハイブリッド。bash + jq の決定的スケルトン + 変更があったセッションだけエージェントが「決定 / 未解決 / 次の一手」を追記 |
| Q19 | 履歴の置き場 | 専用 private repo（`~/.ai-sessions`、`<project>/<日付>-<slug>.md`）に要約を commit + push。全文は同配下で gitignore。コミットに `Session:` トレーラ、SessionStart で直近要約を注入 |
| Q20 | hook 言語 | bash + jq。テストは bats |
| Q21 | DESIGN.md | Google 形式を正本。Impeccable は `init` を使わずコマンドのみ利用。RN/Expo は Expo 公式 skills と prose で補う |
| Q22 | 公開範囲 | private で開始 |

第2ラウンドで提示した「明示しておく前提」はすべて承認。

### 第3ラウンドの前提となる確認済み事実

- 既存スキルに埋め込まれたプロジェクト固有の前提: 統合ブランチ `develop`、リリースブランチ `main`、QA ブランチ `qa`（feature → qa、リリースごとに develop から reset）、リリース PR タイトル `main YYYYMMDD HH:MM`、CalVer `vYY.MM.X`、`mr-qa` 内の Issue #349 への言及、`commit` の GitLab Issue 番号連携
- `push` スキルは既に「CLAUDE.md の記述 → gh/glab API → 名前ヒューリスティック」の順で保護判定しており、AGENTS.md 上書き方式の先例になっている
- ホスティング判定は `claude-hosting-hook`（SessionStart、bash、dotfiles 管理）で共通化済み。`claude-notify-hook`（TTS 通知）はマシン固有
- pyenv は zshrc に条件付き記述があるだけで、このマシンには未導入

### 第3ラウンド（2026-09-05）

| # | 論点 | 決定 |
|---|---|---|
| Q23 | ブランチモデル | 自動検出 + AGENTS.md「ブランチ運用」節で上書き。SessionStart hook が hosting と一緒に判定して注入 |
| Q24 | スキル統合 | `pr`（引数で main / qa）、`sync-base`、`switch-base` に統合。旧名（mr, mr-main, mr-qa, merge-develop, switch-develop-branch）は `disable-model-invocation: true` の 1 行エイリアス |
| Q25 | `spec` の流れ | 一括生成を既定、`--step` で段階生成 |
| Q26 | mise 移行範囲 | Node と Python の両方。zshrc の nvm / pyenv 記述は削除（**ただし dotfiles への変更は PR 経由、下記 §11 参照**） |
| Q27 | 文体サンプル | 提供する。`assets/voice/` に置く |
| Q28 | パイロット | monolith → uskn75-kb → dotfiles |
| Q29 | 実装順 | Phase 0（骨格）→ 1（installer・移管）→ 2（spec / verify / journal）→ 3（writing / UI / TDD）→ 4（onboard・パイロット） |

第3ラウンドで提示した前提はすべて承認。

## 11. 追加制約: 作業ディレクトリ外のプロジェクトを直接編集しない（ユーザー指示 2026-09-05）

- 明示的な指示があるまで、セッションは作業ディレクトリ（この repo）以外のプロジェクトを直接編集しない。
- 他 repo（dotfiles、各プロダクト）に必要な変更は、**GitHub PR**（ライブの作業ツリーに触れず別クローンで作業）か、**別セッション向けの指示テキスト**（`docs/handoffs/`）のどちらかで渡す。
- これは本ハーネス自体の制約として組み込む（ユーザー層の指示 + hook による検知）。強制レベルと運用の詳細は第4ラウンドで確定。

### 第4ラウンド（2026-09-05）

| # | 論点 | 決定 |
|---|---|---|
| Q30 | 作業ディレクトリ外編集の強制 | Write / Edit / NotebookEdit はプロジェクトルート外を hook で拒否。Bash はパターン一致で警告、`chezmoi apply|add` と他 repo への `git push` 等の典型だけ拒否。許可リストは scratchpad、`~/.ai-sessions`、`~/.claude/projects/*/memory`、`/tmp`。解除は `/allow-repo <path>`（セッション限定の許可ファイル） |
| Q31 | 他 repo への変更の渡し方 | コードで表せる変更は別クローンから GitHub PR（auto-merge なし、ライブの作業ツリーに触れない）。判断や対話が要る作業は `docs/handoffs/YYYY-MM-DD-<target>.md` に手順書を置き、別セッションが実行 |

frontier 空。以下 §12 が共有理解の確定版。

---

## 12. 共有理解（確定版 2026-09-05）

### 12.1 原則
1. 正本は中立形式（`SKILL.md`、`AGENTS.md`、MCP、Google DESIGN.md）。ツール固有物は薄いラッパか生成物
2. Guides と Sensors を対で持ち、Sensors は可能な限り computational
3. プロダクト repo に置くのは `AGENTS.md` `CLAUDE.md` `openspec/` `DESIGN.md` `PRODUCT.md`。検証は `make verify` / `pnpm run verify` の規約
4. 役割ごとに採用と代替を ADR に記録し、外部スキルはピン止め
5. Progressive disclosure。環境から分かることは書かない
6. **作業ディレクトリ外のプロジェクトを直接編集しない**。PR か handoff 文書で渡す

### 12.2 リポジトリ構成
```
uskn-harness/                      # GitHub private uskanda/uskn-harness、main のみ、CalVer
├── AGENTS.md / CLAUDE.md / README.md
├── docs/{principles.md, adr/, handoffs/, portability-matrix.md, trends/, proposal-2026-09.md}
├── openspec/                      # 自身も OpenSpec + grilling で運用
├── skills/                        # 正本。agentskills.io 準拠、英語
│   ├── spec/  verify/  journal/  recall/  allow-repo/  onboard-harness/
│   ├── git/   commit push pr sync-base switch-base rebase cleanup-merged pre-merge fix-ci release nessun-dorma
│   │          + エイリアス mr mr-main mr-qa merge-develop switch-develop-branch（disable-model-invocation）
│   ├── tdd/  systematic-debugging/  verification-before-completion/  using-git-worktrees/   # superpowers fork, MIT 表記
│   ├── ui-guidelines/  ja-writing/  en-writing/
│   └── (参照: grilling, grill-me, handoff, writing-for-agents, humanizer, impeccable, expo/skills → deps.json)
├── deps.json                      # 外部スキル・CLI の出所とピン
├── hooks/scripts/*.sh + hooks/adapters/{claude/hooks.json, codex/, gemini/}   # bash + jq、bats
├── templates/{repo/, user/}       # repo 5 点 + .textlintrc、ユーザー層 AGENTS.md
├── schemas/uskn/                  # OpenSpec schema（grilling → proposal …）。installer が user-level に配置
├── assets/voice/                  # 文体サンプル（private 前提）
├── plugins/uskn-harness/          # Claude 用。hook（+ agents / MCP）のみ
├── .claude-plugin/marketplace.json
└── bin/uskn-harness               # init | doctor | sync（mise → Node → openspec/textlint → npx skills -g → plugin）
```

### 12.3 v1 の hook
| イベント | 役割 |
|---|---|
| SessionStart | hosting（GitHub/GitLab）とブランチモデル（既定・統合・QA）の判定を注入、`~/.ai-sessions/<project>/` の直近要約を注入 |
| PreToolUse Write/Edit/NotebookEdit | プロジェクトルート外を拒否（許可リストと `/allow-repo` を除く） |
| PreToolUse Bash | 他 repo への破壊的操作（`chezmoi apply|add`、`git -C <他repo> push` 等）を拒否、他は警告。`openspec new change` / propose 前に grilling 成果物を確認 |
| PostToolUse Write/Edit | `.md`（openspec/、docs/）に textlint |
| Stop | 作業ツリーに変更があれば verify（規約コマンド）、journal 未記録なら追記を促す |
| SessionEnd | journal の決定的スケルトンを生成し sessions repo に commit |

### 12.4 ワークフロー
`/spec <idea>` → grilling（ラウンド形式）→ `grilling.md` 保存 → proposal / design / specs / tasks 一括生成（`--step` で段階）→ `/opsx:apply` を TDD で → Stop hook が verify → `/opsx:archive` → journal。

### 12.5 配布と同期
- スキル: `npx skills add uskanda/uskn-harness -g`（Claude は `~/.claude/skills/` へ symlink、名前はプレフィックスなし）
- hook: Claude プラグイン `uskn-harness`（marketplace は本 repo）
- ランタイム: mise（Node + Python、shims で非対話シェル対応）
- マシン間: chezmoi の run_once が `uskn-harness sync` を呼ぶ。`~/.claude/skills` のハーネス由来 symlink は `.chezmoiignore`。**dotfiles への変更はすべて PR 経由**

### 12.6 履歴
sessions repo（GitHub private `uskanda/ai-sessions` → `~/.ai-sessions`）に `<project>/<日付>-<slug>.md`。全文は同配下で gitignore。プロダクトのコミットに `Session:` トレーラ。検索は ripgrep + `recall`。

### 12.7 UI とライティング
- UI: Google DESIGN.md 形式を正本、Impeccable はコマンドのみ（`init` 不使用）、RN/Expo は Expo 公式 skills。frontend-design はフォールバック
- 日本語: textlint（ja-technical-writing + ai-writing）+ `ja-writing`。英語: agent-style + humanizer。文体サンプルは `assets/voice/`。文体基準はスキル作成時に短い grilling

### 12.8 実装フェーズ
0 骨格（GitHub private repo、AGENTS.md / CLAUDE.md、`openspec init`、ADR-0001）→ 1 installer・chezmoi 連携（PR）・既存スキル移管と汎用化・hosting hook 移管 → 2 spec / verify / journal・recall・cross-repo ガード → 3 writing / UI / TDD fork → 4 onboard-harness・monolith → uskn75-kb

### 12.9 後回しにしたもの
Codex 等の実機検証、episodic-memory、OpenSpec stores、intake tier（tiny / normal / high-risk）、ja-writing の文体基準、nessun-dorma の `/goal` ベース書き直しの詳細

---

## 13. Phase 1 の grilling

### 第5ラウンドの前提となる確認済み事実（2026-09-05）

- **symlink した skills-dir プラグインは hook 込みで読み込まれる**（sandbox の `CLAUDE_CONFIG_DIR` で検証。`~/.claude/skills/<name> -> <repo>/plugins/<name>` で `SessionStart` hook が認識され、`claude plugin details` で token cost も出る）。marketplace と `claude plugin install` を使わずに hook を配れる。skills-dir プラグインは `bin/` 非対応、プラグイン外へ向く内部 symlink は無視される
- **`npx skills add <ローカルパス> -g` はコピーする**（symlink ではない）。自作スキルの live 編集には `sync` 自身が symlink を張るほうが確実。`npx skills` は GitHub 上のサードパーティスキル向けに使う
- **mise の shims はグローバル設定が無いと他ディレクトリで解決しない**（`mise.toml` の無い場所で `npx is not a valid shim`）。installer は `mise use -g node@24` で `~/.config/mise/config.toml` を書く必要がある
- Claude Code のプラグイン hook は `${CLAUDE_PLUGIN_ROOT}`、`${CLAUDE_PROJECT_DIR}`、`$HOME` が shell で展開される。マーケットプレイス経由のローカルパス導入はキャッシュへコピーされる
- `claude plugin validate --strict` と `claude plugin details` が使える
- 既存 `claude-hosting-hook` は bash 約 200 行。stdin の JSON から cwd を取り、remote URL → gh/glab 設定 → CI ファイルの順で判定し、`<repo-hosting>` ブロックを出力する。`--plain` でスキルから直接呼べる

### 第5ラウンド（2026-09-05）

| # | 論点 | 決定 |
|---|---|---|
| Q32 | 配置 | 安定パス `~/.local/share/uskn-harness`（開発機は `~/repos/uskn-harness` への symlink、他端末は managed clone、`USKN_HARNESS_DIR` で上書き） |
| Q33 | プラグイン配布 | skills-dir 方式のみ。`~/.claude/skills/uskn-harness -> <harness>/plugins/uskn-harness`。marketplace は作らない（ADR-0002） |
| Q34 | hook の置き場 | 正本は `plugins/uskn-harness/hooks/scripts/`。トップレベル `hooks/` は他ツール向けアダプタのみ |
| Q35 | 自作スキルの導入 | `sync` が `skills/**/<name>` ごとに symlink。`npx skills` はサードパーティ専用 |
| Q36 | ブランチモデル上書き | AGENTS.md の `## Branch model` 見出し下の fenced yaml |
| Q37 | このマシンでの `sync` | 実行する。chezmoi 管理の同名スキルはスキップして警告 |
| Q38 | dotfiles PR | **1 本（PR #10）に積み、実用可能になるまでそこで管轄する**（推奨は分割だったがユーザー判断で一本化） |

前提（change を 2 つに分ける、`sync` 冪等、`pr` の意味論、エイリアス、bats、`npx skills` の使い方）はすべて承認。

## 14. Phase 2 の grilling

### 第6ラウンド（2026-09-05）

| # | 論点 | 決定 |
|---|---|---|
| Q39 | sessions repo | GitHub private `uskanda/ai-sessions` を作成し `~/.ai-sessions` に clone。commit と push は SessionEnd で自動（push 失敗は無視して次回再試行） |
| Q40 | journal の命名 | `~/.ai-sessions/<owner>__<repo>/<YYYY-MM-DD>-<HHMM>-<slug>.md`。slug はエージェントが付け、無ければ session id 先頭 8 桁 |
| Q41 | スケルトン | メタ、ユーザープロンプト各先頭 200 字、変更ファイル、期間中のコミット、使ったスキル。ツール出力とアシスタント本文は含めない |
| Q42 | 生成タイミング | Stop ごとに増分更新、SessionEnd は commit / push のみ（timeout 60 秒）。決定欄はセッション中 1 回だけ Stop を block して書かせる |
| Q43 | verify gate | 作業ツリーが変化したときだけ `make verify` → `pnpm run verify` / `npm run verify`。失敗は block、`stop_hook_active` で再ブロックしない、`USKN_SKIP_VERIFY=1` で回避 |
| Q44 | grilling ガード | uskn schema で `grilling` を proposal の前提に + PreToolUse Write/Edit で `grilling.md` 無しの成果物書き込みを deny |
| Q45 | cross-repo ガード | Write/Edit/NotebookEdit はルート外 deny（許可リストあり）。Bash は chezmoi と他 repo への git 操作を deny、外への書き込みは警告。`/allow-repo` はセッション限定 |
| Q46 | SessionStart 注入 | 同プロジェクトの直近 3 件の「タイトル、決定、次の一手」 |
| Q47 | Session トレーラ | `<repo-context>` に session 情報を載せ、`commit` スキルがトレーラを付ける |

前提（change 4 分割、schema の配置、grilling.md 形式、bash + jq / bats、サブエージェント除外、`recall`）はすべて承認。
