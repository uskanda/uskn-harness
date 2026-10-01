## Why

仕様PRができても、実装を進めるには人がセッションを開き、`/opsx:apply` を走らせ、結果を見て直させる往復が要る。
`docs/loop-engineering-2026-09.md` の段階1として、実装役と監査役を完了基準か停止条件に達するまで交互に動かすループ本体を作る。段階1では、ループは手元から手動で起動する。
監査役を実装役から分け、完了基準の土台を計算的センサーに置くのは、自己評価と会話だけを読む判定が甘くなるという調査の結果による。

## What Changes

- 新しいコマンド `uskn-loop` を `bin/uskn-loop` に追加する。補助ファイル（実装役と監査役への指示、判定のJSON Schema、共通の関数）は最上位の `loop/` に置く。実装はbashとjq
- `uskn-loop run <PR/MR>` は、1つの仕様PRについて、ラウンドごとに実装役、計算的センサー、監査役を順に動かす。完了基準を満たすか停止条件に達するまで繰り返す
- 受け付けるのは、4条件を満たすGitHubのPRとGitLabのMRである。条件は、openであること、forkでないこと、作成者が `gh` / `glab` のユーザーであること、archiveされていないchangeを1つだけ追加していることである
- 作業は手元のクローンの `.claude/worktrees/loop-pr-<番号>` で行い、完了したら消す
- 状態（ラウンドごとの判定、費用の見積もり、ログ、ロック）を状態ディレクトリの下に置き、中断後の再実行で続きから始める。`--reset` で最初からやり直す
- 実装役は無人の `claude -p` として、autoの権限モードと `--permission-prompts none` で動く。1ラウンド目は `/opsx:apply <change>`、2ラウンド目以降は指摘を渡して直させる
- 計算的センサーは、検証規約、`openspec validate --strict`、tasks.mdの完了、基底ブランチとの差分の検査である
- 監査役はOpus 5.5（effort high）の別の `claude -p` で、読み取りとBashだけを使い、4つの欄を持つJSONで判定を返す
- 停止条件は、5ラウンド、1回ごとの費用と時間の上限、PRごとの費用の合計、2ラウンド続けての進展なし、pushの拒否、基底ブランチとの衝突である
- ラウンドごとにpushし、PRに1つの進捗コメントを日本語で書き換える。完了したらdraftを解除し、止めたらdraftのまま理由を知らせる
- `uskn-harness sync` が `~/.local/bin/uskn-loop` を張り、`doctor` がその向き先を検査する
- `spec-pr` が作る仕様PRの本文の進め方に、`uskn-loop run <番号>` の行を足す。スキルが名指しするコマンドの実在を確かめるbatsのテストは、リポジトリの `bin/` のコマンドも認めるようにする
- ADR-0006に、ループをハーネスに置くこと、プロダクトリポジトリに何も足さないこと、段階2ではサーバー単位のウォッチャーにすることを記録する

## Capabilities

### New Capabilities

- `loop-run`: `uskn-loop run` の受け付け条件、作業場所、状態と再開、ラウンドの流れ、停止条件、push、完了時と停止時のPRの扱い
- `loop-criteria`: 完了基準。計算的センサーと、監査役の道具、判定の形、作業ツリーの復元
- `loop-progress-comment`: PRごとに1つの進捗コメントの形式と、完了時と停止時のコメント

### Modified Capabilities

- `harness-sync`: 実行ファイルの公開に `~/.local/bin/uskn-loop` を加える
- `harness-doctor`: 検査項目に `~/.local/bin` の実行ファイルのsymlinkを加える
- `verify-fast`: `bin/uskn-loop` と `loop/` の変更で `bin/tests/uskn-loop.bats` を実行する
- `spec-pr-skill`: 仕様PRの本文の進め方にループでの実装を加える

## Impact

- 新規：`bin/uskn-loop`、`loop/`（指示、JSON Schema、共通の関数）、`bin/tests/uskn-loop.bats` と偽物の `claude`、`gh`、`glab`
- 変更：`bin/uskn-harness`（syncとdoctorのリンク）と `bin/tests/uskn-harness.bats`
- 変更：`Makefile`（verify-fastのテストの選択）と `bin/tests/makefile.bats`
- 文書：`docs/adr/0006-loop-runner.md`、`AGENTS.md` のLayout表、`README.md`
- 依存：`claude`（`-p`、`--json-schema`、`--max-budget-usd`）、`gh`、`glab`、jq。プロダクトリポジトリには何も足さない
- 前提：仕様PRは `add-spec-pr` の `spec-pr` が作る。`spec-pr-skill` の差分があるので、`add-spec-pr` を先にarchiveする
- 変更：`skills/spec-pr/SKILL.md`、`bin/tests/spec-pr-skill.bats`、`bin/tests/skill-commands.bats`
