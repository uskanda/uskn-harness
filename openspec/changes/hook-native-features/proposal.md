## Why

hookは、Claude Codeが後から備えた仕組みを使っていない。そのため、どのファイルを書いても全部のhookが起動する。
Stopのたびに約60秒の `make verify` が走り、blockのあとの再試行は検証されない。
worktreeに入ったセッションでは、ガードが自分の作業場所への書き込みを拒否することがある。
スキルは補助スクリプトを長いパスで呼んでいる。fix-hook-bugsの残課題（verify gateの状態ファイルをエージェントが書けること）もここで閉じる。

## What Changes

- `hooks.json` のtextlint-checkとterms-checkに `if` を付け、`**/*.md` の書き込みだけで起動させる。grilling-guardは `**/openspec/changes/**` に限る。スクリプトの中の絞り込みは、`if` を解さない版のために残す
- verify gateは、`Makefile` に `verify-fast` があればそれを使い、無ければ従来どおり `verify` を使う
- ハーネスの `Makefile` に `verify-fast` を足す。変更された文書のtextlintとterms、変更されたスクリプトのshellcheck、関わるbatsだけを走らせる。フルの `verify` はCIとarchive-pushで回す
- verify gateは `stop_hook_active` のときに黙るのをやめる。失敗が続く間は1ターンに3回までblockし、そのあとは失敗したままである旨を返して終わらせる
- ガードのルートを、`CLAUDE_PROJECT_DIR` と、同じリポジトリのcheckout（worktree）であるときの `cwd` のgitルートにする。別のリポジトリへ `cd` してもルートは広がらない。verify gate、textlint-check、terms-checkは `cwd` のgitルートで動く
- verify gateの状態ファイル（`baseline`、`verified`、`verify-blocks`）を、許可ファイルと同じくエージェントのWrite、Edit、Bashから守る
- プラグインに `bin/` を足し、スキルが長いパスで呼んでいた `session-start.sh` と `terms-check.sh` を短いコマンドにする。gitスキルとaudit-writingスキルはそれを呼ぶ。ADR-0002の「skills-dirプラグインは `bin/` 非対応」を直す
- terms-checkとtextlint-checkのhookは `.markdown` を対象から外す（`if` の `**/*.md` に揃える）

## Capabilities

### New Capabilities

- `verify-fast`: ハーネス自身の `Makefile` の、変更に関わる検査だけを走らせる速い検証

### Modified Capabilities

- `verify-gate`: 検証規約の探索に `verify-fast` を加え、`stop_hook_active` による省略を1ターン3回のblockの上限に置き換える
- `write-guard`: ルートを2つにし、verify gateの状態ファイルへの書き込みを拒否する
- `bash-guard`: ルートを2つにし、verify gateの状態ファイルを名指しや書き込み先とするコマンドを拒否する
- `claude-plugin-packaging`: hookの `if` による起動条件と、スキル向けの短いコマンド（`bin/`）を定める
- `textlint-hook`: 実行条件を作業ディレクトリ配下の `.md` にし、設定を探す場所を `cwd` のgitルートにする
- `terminology-guard`: hookの対象を `.md` に限り、用語集と名前の照合に `cwd` のgitルートを使う
- `git-workflow-skills`: ブランチモデルの取得に短いコマンドを使う

## Impact

- hook：`plugins/uskn-harness/hooks/hooks.json` と `lib/common.sh`。
  `hooks/scripts/` の `verify-gate.sh`、`write-guard.sh`、`bash-guard.sh`、`textlint-check.sh`、`terms-check.sh`
- プラグイン：`plugins/uskn-harness/bin/`（新規）、`plugin.json` の説明、`plugins/uskn-harness/README.md`
- 検証：`Makefile` の `verify-fast` と `SCRIPT_DIRS`
- テスト：`plugins/uskn-harness/hooks/tests/` と `bin/tests/` のbats
- スキル：`skills/audit-writing` と、`skills/git/` の8つ。
  `cleanup-merged`、`fix-ci`、`pr`、`push`、`rebase`、`release`、`switch-base`、`sync-base`
- 文書：ADR-0002への注記と、新しいADR-0005。用語集 `openspec/glossary.yml` の「verify gate」の定義
- 触らないもの：journal系のhookとスキル、`AGENTS.md`、`templates/`、`deps.json`。
  スキルの `skills/allow-repo`、`skills/verify`、`skills/archive-push`、`skills/git/commit`
- この変更はfix-hook-bugsの上に積む。同じ要件を変えるので、fix-hook-bugsを先にarchiveする
