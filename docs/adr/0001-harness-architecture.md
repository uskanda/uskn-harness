# ADR-0001: ハーネス全体構成

- 状態：採用（2026-09-05）
- 決定者：uskanda（grilling 4ラウンドで確定。記録は `docs/proposal-2026-09.md` §10〜§12）
- 関連：後続ADRは本ADRの各節を差し替える形で書く

## 文脈

個人プロダクト群（monolith、uskn75-kbほか）でエージェントコーディングの作法がリポジトリごとに散らばっている。
仕様決定（OpenSpec + grilling）、TDD、検証、履歴、UIとライティングの指針を共通化し、
Claude Codeを主としつつ他のエージェントへ移せる形で持ちたい。2026年9月時点で標準になっているのは
AGENTS.md、Agent Skills（`SKILL.md`）、MCP。hookはイベント語彙が揃ったが設定形式は非互換。

## 決定

### 1. 原則
1. 正本は中立形式（`SKILL.md`、`AGENTS.md`、MCP、Google DESIGN.md）。ツール固有物は薄いラッパか生成物
2. 指針（guide）には検知（sensor）を対で付け、検知は可能な限り決定的な計算で行う
3. プロダクトリポジトリに置けるのは `AGENTS.md` `CLAUDE.md` `openspec/` `DESIGN.md` `PRODUCT.md` と検証規約。
   これは上限であって、全部置く義務ではない（`DESIGN.md` と `PRODUCT.md` はUIを持つプロダクトだけ。2026-09-05に明確化）。
   検証コマンドは `make verify` → `pnpm run verify` / `npm run verify` の規約で探し、無ければ警告のみ
4. 役割ごとに採用と代替をADRに残し、外部スキルとCLIは `deps.json` でピン止めする
5. 常時ロードは目次と規則だけ。手順はスキル、詳細は `references/` へ。環境から分かることは書かない
6. 作業ディレクトリ外のプロジェクトを直接編集しない。他リポジトリへの変更は別クローンからのPRか `docs/handoffs/` の手順書で渡す

### 2. 対象ツール
動作保証はClaude Codeのみ。Codex CLI、Gemini CLI、OpenCode向けにはアダプタの置き場を用意するが検証しない。

### 3. リポジトリ構成
GitHub private、`main` のみ、CalVerタグ。置くものは次のとおり。

- `skills/`: スキルの正本（英語）
- `templates/{repo,user,chezmoi}/`: プロダクトリポジトリ向け、ユーザー層向け、dotfilesのbootstrap向けの配布ファイル
- `schemas/uskn/`: OpenSpecのschema
- `plugins/uskn-harness/hooks/`: hook本体（scripts、tests、hooks.json）。他ツール向けアダプタは `hooks/adapters/<tool>/` に置く。必要が出た時点で作る（ADR-0002）
- `deps.json`: 外部スキルとCLIのピン
- `assets/voice/`: 文体サンプル
- `docs/{adr,handoffs}` と `docs/proposal-2026-09.md`: 決定、別セッション向けの手順書、調査とgrillingの記録
- `openspec/`: 本リポジトリ自身の運用
- `bin/uskn-harness`: installer（init / doctor / sync）

### 4. 配布
- スキル：`npx skills add uskanda/uskn-harness -g`。Claude Codeでは `~/.claude/skills/` へsymlink、名前はプレフィックスなし
- hook: Claude Codeプラグイン `uskn-harness`（marketplaceは本リポジトリ）。hook本体はbash + jq、テストはbats
- ランタイム：mise（NodeとPython）。shimsをzprofileに通し、非対話シェルのhookからも解決する
- マシン間：chezmoiのrun_onceが `uskn-harness sync` を呼ぶ。`~/.claude/skills` のハーネス由来symlinkは `.chezmoiignore`。dotfilesへの変更はすべてPR

### 5. 指示ファイルと言語
各リポジトリは `AGENTS.md` を正本、`CLAUDE.md` は `@AGENTS.md` とClaude固有の数行。ユーザー層は `templates/user/AGENTS.md` を
`~/.claude/CLAUDE.md` へ配置。スキル、hook、テンプレート、本リポジトリのAGENTS.mdは英語。チャット、コミット、PR、ADR、OpenSpec成果物は日本語。

### 6. ワークフロー
1. `/spec <idea>` がgrillingを回す（ラウンド形式。mattpocock/skillsの `grilling` を参照）。
2. 結果を `openspec/changes/<name>/grilling.md` に保存する。
3. proposal、design、specs、tasksを一括生成する（`--step` で段階生成）。
4. `/opsx:apply` をTDDで進め、Stop hookがverifyを実行する。
5. `/opsx:archive` でmain specsに反映する。

OpenSpecは `spec-driven` schemaを `uskn` にフォークし、`grilling` アーティファクトをproposalの前提に置く。
schemaはuser-levelの `~/.local/share/openspec/schemas/uskn/` に置く。
リポジトリ側は `openspec/config.yaml` の `schema: uskn` だけ。profileはexpanded。

### 7. hook（v1）
| イベント | 役割 |
|---|---|
| SessionStart | hosting（GitHub / GitLab）とブランチモデル（既定・統合・QA）を判定して注入。sessions リポジトリの直近要約を注入 |
| PreToolUse Write / Edit / NotebookEdit | プロジェクトルート外を拒否。許可リストは scratchpad、`~/.ai-sessions`、`~/.claude/projects/*/memory`、`/tmp`。`/allow-repo <path>` でセッション限定に解除 |
| PreToolUse Bash | `chezmoi apply|add`、他 repo への `git push` などの典型を拒否、他のパターンは警告。`openspec new change` / propose 前に grilling 成果物を確認 |
| PostToolUse Write / Edit | `openspec/` と `docs/` の `.md` に textlint |
| Stop | 作業ツリーに変更があれば verify。journal の決定的な部分を生成・更新し、決定欄が空なら 1 回だけ追記を促す。緊急回避は環境変数 1 つ |
| SessionEnd | journal を最終更新し、sessions リポジトリに commit して push する |

### 8. 既存スキルの移管
gitワークフロー系のスキルをハーネスへ移す。
対象はcommit、push、pr / mr、mr-main、mr-qa、rebase、merge-develop、switch-develop-branch。
cleanup-merged、pre-merge、fix-ci、release、nessun-dormaも移す。
`develop` / `main` / `qa` の固定は「自動検出と、AGENTS.md『ブランチ運用』節での上書き」に汎用化する。
判定はSessionStart hookが担う。
`pr`（引数でmain / qa）、`sync-base`、`switch-base` に統合する。
旧名は `disable-model-invocation: true` の1行エイリアスで残す。
プロジェクト履歴への言及（Issue番号など）は削除する。
chezmoi-merge、sync-claude-settings、set-workspace-theme、cleanupはdotfilesに残す。
`openspec-*` はCLI生成物に置き換える。

### 9. 方法論スキル
superpowersは丸ごと採用しない。forkするのは次の4つで、どれにもMIT表記を付ける。

- test-driven-development
- systematic-debugging
- verification-before-completion
- using-git-worktrees

mattpocock/skillsのgrilling、grill-me、handoff、writing-for-agentsは参照してピン止めする。
humanizer、agent-style、Impeccable、expo/skillsも同じ扱いにする。

### 10. 履歴
要約はsessionsリポジトリ（GitHub private `uskanda/ai-sessions`、`~/.ai-sessions`）にcommitとpushする。
ファイル名は `<project>/<日付>-<slug>.md`。
要約はbash + jqの決定的スケルトンに、変更があったセッションだけエージェントが「決定 / 未解決 / 次の一手」を追記する。
全文トランスクリプトは同配下でgitignore（ローカルのみ）。プロダクトのコミットに `Session:` トレーラ。検索はripgrep + `recall`。

### 11. UI とライティング
- UI: Google DESIGN.md形式（YAMLトークン + 根拠）を正本。Impeccableはコマンド（audit / critique / polishなど）のみ使い `init` は使わない。
  RN / ExpoはExpo公式skillsとDESIGN.mdのproseで補う。Anthropic frontend-designはフォールバック
- 日本語：textlint（preset-ja-technical-writing + preset-ai-writing）+ `ja-writing` スキル。英語：agent-styleの21ルール + humanizer。
  文体サンプルは `assets/voice/`。適用範囲はコミット、PR、仕様、ドキュメント、UI文言。文体基準はスキル作成時に短いgrillingで決める

### 12. 実装フェーズ
0. 骨格（本ADR、`openspec init`、GitHubリポジトリ）
1. installer、chezmoi連携（PR）、既存スキルの移管と汎用化、hosting hookの移管
2. `spec`、`verify`、`journal`、`recall`、cross-repoガード
3. ライティング、UI、方法論スキルのfork
4. `onboard-harness`、monolithとuskn75-kbへの導入

## 検討した代替案

| 論点 | 不採用案 | 理由 |
|---|---|---|
| SDD | Spec Kit、Kiro specs | ユーザー要件で OpenSpec 前提。OpenSpec は schema / profile / stores の拡張点と 40 ツール出力を持つ |
| 方法論 | superpowers を丸ごと採用 | SessionStart で独自の brainstorming → plan → execute を注入し、OpenSpec と計画が二重化する |
| 履歴 | claude-mem、episodic-memory | 常駐ワーカーや SQLite + 埋め込みは「ライトウェイト」要件に合わない。意味検索が必要になれば episodic-memory を追加 |
| UI | Impeccable の DESIGN.md 形式を正本 | Google 仕様と互換がなく Web 専用。トークンの機械可読性と lint を失う |
| 配布 | rulesync 系で各ツール向けファイルを生成 | 正本を AGENTS.md と SKILL.md に置けば生成は不要。Claude Code は `@AGENTS.md` で足りる |
| Node | nvm 継続 | 非対話シェル（hook）で解決できない。mise は shims で解決し Python も統合できる |
| 検証コマンド | `harness.yaml` 新設 | リポジトリに置くものを増やさず、人にも読める規約（`make verify`）で足りる |
| cross-repo | 指示のみ | ユーザー要件で制約として担保が必要。Write / Edit は確実に止められる |

## 結果

- 良い点：プロダクトリポジトリが軽い。スキルとhookが1か所に集まり、差し替えは `deps.json` とADRの更新で済む。仕様決定の履歴が `openspec/` とsessionsリポジトリに残る
- 引き受けるコスト：miseへの移行とdotfilesの変更（PR）。OpenSpec schemaはexperimentalで、CLI更新時に追従が要る。Claude Code以外は未検証のまま
- 後回し：Codex等の実機検証、episodic-memory、OpenSpec stores、intake tier、`nessun-dorma` の `/goal` ベース書き直し
