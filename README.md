# uskn-harness

個人プロダクト群で共用する、エージェントコーディング用ハーネス。
スキル、hook、テンプレート、配布用インストーラをこのリポジトリに集約する。
各プロダクトのリポジトリには `AGENTS.md` `CLAUDE.md` `openspec/` `DESIGN.md` `PRODUCT.md` だけを置く。

## 状態

Phase 4（`onboard-harness` とプロダクトリポジトリへの導入）まで完了。
monolithとuskn75-kbにはdraft PRを出してある。マージは他作業の目処が立ってから。
決定は [docs/adr/0001-harness-architecture.md](docs/adr/0001-harness-architecture.md) と [docs/adr/0002-plugin-distribution-via-skills-dir.md](docs/adr/0002-plugin-distribution-via-skills-dir.md) にある。
進行中のchangeは `openspec/changes/` を見る。

- `skills/git/`: gitワークフローのスキル11個（commit、push、pr、rebase、releaseほか）。旧名は1行のエイリアスで残す
- `plugins/uskn-harness/`: hookだけを載せたClaude Codeプラグイン。SessionStartで `<repo-context>`（hostingとブランチモデル）を注入する
- `skills/spec/`: `/spec <idea>` がgrillingを回し、`grilling.md` を残してからOpenSpec成果物を作る。schema `uskn`（`schemas/uskn/`）がgrillingをproposalの前提にする
- `skills/journal/` と `skills/recall/`: セッションごとのjournalをprivateリポジトリ `uskanda/ai-sessions` に貯める。事実はhook、判断はエージェントが書く。SessionEndでcommitとpushを行い、SessionStartで直近3件を注入する。コミットには `Session: <sid8>` トレーラが付く
- `skills/allow-repo/` とPreToolUse hook `write-guard` / `bash-guard`: ルート外への書き込みを止める。`chezmoi apply` と他リポジトリへのgit操作も止める。ユーザーが明示したときだけ `/allow-repo <path>` で解除する。解除はそのセッションに限る
- `skills/verify/` とStop hook `verify-gate`: セッションで作業ツリーが変わったとき検証規約を実行する。規約は `make verify`、無ければ `pnpm run verify` / `npm run verify`。失敗している間は終了させない。`USKN_SKIP_VERIFY=1` で回避できる
- `skills/ja-writing/` とPostToolUse hook `textlint-check`: 日本語を含むMarkdownを書くたびにtextlintが走る。設定は `skills/ja-writing/textlintrc.json`
- `skills/en-writing/`: 人が読む英語の文章にagent-styleの21ルールとhumanizerを当てる。エージェント向け文書は `writing-for-agents` に任せる
- `skills/ui-guidelines/` と `templates/repo/DESIGN.md`: UIの正本はGoogle DESIGN.md形式とPRODUCT.md。Impeccableは評価と改善のコマンドだけ使う
- `skills/test-driven-development/` ほか3件：obra/superpowersからforkした方法論スキル。TDD、系統的デバッグ、完了前検証、git worktreeを扱う
- `skills/onboard-harness/` と `uskn-harness onboard-check`: プロダクトリポジトリに何を置くかを決めてdraft PRで渡す。点検は読み取り専用
- `docs/handoffs/`: 別セッション向けの手順書。他リポジトリの導入手順（draft PRの本文と同じ内容）と、このリポジトリでの引き継ぎ

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
make verify       # openspec validate、shellcheck、bats、SKILL.md 検査、claude plugin validate、textlint、design.md lint
```

CI（`.github/workflows/verify.yml`）はmainへのpush、pull request、手動実行で `make verify VERIFY_STRICT=1` を走らせる。
strictでは道具が無いチェックはskipではなく失敗になる。道具は `uskn-harness sync --tools` で、ローカルと同じピンから入れる。
