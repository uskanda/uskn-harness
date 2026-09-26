## 1. ルートを2つにする

- [x] 1.1 `common.bats` に `project_roots` と `work_root` のテストを足し、失敗を確認する。場合は4つ。`CLAUDE_PROJECT_DIR` と `cwd` のgitルートの両方、同じときの1行、どちらも無いときの `cwd`、複数のルートでの `path_allowed`
- [x] 1.2 write-guardとbash-guardのテストに、ルートの外のworktreeの場合を足す。書き込みとcommitは黙り、3つ目のリポジトリは拒否される。失敗を確認する
- [x] 1.3 textlint-checkとterms-checkのテストに、worktreeにだけある `.textlintrc.json` と用語集の語が使われる場合を足す。失敗を確認する
- [x] 1.4 `lib/common.sh` に `project_roots` と `work_root` を足し、`path_allowed` をルートの一覧で判定させる。ガードは `project_roots`、検査は `work_root` を使う。1.1〜1.3と既存のテストが通ることを確認する
- [x] 1.5 `git worktree add` で作った本物のworktreeで、ルートの外のworktreeのテストを書き直す。別のリポジトリへ移った `cwd` のテストを足す。write-guardのWriteと、bash-guardのgitの書き込みが拒否される。ルートの下のディレクトリのテストも足し、失敗を確認する
- [x] 1.6 `project_roots` が `cwd` のgitルートを加えるのを、同じgit common dirのときだけに限る。読めないときは加えない。1.5と既存のテストが通ることを確認する

## 2. verify gateの状態ファイルを守る

- [x] 2.1 write-guardのテストを足し、失敗を確認する。`baseline`、`verified`、`verify-blocks` へのWriteとEditは拒否する。状態ディレクトリを許可したあとも拒否し、`verify.log` は黙る
- [x] 2.2 `lib/common.sh` に状態ファイルの判定を足し、write-guardで解除できない拒否にする。2.1が通ることを確認する
- [x] 2.3 bash-guardのテストを足し、失敗を確認する。拒否するのは、`verified` へのリダイレクト、セッションのディレクトリの `rm -rf` と `cp`、状態ディレクトリの上位の `rm -rf`、`cat` での名指し。`verify.log` の `tail` と `cp x ~/` は黙る
- [x] 2.4 bash-guardに状態ファイルの文字列の照合、書き込み先の判定、消す操作の判定を足す。2.3と既存のテスト、shellcheckが通ることを確認する

## 3. verify gateの再検証と上限

- [x] 3.1 `verify-gate.bats` の `stop_hook_active` で黙るテストを、継続でも検証してblockするテストに置き換える。失敗を確認する
- [x] 3.2 `verify-gate.bats` にテストを足し、失敗を確認する。3回までのblock、4回目の `systemMessage`、次のターンでの再開、変わらない作業ツリーでの再実行なし
- [x] 3.3 `verify-gate.bats` にテストを足し、失敗を確認する。`verify-fast` のあるMakefileでは `make verify-fast` だけが走る。`CLAUDE_PROJECT_DIR` と違う `cwd` のgitルートで走る
- [x] 3.4 `verify-gate.sh` に、`verify-blocks` による回数と前回の失敗の記録、`verify-fast` の探索を入れる。`baseline` が無いときの行には触れない。3.1〜3.3とshellcheckが通ることを確認する

## 4. verify-fast

- [x] 4.1 `makefile.bats` に `verify-fast-plan` のテストを足す。`CHANGED` を与え、文書、用語集、hook、共通部品、`hooks.json`、`bin/`、`Makefile`、スキルの各場合の選択を確かめる。失敗を確認する
- [x] 4.2 `makefile.bats` に、一時のgitリポジトリへ `Makefile` を写すテストを足す。commit済みの変更と追跡外のファイルが一覧に入ることを確かめる。失敗を確認する
- [x] 4.3 `Makefile` に `VERIFY_BASE`、`CHANGED`、選び方の変数、`verify-fast`、`verify-fast-plan` を足す。`SCRIPT_DIRS` に `plugins/uskn-harness/bin` を足す。4.1と4.2が通ることを確認する
- [x] 4.4 `make verify-fast` の所要時間を、変更なし、文書1本、hook1本の場合で測る。数秒に収まることを確認する

## 5. hooks.jsonのif

- [x] 5.1 `hooks-json.bats` を足し、失敗を確認する。確かめるのは、textlint-check、terms-check、grilling-guardのmatcherと `if` の組み合わせと、`if` を持たないhook
- [x] 5.2 `hooks.json` をツールごとのmatcherに分けて `if` を付ける。5.1と `claude plugin validate --strict plugins/uskn-harness` が通ることを確認する
- [x] 5.3 textlint-checkとterms-checkのテストに、`.markdown` のファイルでは黙る場合を足して失敗を確認する。スクリプトを `.md` だけに絞り、通ることを確認する

## 6. プラグインのbin/

- [x] 6.1 `plugin-bin.bats` を足し、失敗を確認する。2つのコマンドが元のスクリプトと同じ出力と終了コードを返すこと、symlinkを通したプラグインでも動くことを確かめる
- [x] 6.2 `bin/tests/skill-commands.bats` を足し、失敗を確認する。スキルは `session-start.sh` と `terms-check.sh` を長いパスで呼ばない。スキルの呼ぶ `uskn-*` は `bin/` に実在する
- [x] 6.3 `plugins/uskn-harness/bin/` に `uskn-repo-context` と `uskn-terms-check` を置く。6.1とshellcheckが通ることを確認する
- [x] 6.4 gitスキル8つとaudit-writingスキルの呼び出しを短いコマンドに替える。6.2が通ることを確認する
- [x] 6.5 `plugin.json` の説明と `plugins/uskn-harness/README.md` に `bin/` と `if` を書く。`make verify-plugin` と `make verify-terms` が通ることを確認する
- [x] 6.6 ADR-0005を書き、ADR-0002に注記を足す。textlintとtermsの検査が通ることを確認する

## 7. 仕上げ

- [x] 7.1 `openspec/glossary.yml` の「verify gate」の定義を、1ターンに3回までblockする形に直す。`make verify-terms` が通ることを確認する
- [x] 7.2 `make verify` と `openspec validate hook-native-features --strict` が通ることを確認する。`make verify` と `make verify-fast` の所要時間を記録する

## 統合（2026-09-25）

- [x] 統合のときに、write-guardの「ルート外の拒否」へretire-session-journalの変更（許可リストから `~/.ai-sessions` を外し、拒否する場合の例を足す）を取り込む。archiveはfix-hook-bugs、retire-session-journal、この変更の順に行う
