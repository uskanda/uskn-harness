# uskn-harness

個人プロダクト群で共用する、エージェントコーディング用ハーネス。
スキル、hook、テンプレート、配布用インストーラをこのリポジトリに集約する。
各プロダクトのリポジトリには、規約が求めるファイルだけを置く。

## 目指すもの

プロダクトごとに散らばるエージェントの作法を1か所に集め、どのリポジトリでも同じ手順で開発できる状態にする。
狙いは4つ。

- 正本を中立形式で持つ。スキル、`AGENTS.md`、OpenSpecが正本で、Claude Code向けの配線は薄いラッパにとどめる。ツールを替えても中身が残る
- 指針にはセンサーを付ける。守ってほしい決まりは、hookとlintとテストで機械的に確かめる。人の記憶に頼らない
- 各リポジトリには規約が求めるファイルだけを置く。残りはインストーラが配る
- 決定を残す。仕様はgrillingで決め、ADRとOpenSpecのarchiveに理由ごと残す。同じ議論を繰り返さない

## 機能

| 領域 | 実装 | センサー |
|---|---|---|
| 配布と導入 | `bin/uskn-harness`（sync / doctor / onboard-check）、`templates/`、`deps.json` のピン、`plugins/uskn-harness` | `uskn-harness doctor`、bats |
| 仕様づくり | `skills/spec/` がgrillingを回し、schema `uskn` がgrillingをproposalの前提にする | PreToolUse hook `grilling-guard` |
| 実装と検証 | `skills/verify/`、obra/superpowersからforkした方法論スキル4件（TDD、系統的デバッグ、完了前検証、worktree） | Stop hook `verify-gate`、`make verify`、CI |
| git運用 | ワークフローのスキル11個（commit、push、pr、rebase、releaseほか）。旧名は1行のエイリアスで残す | SessionStart hookが `<repo-context>` を注入する |
| 記録 | セッションjournalをprivateリポジトリ `uskanda/ai-sessions` に貯める。`skills/journal/` と `skills/recall/` | Stop hookが事実を書き、決定欄が空なら1度だけ促す |
| 安全 | `skills/allow-repo/`。ルート外への書き込み、`chezmoi apply`、他リポジトリへのgit操作を止める | PreToolUse hook `write-guard` と `bash-guard` |
| 文章 | `skills/ja-writing/`（JTF準拠の表記、成果物ごとの文体）、`skills/en-writing/`（agent-styleとhumanizer） | PostToolUse hook `textlint-check`、`make verify` |
| 用語 | 用語集 `openspec/glossary.yml`。名前の出所を3つに限る。`skills/audit-writing/` が既存リポジトリを一括で直す | PostToolUse hook `terms-check`、`make verify` |
| UI | `skills/ui-guidelines/` と `templates/repo/DESIGN.md`。正本はGoogle DESIGN.md形式とPRODUCT.md | `designmd lint` |

使ううえでの要点は3つ。

- センサーの回避はその場限りにする。`USKN_SKIP_VERIFY`、`USKN_SKIP_TEXTLINT`、`USKN_SKIP_TERMS`、`USKN_SKIP_JOURNAL` を1にすると、それぞれの検査を飛ばせる
- コミットには `Session: <sid8>` トレーラが付く。`recall <sid8>` で当時の決定に戻れる
- プロダクトリポジトリへの変更は、別クローンから出すpull requestで渡す。作業ツリーは直接触らない

## 状態

ハーネス本体はひととおり動いている。`make verify` とCIが通り、`uskn-harness doctor` は0 problem。
monolithへの導入はマージ済み。uskn75-kbはpull requestが開いたまま。
決定は [docs/adr/0001-harness-architecture.md](docs/adr/0001-harness-architecture.md) と [docs/adr/0002-plugin-distribution-via-skills-dir.md](docs/adr/0002-plugin-distribution-via-skills-dir.md) にある。
進行中のchangeは `openspec/changes/` を見る。

## hook の発火を確かめる

Stop hookは応答が正常に終わったときだけ走る。利用上限で切れたターンや、ユーザーが中断したターンでは走らない。
SessionEndはアプリがセッションを閉じたときに走る。デスクトップアプリではセッションが数時間開いたままになる。
走ったかどうかは2か所で分かる。

- 状態ディレクトリ `~/.local/state/uskn-harness/sessions/<session_id>/`。SessionStartが `baseline` を、Stopが `transcript` と `journal` を、verify gateが `verify.log` を書く
- トランスクリプト `~/.claude/projects/<cwd>/<session_id>.jsonl` の `stop_hook_summary` 行。Stop hookが走るたびに1行増える

まだ1ターンも終わっていないセッションでjournalが要るときは、`journal-update.sh --session <sid8> --ensure` で先に作れる。

## 読む順番

1. [AGENTS.md](AGENTS.md): エージェント向けの入口と制約
2. [docs/adr/0001-harness-architecture.md](docs/adr/0001-harness-architecture.md): 全体構成と決定
3. [docs/proposal-2026-09.md](docs/proposal-2026-09.md): 2026年9月時点のトレンド調査とgrillingの記録

## 導入

新しいマシンではdotfilesを適用すると、run_onceがmiseを入れて `~/.local/share/uskn-harness` を用意する。続けて `uskn-harness sync` が走る。
OSごとの手順と確認方法は [docs/setup-new-machine.md](docs/setup-new-machine.md) にある。
このcheckoutがある開発機では、次のコマンドを使う。

```bash
~/repos/uskn-harness/bin/uskn-harness sync --dry-run   # 予定を確認
~/repos/uskn-harness/bin/uskn-harness sync             # 参照点、mise、npm の CLI、symlink、ユーザー層 CLAUDE.md
uskn-harness doctor                                    # 状態レポート。問題があれば終了コード 1
```

`sync` は最初にcheckoutをfast-forwardする。cleanでfast-forwardできるときだけで、`--no-pull` で止められる。
`sync` は冪等で、既存の実ディレクトリ（chezmoi管理のスキルなど）は `conflict` として触らない。
`sync --remove` でハーネス由来のsymlinkと管理コピーだけを取り除ける。

## 開発

```bash
mise install      # Node 24、bats、shellcheck（mise.toml）
make verify       # openspec validate、shellcheck、bats、SKILL.md 検査、claude plugin validate、textlint、design.md lint、terms-check
```

CI（`.github/workflows/verify.yml`）はmainへのpush、pull request、手動実行で `make verify VERIFY_STRICT=1` を走らせる。
strictでは道具が無いチェックはskipではなく失敗になる。道具は `uskn-harness sync --tools` で、ローカルと同じピンから入れる。
