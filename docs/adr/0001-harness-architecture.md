# ADR-0001: ハーネス全体構成

- 状態: 採用（2026-09-05）
- 決定者: uskanda（grilling 4 ラウンドで確定。記録は `docs/proposal-2026-09.md` §10〜§12）
- 関連: 後続 ADR は本 ADR の各節を差し替える形で書く

## 文脈

個人プロダクト群（monolith、uskn75-kb ほか）でエージェントコーディングの作法が repo ごとに散らばっている。
仕様決定（OpenSpec + grilling）、TDD、検証、履歴、UI とライティングの指針を共通化し、
Claude Code を主としつつ他のエージェントへ移せる形で持ちたい。2026年9月時点で標準になっているのは
AGENTS.md、Agent Skills（`SKILL.md`）、MCP。hook はイベント語彙が揃ったが設定形式は非互換。

## 決定

### 1. 原則
1. 正本は中立形式（`SKILL.md`、`AGENTS.md`、MCP、Google DESIGN.md）。ツール固有物は薄いラッパか生成物
2. 指針（guide）には検知（sensor）を対で付け、検知は可能な限り決定的な計算で行う
3. プロダクト repo に置けるのは `AGENTS.md` `CLAUDE.md` `openspec/` `DESIGN.md` `PRODUCT.md` と検証規約。
   これは上限であって、全部置く義務ではない（`DESIGN.md` と `PRODUCT.md` は UI を持つプロダクトだけ。2026-09-05 に明確化）。
   検証コマンドは `make verify` → `pnpm run verify` / `npm run verify` の規約で探し、無ければ警告のみ
4. 役割ごとに採用と代替を ADR に残し、外部スキルと CLI は `deps.json` でピン止めする
5. 常時ロードは目次と規則だけ。手順はスキル、詳細は `references/` へ。環境から分かることは書かない
6. 作業ディレクトリ外のプロジェクトを直接編集しない。他 repo への変更は別クローンからの PR か `docs/handoffs/` の手順書で渡す

### 2. 対象ツール
動作保証は Claude Code のみ。Codex CLI、Gemini CLI、OpenCode 向けにはアダプタの置き場を用意するが検証しない。

### 3. リポジトリ構成
GitHub private、`main` のみ、CalVer タグ。置くものは次のとおり。

- `skills/`: スキルの正本（英語）
- `hooks/scripts/` と `hooks/adapters/`: hook 本体と、ツールごとの配線
- `templates/repo/` と `templates/user/`: プロダクト repo 向けとユーザー層向けの配布ファイル
- `schemas/uskn/`: OpenSpec の schema
- `plugins/uskn-harness/`: Claude Code プラグイン（hook のみ）
- `deps.json`: 外部スキルと CLI のピン
- `assets/voice/`: 文体サンプル
- `docs/{adr,handoffs,trends}`: 決定、他 repo への手順書、調査
- `openspec/`: 本 repo 自身の運用
- `bin/uskn-harness`: installer（init / doctor / sync）

### 4. 配布
- スキル: `npx skills add uskanda/uskn-harness -g`。Claude Code では `~/.claude/skills/` へ symlink、名前はプレフィックスなし
- hook: Claude Code プラグイン `uskn-harness`（marketplace は本 repo）。hook 本体は bash + jq、テストは bats
- ランタイム: mise（Node と Python）。shims を zprofile に通し、非対話シェルの hook からも解決する
- マシン間: chezmoi の run_once が `uskn-harness sync` を呼ぶ。`~/.claude/skills` のハーネス由来 symlink は `.chezmoiignore`。dotfiles への変更はすべて PR

### 5. 指示ファイルと言語
各 repo は `AGENTS.md` を正本、`CLAUDE.md` は `@AGENTS.md` と Claude 固有の数行。ユーザー層は `templates/user/AGENTS.md` を
`~/.claude/CLAUDE.md` へ配置。スキル、hook、テンプレート、本 repo の AGENTS.md は英語。チャット、コミット、PR、ADR、OpenSpec 成果物は日本語。

### 6. ワークフロー
1. `/spec <idea>` が grilling を回す（ラウンド形式。mattpocock/skills の `grilling` を参照）。
2. 結果を `openspec/changes/<name>/grilling.md` に保存する。
3. proposal、design、specs、tasks を一括生成する（`--step` で段階生成）。
4. `/opsx:apply` を TDD で進め、Stop hook が verify を実行する。
5. `/opsx:archive` で main specs に反映する。

OpenSpec は `spec-driven` schema を `uskn` にフォークし、`grilling` アーティファクトを proposal の前提に置く。
schema は user-level の `~/.local/share/openspec/schemas/uskn/` に置く。
repo 側は `openspec/config.yaml` の `schema: uskn` だけ。profile は expanded。

### 7. hook（v1）
| イベント | 役割 |
|---|---|
| SessionStart | hosting（GitHub / GitLab）とブランチモデル（既定・統合・QA）を判定して注入。sessions repo の直近要約を注入 |
| PreToolUse Write / Edit / NotebookEdit | プロジェクトルート外を拒否。許可リストは scratchpad、`~/.ai-sessions`、`~/.claude/projects/*/memory`、`/tmp`。`/allow-repo <path>` でセッション限定に解除 |
| PreToolUse Bash | `chezmoi apply|add`、他 repo への `git push` などの典型を拒否、他のパターンは警告。`openspec new change` / propose 前に grilling 成果物を確認 |
| PostToolUse Write / Edit | `openspec/` と `docs/` の `.md` に textlint |
| Stop | 作業ツリーに変更があれば verify。journal 未記録なら追記を促す。緊急回避は環境変数 1 つ |
| SessionEnd | journal の決定的スケルトンを生成し sessions repo に commit |

### 8. 既存スキルの移管
git ワークフロー系のスキルをハーネスへ移す。
対象は commit、push、pr / mr、mr-main、mr-qa、rebase、merge-develop、switch-develop-branch。
cleanup-merged、pre-merge、fix-ci、release、nessun-dorma も移す。
`develop` / `main` / `qa` の固定は「自動検出と、AGENTS.md『ブランチ運用』節での上書き」に汎用化する。
判定は SessionStart hook が担う。
`pr`（引数で main / qa）、`sync-base`、`switch-base` に統合する。
旧名は `disable-model-invocation: true` の 1 行エイリアスで残す。
プロジェクト履歴への言及（Issue 番号など）は削除する。
chezmoi-merge、sync-claude-settings、set-workspace-theme、cleanup は dotfiles に残す。
`openspec-*` は CLI 生成物に置き換える。

### 9. 方法論スキル
superpowers は丸ごと採用しない。fork するのは次の 4 つで、どれにも MIT 表記を付ける。

- test-driven-development
- systematic-debugging
- verification-before-completion
- using-git-worktrees

mattpocock/skills の grilling、grill-me、handoff、writing-for-agents は参照してピン止めする。
humanizer、agent-style、Impeccable、expo/skills も同じ扱いにする。

### 10. 履歴
要約は sessions repo（GitHub private `uskanda/ai-sessions`、`~/.ai-sessions`）に commit と push する。
ファイル名は `<project>/<日付>-<slug>.md`。
要約は bash + jq の決定的スケルトンに、変更があったセッションだけエージェントが「決定 / 未解決 / 次の一手」を追記する。
全文トランスクリプトは同配下で gitignore（ローカルのみ）。プロダクトのコミットに `Session:` トレーラ。検索は ripgrep + `recall`。

### 11. UI とライティング
- UI: Google DESIGN.md 形式（YAML トークン + 根拠）を正本。Impeccable はコマンド（audit / critique / polish など）のみ使い `init` は使わない。
  RN / Expo は Expo 公式 skills と DESIGN.md の prose で補う。Anthropic frontend-design はフォールバック
- 日本語: textlint（preset-ja-technical-writing + preset-ai-writing）+ `ja-writing` スキル。英語: agent-style の 21 ルール + humanizer。
  文体サンプルは `assets/voice/`。適用範囲はコミット、PR、仕様、ドキュメント、UI 文言。文体基準はスキル作成時に短い grilling で決める

### 12. 実装フェーズ
0. 骨格（本 ADR、`openspec init`、GitHub repo）
1. installer、chezmoi 連携（PR）、既存スキルの移管と汎用化、hosting hook の移管
2. `spec`、`verify`、`journal`、`recall`、cross-repo ガード
3. ライティング、UI、方法論スキルの fork
4. `onboard-harness`、monolith と uskn75-kb への導入

## 検討した代替案

| 論点 | 不採用案 | 理由 |
|---|---|---|
| SDD | Spec Kit、Kiro specs | ユーザー要件で OpenSpec 前提。OpenSpec は schema / profile / stores の拡張点と 40 ツール出力を持つ |
| 方法論 | superpowers を丸ごと採用 | SessionStart で独自の brainstorming → plan → execute を注入し、OpenSpec と計画が二重化する |
| 履歴 | claude-mem、episodic-memory | 常駐ワーカーや SQLite + 埋め込みは「ライトウェイト」要件に合わない。意味検索が必要になれば episodic-memory を追加 |
| UI | Impeccable の DESIGN.md 形式を正本 | Google 仕様と互換がなく Web 専用。トークンの機械可読性と lint を失う |
| 配布 | rulesync 系で各ツール向けファイルを生成 | 正本を AGENTS.md と SKILL.md に置けば生成は不要。Claude Code は `@AGENTS.md` で足りる |
| Node | nvm 継続 | 非対話シェル（hook）で解決できない。mise は shims で解決し Python も統合できる |
| 検証コマンド | `harness.yaml` 新設 | repo に置くものを増やさず、人にも読める規約（`make verify`）で足りる |
| cross-repo | 指示のみ | ユーザー要件で制約として担保が必要。Write / Edit は確実に止められる |

## 結果

- 良い点: プロダクト repo が軽い。スキルと hook が 1 か所に集まり、差し替えは `deps.json` と ADR の更新で済む。仕様決定の履歴が `openspec/` と sessions repo に残る
- 引き受けるコスト: mise への移行と dotfiles の変更（PR）。OpenSpec schema は experimental で、CLI 更新時に追従が要る。Claude Code 以外は未検証のまま
- 後回し: Codex 等の実機検証、episodic-memory、OpenSpec stores、intake tier、`nessun-dorma` の `/goal` ベース書き直し
