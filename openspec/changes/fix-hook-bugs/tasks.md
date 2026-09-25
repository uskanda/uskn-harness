## 1. テストの判定を直す

- [x] 1.1 journal系を除く全batsで、`[ A ] && [ B ]` を1行1判定に分ける。行の途中の `! grep` と `|| true` の判定は `refute` に直す。`grep` で該当行が残らないことと、batsが通ることを確認する
- [x] 1.2 `bash-guard.bats` と `write-guard.bats` の許可ディレクトリを `BATS_TEST_TMPDIR` の下の専用ディレクトリにする。既定の許可リストは別のテストで確かめる。scratchpadの下の `TMPDIR` で両方が通ることを確認する
- [x] 1.3 1.1で失敗し始めた `textlint-check.bats` の判定を調べる。`.textlintrc` と `.textlintrc.json` の片方だけでは、リポジトリの設定が使われていなかった。`textlint-check.sh` の判定を直し、テストが通ることを確認する

## 2. 許可ファイルの保護

- [x] 2.1 write-guardのテストに、許可ファイルへのWrite、symlink経由のEdit、状態ディレクトリを許可したあとのWriteが拒否される場合を足し、失敗を確認する
- [x] 2.2 `lib/common.sh` の `path_allowed` から許可ファイルを除き、write-guardに解除できない拒否を足す。2.1が通ることを確認する
- [x] 2.3 bash-guardのテストに、許可ファイルへのリダイレクトと `cp` が拒否され、`allow-repo.sh` の実行は黙る場合を足し、失敗を確認する
- [x] 2.4 bash-guardに許可ファイルの文字列の照合と、書き込み先の解決による拒否を足す。2.3が通ることを確認する

## 3. bash-guardの解析

- [x] 3.1 bash-guardのテストに、報告された取りこぼしを足す。引用符付きの `-C` と `cd`、`git -c k=v -C`、`--git-dir`、`GIT_DIR=`、`pushd`、引用符付きのリダイレクト。失敗を確認する
- [x] 3.2 bash-guardのテストに、報告された誤検知を足す。`git -C <外> log --grep reset`、`sed -i -n '/,$p'`、heredocの本文、外からの `cp`。失敗を確認する
- [x] 3.3 bash-guardをawkの字句解析と単純コマンドごとの判定に書き換える。3.1、3.2、既存のテスト、shellcheckが通ることを確認する
- [x] 3.4 chezmoiのテストに3つの場合を足し、失敗を確認する。`chezmoi -v apply` の拒否。source directoryを許可したあとの解除（`chezmoi source-path` の偽物と、`~/.local/share/chezmoi` への後退）。理由に入る `/allow-repo <source directory>`
- [x] 3.5 chezmoiの下位コマンドの判定と解除を実装する。3.4が通ることを確認する

## 4. terms-check

- [x] 4.1 terms-checkのテストを足す。PNGを追跡するリポジトリでの検査、CLIでのpythonの異常終了の非ゼロ、python3が無いときの既定とstrictの違い。失敗を確認する
- [x] 4.2 hookが黙るテストの `.ts` に、用語集に無いカタカナ語のコメントを入れる。失敗を確認する
- [x] 4.3 `terms-check.sh` を直す。バイト列で読み、hookはMarkdownに限り、CLIではpythonの失敗を返し、`VERIFY_STRICT` を読む。`Makefile` の `verify-terms` は `VERIFY_STRICT` を渡す。4.1と4.2が通ることを確認する

## 5. syncの終了コード

- [x] 5.1 `uskn-harness.bats` にテストを足す。npm globalの導入の失敗と `--tools` での失敗で終了コード1。予約名のスキルで、何も書かずに終了コード2。失敗を確認する
- [x] 5.2 `bin/uskn-harness` の `cmd_sync` が失敗の数で終了コードを決め、標準エラーに要約を出すようにする。checkoutの更新の失敗は `warn` にする。`check_duplicates` を主のシェルで判定する。5.1と既存のテストが通ることを確認する

## 6. スキルのfrontmatter

- [x] 6.1 `bin/tests/makefile.bats` にテストを足し、失敗を確認する。コロンと空白を引用符なしで含むfrontmatterで `verify-skills` が失敗する。PyYAMLが無いときはstrictで失敗する
- [x] 6.2 `Makefile` の `verify-skills` にPyYAMLによる解析を足す。6.1が通り、直す前の6つのスキルで `make verify-skills` が失敗することを確認する
- [x] 6.3 `skills/git/` の `cleanup-merged`、`fix-ci`、`push`、`rebase`、`switch-base`、`sync-base` の `description` を直す。
  同じ形で不正だった `commit` は、別の変更 `fork-skills-model-effort` が書く行と同じ内容に直す。`make verify-skills` が通ることを確認する
- [x] 6.4 `.github/workflows/verify.yml` に、PyYAMLが無いときだけOSのパッケージで入れる手順を足す

## 7. timeoutが無い環境の上限

- [ ] 7.1 `timeout` と `gtimeout` の無いPATHで、`with_timeout` が124を返し、process groupを止めるテストを足す。失敗を確認する
- [ ] 7.2 verify gateとtextlint-checkのテストを足す。同じPATHで、verify gateは打ち切りでblockし、textlint-checkは打ち切られる。失敗を確認する
- [ ] 7.3 `lib/common.sh` に `with_timeout` を足し、`verify-gate.sh` と `textlint-check.sh` から使う。7.1と7.2が通ることを確認する

## 8. 出力と文書の整合

- [ ] 8.1 verify gateのテストで、blockの出力に `hookSpecificOutput` が無いことを確かめ、失敗を確認してから `verify-gate.sh` を直す
- [ ] 8.2 `hooks.json` のmatcher、`grilling-guard.sh`、`textlint-check.sh`、`write-guard.sh` の冒頭のコメントから `MultiEdit` を外す。`claude plugin validate --strict` が通ることを確認する
- [ ] 8.3 `openspec/glossary.yml` などの、実態と違う記述を直す。用語集の「verify gate」の定義、`plugin.json` の説明、プラグインの `README.md`。
  `.gitignore` と、`lib/common.sh` の古いコメントも直す。`make verify-terms` が通ることを確認する

## 9. 検証

- [ ] 9.1 `make verify` が通ることを確認し、所要時間を記録する。ガードのテストをscratchpadの下の `TMPDIR` でも走らせる
- [ ] 9.2 `openspec validate fix-hook-bugs --strict` が通ることを確認する
