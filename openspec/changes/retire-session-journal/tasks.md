## 1. hookのテストを先に書く

- [x] 1.1 `session-start.bats` のsession行のテストを、hookモードの出力にsession行とトレーラの案内が無いことを確かめるテストに置き換える。変更前のスクリプトで失敗することを確かめる
- [x] 1.2 `session-baseline.bats` で、`baseline` だけが作られ、`project`、`started`、`baseline-head` が無いことを確かめる。変更前のスクリプトで失敗することを確かめる
- [x] 1.3 `verify-gate.bats` の `baseline` 欠落のテストに、`project` と `started` が作られないことの判定を足す。変更前のスクリプトで失敗することを確かめる
- [x] 1.4 `write-guard.bats` の許可リストのテストから `~/.ai-sessions` を外し、`~/.ai-sessions` への書き込みが拒否されるテストを足す。変更前のスクリプトで失敗することを確かめる
- [x] 1.5 `allow-repo.bats` にテストを2つ足す。`--session` が無いか空のとき、`CLAUDE_CODE_SESSION_ID` の先頭8文字を使う。どちらも無いときは終了コード2で止まる。変更前のスクリプトで失敗することを確かめる

## 2. hookを直す

- [x] 2.1 `hooks.json` から、SessionStartのjournal-recent.sh、Stopのjournal-update.sh、SessionEndの節を外す。`claude plugin validate --strict` が通ることを確かめる
- [x] 2.2 hookのjournal-recent.sh、journal-update.sh、journal-end.shとそのbatsを削除する。`tests/fixtures/transcript.jsonl` も削除する。残りのbatsが通ることを確かめる
- [x] 2.3 `session-start.sh` から `session_id` の読み取りとsession行の出力を外す。1.1が通ることを確かめる
- [x] 2.4 `session-baseline.sh` が `baseline` だけを書くようにし、先頭のコメントを直す。1.2が通ることを確かめる
- [x] 2.5 `verify-gate.sh` の `baseline` 欠落時の記録を `baseline` だけにする。ほかの判定には触れない。1.3が通ることを確かめる
- [x] 2.6 `lib/common.sh` から `USKN_SESSIONS`、`sid8`、`project_key`、`to_local_stamp`、`now_iso` を外す。`path_allowed` の `~/.ai-sessions` も外す。`session_dir_for_prefix` は残す。1.4と既存のbatsが通ることを確かめる
- [x] 2.7 `allow-repo.sh` に `CLAUDE_CODE_SESSION_ID` の代替を足し、エラーの文言からsession行への言及を外す。1.5が通ることを確かめる
- [x] 2.8 `write-guard.sh` の先頭のコメントから `~/.ai-sessions` を外す。`make verify` のshellcheckが通ることを確かめる

## 3. インストーラ

- [x] 3.1 `bin/tests/uskn-harness.bats` の `setup` で、状態ディレクトリを偽の場所に向ける（`XDG_STATE_HOME` と `USKN_STATE_DIR`）。`~/.ai-sessions` を前提にした判定を、作られないことと既存のものが変わらないことの判定に置き換える
- [x] 3.2 `uskn-harness.bats` に、古いセッションの状態の削除のテストを足す。40日前のものだけが消え、中に新しいファイルがあるものと昨日のものは残り、`--dry-run` と `--tools` では消えないこと。変更前のスクリプトで失敗することを確かめる
- [x] 3.3 `uskn-harness.bats` に、削除したスキルのsymlinkの除去のテストを足す。ハーネスの中を指す先の無いsymlinkだけが消え、ハーネスの外を指すものは残ること。変更前のスクリプトで失敗することを確かめる。統合のときに `retire-obsolete-skills` の実装へ一本化し、テストはそちらの関数を通す形で残した
- [x] 3.4 `doctor` がsessionsリポジトリを報告しないことのテストを足す
- [x] 3.5 `bin/uskn-harness` から `SESSIONS_DIR`、`ensure_sessions_repo`、`doctor` の検査、usageの6bを外す。古いセッションの状態の削除と、先の無いsymlinkの除去を足す。3.1〜3.4が通ることを確かめる

## 4. スキル

- [x] 4.1 `skills/journal/` と `skills/recall/` を削除する。`make verify` の `verify-skills` が通ることを確かめる
- [x] 4.2 `skills/allow-repo/SKILL.md` の手順を、`${CLAUDE_SESSION_ID}` の先頭8文字を渡す形にする。置換されないときは `CLAUDE_CODE_SESSION_ID` を読むと書く。`<repo-context>` への言及が無いことを `grep` で確かめる
- [x] 4.3 `skills/ja-writing/SKILL.md` の例文からjournalを外す。直す前の文でtextlintの指摘が4件出ることを確かめる
- [x] 4.4 `skills/git/commit/SKILL.md` のSession trailerの規則を外す。代わりに、常に `Co-Authored-By: Claude <noreply@anthropic.com>` を付ける規則にする。`grep` でSession trailerの記述が無いことを確かめる（fork-skills-model-effortのarchive後に行う）

## 5. 文書と仕様

- [x] 5.1 `README.md` の記録の行、`USKN_SKIP_JOURNAL`、Sessionトレーラと `recall` の要点、hookの発火の節を直す。textlintとterms-checkが通ることを確かめる
- [x] 5.2 `docs/setup-new-machine.md` からsessionsリポジトリの記述を外し、残った `~/.ai-sessions` はユーザーが消してよいと書く。textlintが通ることを確かめる
- [x] 5.3 `templates/user/CLAUDE.md` からjournalの行を外す。60行以内のテストが通ることを確かめる
- [x] 5.4 `plugins/uskn-harness/README.md` のhookの一覧と、hookの発火の確かめ方を直す
- [x] 5.5 `docs/adr/0004-retire-session-journal.md` を書き、ADR-0001の §7と §10に置き換えの注記を足す。textlintが通ることを確かめる
- [x] 5.6 `openspec/specs/session-baseline/spec.md` のPurposeからjournalを外す。用語集の項目の入れ替えと一般語の追加（済み）を含め、terms-checkが通ることを確かめる

## 6. 検証

- [x] 6.1 `journal`、`recall`、`ai-sessions`、`sid8`、`Session:` を `grep` する。残るのは次だけであることを確かめる。アーカイブ、記録としての文書、この変更と並行する変更の成果物、archiveで差分が当たるmain spec、`commit` スキル（4.4）
- [x] 6.2 `make verify` と `openspec validate retire-session-journal --strict` が通ることを確かめる
- [ ] 6.3 archiveはfix-hook-bugsとfork-skills-model-effortのあとに行う。`openspec validate` が報告する `harness-sync` のMODIFIEDの情報は、fix-hook-bugsのarchive後に消えることを確かめる。
  scratchpadのコピーでは、fix-hook-bugsのあとにこの変更をarchiveでき、journal系の5つの能力のspecが消えることを確かめた
