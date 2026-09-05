## Context

- 既存スキルは `~/.claude/skills`（chezmoi 管理、日本語本文）にあり、`develop` / `main` / `qa` の固定名と、GitLab の MR 手順で得た運用知識（auto-merge の即時マージ事故、ソースブランチ削除の既定 ON への対処）を持つ。運用知識は残し、固定名と履歴だけを外す
- `claude-hosting-hook` は bash 約 200 行で、stdin JSON の `cwd` → remote URL → gh / glab 設定 → CI ファイルの順に判定し、`--plain` を持つ。この構造を引き継ぐ
- Claude Code の skills-dir プラグインは symlink でも hook 込みで読み込まれる（sandbox で検証済み、ADR-0002）。hook のコマンドは `${CLAUDE_PLUGIN_ROOT}` 起点。プラグイン外へ向く symlink は無視される
- hook は非対話シェルで動く。Node は保証されないので bash + jq、jq も無い環境では簡易パースに落とす
- 動作保証は Claude Code のみ（Q1）。他ツール向けアダプタはこの change では作らない

## Goals / Non-Goals

**Goals:**
- スキル本文からプロジェクト固有の前提を取り除き、`branch-model` の解決結果だけに依存させる
- hosting とブランチモデルの判定を 1 か所（`session-start.sh`）に集約し、スキルとテストの両方から呼べるようにする
- TDD: hook スクリプトは bats のテストを先に書く

**Non-Goals:**
- `sync` によるスキルの導入、dotfiles からの撤去（`harness-installer` change）
- `nessun-dorma` の `/goal` ベースの書き直し、`spec` / `verify` / `journal` スキル（Phase 2）
- Codex / Gemini 向けアダプタ

## Decisions

1. **単一スクリプト `plugins/uskn-harness/hooks/scripts/session-start.sh`**。引数なしで `<repo-context>` ブロックを標準出力に出し、`--plain hosting` / `--plain branches` / `--json` で機械可読出力に切り替える。ライブラリ分割はしない（読み込み経路が 1 つで済み、テストは CLI 経由で書ける）。代替: 関数ライブラリ + 薄いエントリ。テストの都合以外に利点が無いので見送り
2. **ブランチ検出はローカルの remote-tracking ref だけを見る**（`refs/remotes/origin/HEAD`、`refs/remotes/origin/<name>`）。ネットワークに出ない（SessionStart の遅延を避ける）。`origin/HEAD` が無ければ `origin/main` → `origin/master` → ローカル `main` / `master` の順で default を決める。代替: `git ls-remote`。毎セッション数百 ms〜数秒かかるので不採用
3. **AGENTS.md の上書きは awk のステートマシンで拾う**。`^## Branch model` を見つけたら次の fenced block（言語 `yaml`）内の `key: value` 行だけを読む。yq は要求しない。値は前後の空白と引用符を落とす。`qa: none` を「無し」とする
4. **出力は英語の短い構造化ブロック**（`<repo-context>` … `</repo-context>`）。中身は hosting（platform, CLI, 用語, 根拠）とブランチモデル（各値と根拠）、そして「スキルはこの値を使い再判定しない」の 1 文。旧 hook は日本語だったが、スキル本文が英語になるので揃える。エージェントのチャット言語はユーザー層の指示で決まり、この出力には影響されない
5. **スキルの文脈取得は 2 段**。まず `<repo-context>` を使い、無ければ `"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/session-start.sh" --plain branches` を実行する。それも無ければスキル内に書いた最小の git コマンドで default / integration を推定する。代替: スキルごとに判定ロジックを持つ。重複と不一致の元なので不採用
6. **`pr` は 1 スキルに統合し、引数で分岐**。`$ARGUMENTS` が空 → integration 向け（auto-merge）、default と一致かつ integration ≠ default → リリース PR（source = integration、タイトル `<default> YYYYMMDD HH:MM` JST）、qa と一致 → QA PR（ソースブランチ保持、GitLab では API で `remove_source_branch=false` を設定して検証してからマージ）、それ以外のブランチ名 → そのブランチ向けの通常 PR（auto-merge あり）。CI 待ちのポーリング（最大 3 分）と即時マージ検出は旧 `mr` の手順をそのまま残す
7. **`cleanup-merged` は git alias に依存しない**。旧スキルは `git cleanup-merged` という alias を前提にしていたが、ハーネス外の設定に依存するので `git branch --merged origin/<integration>` を使って一覧と削除を行う
8. **エイリアスは 1 行本文 + `disable-model-invocation: true`**。`mr` → `pr`、`mr-main` → `pr <default>`、`mr-qa` → `pr <qa>`、`merge-develop` → `sync-base`、`switch-develop-branch` → `switch-base`。エイリアス本文は「Run the Skill tool with `pr`, passing the repository's default branch as the argument」のように値ではなく役割で書く
9. **スキルの言語**: 本文英語。生成物の言語は「Follow the language policy in the user or repository instructions; default to Japanese」と書き、値はハードコードしない
10. **テスト**: `plugins/uskn-harness/hooks/tests/session-start.bats`。一時ディレクトリに bare の origin と clone を作り、remote URL、ブランチの有無、AGENTS.md の内容、`--plain` / `--json`、非 git ディレクトリ、jq の無い PATH を検証する。`make verify` が `bats` を実行する

## Risks / Trade-offs

- [`origin/HEAD` が無い clone（`git init` + `remote add`）] → default の段階的フォールバック。根拠を出力に含めるので誤判定が見える
- [AGENTS.md の yaml が壊れている] → 読めた行だけ採用し、残りは自動検出。壊れている旨を出力に添える
- [skills-dir プラグインの `${CLAUDE_PLUGIN_ROOT}` が symlink パスになる] → スクリプトは自身の位置に依存しない（`$0` の dirname を使わず、hooks.json から絶対パスで呼ぶ）ので影響なし
- [旧スキルと新スキルが `~/.claude/skills` に併存する期間] → 同名は `sync` がスキップし、dotfiles PR #10 の撤去後に入れ替わる。それまで Claude は chezmoi 版を使う
- [英語本文への書き換えで手順の細部が落ちる] → 旧スキルの手順を 1 対 1 で対応させ、削るのは固定名と履歴だけにする。テストできない部分はレビューで担保

## Migration Plan

1. 本 change を実装し、`make verify` と sandbox の `claude plugin details` で hook を確認する
2. `harness-installer` の `sync` でこのマシンに symlink を入れる（同名はスキップ）
3. dotfiles PR #10 で旧スキルと `claude-hosting-hook` を撤去し、`chezmoi apply` 後に `sync` を再実行する
4. 問題があれば PR #10 を revert し、旧スキルに戻す（新スキルは symlink なので `sync --remove` で消せる）
