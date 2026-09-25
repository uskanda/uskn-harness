## Why

決定の記録は、変更ごとの `grilling.md` と `design.md`、ADR、コミットにすでに残る。
セッションjournalはそれと重なる。しかも端末ごとのローカルgitに閉じていて、ほかの端末からは引けない。
仕組みの維持には、Stop hookのblock、トランスクリプトの解析、SessionEndのcommit、sessionsリポジトリの管理が要る。
新しい仕組みは作らずに外し、hookとインストーラを軽くする。好みの記録はClaude Codeのauto memoryに任せる。

## What Changes

- **BREAKING** `journal` と `recall` のスキルを削除する
- **BREAKING** hookのjournal-recent.sh、journal-update.sh、journal-end.shを削除する。`hooks.json` からSessionStartとStopの該当項目、SessionEndの節を外す
- `<repo-context>` にsession行とトレーラの案内を出さない
- `commit` はSession trailerを付けず、常に `Co-Authored-By: Claude <noreply@anthropic.com>` を付ける。既存のコミットはそのまま
- `allow-repo` は `${CLAUDE_SESSION_ID}` の先頭8文字をsid8に使う。置換されないときは環境変数 `CLAUDE_CODE_SESSION_ID` から得る
- SessionStartとverify gateは、状態ディレクトリにjournal専用のファイル（`project`、`started`、`baseline-head`）を書かない
- `uskn-harness sync` は `~/.ai-sessions` を作らない。`doctor` は検査しない。write-guardとbash-guardの許可リストからも外す。既存のデータには触れない
- `sync` は、30日より古いセッションの状態ディレクトリを消す
- `sync` は、削除したスキルを指したまま先の無くなったsymlinkを `~/.claude/skills` から取り除く。`journal` と `recall` を各端末から外すため
- ADR-0004を足し、ADR-0001 §10（履歴）と §7のjournal関連の行を置き換える
- README、`docs/setup-new-machine.md`、ユーザー層の `CLAUDE.md`、プラグインのREADME、用語集からjournalの記述を外す

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

- `journal-context`: 要件をすべて削除し、能力ごと廃止する
- `journal-skeleton`: 要件をすべて削除し、能力ごと廃止する
- `journal-skill`: 要件をすべて削除し、能力ごと廃止する
- `journal-sync`: 要件をすべて削除し、能力ごと廃止する
- `recall-skill`: 要件をすべて削除し、能力ごと廃止する
- `harness-sync`: sessionsリポジトリの初期化を削除し、`--tools` と失敗の終了コードから外す。古いセッションの状態の削除、削除したスキルのsymlinkの除去、journalの置き場に触れない要件を足す
- `harness-doctor`: sessionsリポジトリの検査を削除する
- `write-guard`: 許可リストから `~/.ai-sessions` を外す
- `session-baseline`: 状態ディレクトリに書くファイルを `baseline` だけにする
- `allow-repo-skill`: sid8の出どころを `<repo-context>` からセッションIDに変える
- `git-workflow-skills`: Sessionトレーラの要件を削除し、Co-Authored-Byトレーラの要件を足す

## Impact

- スキル：`skills/journal/` と `skills/recall/` を削除する。`skills/allow-repo/SKILL.md` と `skills/ja-writing/SKILL.md` の例文を直す。
  `skills/git/commit/SKILL.md` は別の変更（fork-skills-model-effort）が書き換え中なので、そのarchive後に直す
- hook：`plugins/uskn-harness/hooks/` の下。
  `hooks.json`、`session-start.sh`、`session-baseline.sh`、`verify-gate.sh`、`allow-repo.sh`、`write-guard.sh`、`lib/common.sh` とbats。
  journal系の3本とそのbats、`tests/fixtures/transcript.jsonl` は削除する
- インストーラ：`bin/uskn-harness` と `bin/tests/uskn-harness.bats`
- 文書：`README.md`、`docs/setup-new-machine.md`、`templates/user/CLAUDE.md`。
  プラグインの `plugins/uskn-harness/README.md` と用語集の `openspec/glossary.yml` も直す。
  ADRは `docs/adr/0001-harness-architecture.md` に注記を足し、`docs/adr/0004-retire-session-journal.md` を新設する
- 各端末の `~/.ai-sessions` はハーネスの管理から外れて残る。消すかはユーザーが決める
- archiveの順序：`harness-sync` の差分は、fix-hook-bugsが足す要件「失敗の終了コード」を書き換える。
  `git-workflow-skills` の差分は、fork-skills-model-effortが書き換えるSessionトレーラの要件を削除する。
  そのため、この変更は2つのあとにarchiveする
