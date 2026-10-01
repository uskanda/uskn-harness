## 1. 土台

- [ ] 1.1 `docs/adr/0006-loop-runner.md` を書く。ループをハーネスに置くこと、プロダクトリポジトリに何も足さないこと、段階2ではサーバー単位のウォッチャーにすることを記録する。退けた案（リポジトリごとのCI、routines、1セッション内のsubagent）も書く。textlintとterms checkが通ることを確認する
- [ ] 1.2 `bin/tests/uskn-loop.bats` の土台を作る。偽物の `claude`、`gh`、`glab` と、一時ディレクトリにbareのoriginを作る補助を置く。`uskn-loop` を引数なしで実行すると使い方を示して終了コード2で終わるテストを書き、失敗を確認してから `bin/uskn-loop` を作って通す
- [ ] 1.3 `loop/limits.env` と上限の読み込みを作る。既定値と、`USKN_LOOP_` で始まる環境変数による上書きをテストで確かめる
- [ ] 1.4 `AGENTS.md` のLayout表に `loop/` の行を足す。terms checkが通ることを確認する

## 2. ホストと受け付け条件

- [ ] 2.1 `loop/lib/host.sh` を作る。originのURLからGitHubかGitLabかを判定し、PRかMRの情報とログイン中のユーザーを取得する。GitHubとGitLabの両方の経路を、偽物の `gh` と `glab` でテストする
- [ ] 2.2 `uskn-loop run` に受け付け条件を足す。open、forkでない、作成者、changeが1つの4条件について、満たさないときに終了コード2で止まり、worktreeとコメントを作らないことをテストで確かめる
- [ ] 2.3 changeの特定を差分で行う。クローンの外で実行したときと、検証規約が見つからないときに止まることも、テストで確かめる

## 3. 作業場所と状態

- [ ] 3.1 worktreeを `.claude/worktrees/loop-pr-<番号>` に作り、2回目以降は使い回す。無視されていなければ `.git/info/exclude` に1行足す。手元の作業ツリーとブランチが変わらないことをテストで確かめる
- [ ] 3.2 `uskn-loop run` に状態の記録、ロック、再開、`--reset` を足す。二重実行の拒否、残ったロックの引き継ぎ、ラウンドの数えと費用の合計の引き継ぎをテストで確かめる

## 4. ラウンド

- [ ] 4.1 `loop/prompts/implementer.md` を作り、実装役の起動を足す。偽物の `claude` が受けた引数から、権限モード、`--permission-prompts none`、費用の上限を確かめる。1ラウンド目の `/opsx:apply <change>` と、2ラウンド目以降の指摘の受け渡しもテストで確かめる
- [ ] 4.2 `uskn-loop run` にラウンドごとのpushを足す。pushの宛先がheadのブランチだけであることと、拒否されたときに止まることをテストで確かめる
- [ ] 4.3 `uskn-loop run` に計算的センサーを足す。未コミットの変更、検証規約、`openspec validate --strict`、tasks.md、テストの削除とskip、検証の設定の変更の6つを、それぞれ失敗させるテストで確かめる。失敗したラウンドで監査役を起動しないことも確かめる
- [ ] 4.4 `loop/prompts/auditor.md` と `loop/verdict.schema.json` を作り、監査役の起動と判定の読み取りを足す。監査役の道具、判定の欄が欠けたときの停止、作業ツリーの復元をテストで確かめる
- [ ] 4.5 `uskn-loop run` に停止条件と、完了時と停止時の扱いを足す。5ラウンド、PR合計の費用、進展なし、監査役の問い、基底ブランチとの衝突をそれぞれテストで確かめる。draftの解除、worktreeの削除、終了コード0と3、マージとarchiveとラベルを行わないことも確かめる

## 5. 進捗コメント

- [ ] 5.1 `uskn-loop run` に進捗コメントの作成と書き換えを足す。1つのPRにコメントが1つだけであること、再開で印から既存のコメントを見つけること、中身の欄、生の出力を載せないことをテストで確かめる
- [ ] 5.2 `uskn-loop run` に完了時と停止時のコメントを足す。完了では `/archive-push` の案内を、停止では停止条件と問いと再開のコマンドを持つことをテストで確かめる

## 6. 配布

- [ ] 6.1 `bin/uskn-harness` のsyncとdoctorと `--remove` に、`~/.local/bin/uskn-loop` のsymlinkを足す。先に `bin/tests/uskn-harness.bats` へテストを足して失敗を確認する
- [ ] 6.2 `Makefile` のverify-fastで、`bin/uskn-loop` と `loop/` の変更に `bin/tests/uskn-loop.bats` を対応させる。先に `bin/tests/makefile.bats` へテストを足して失敗を確認する
- [ ] 6.3 `README.md` の機能の表にループの行を足す。textlintとterms checkが通ることを確認する
- [ ] 6.4 `bin/tests/skill-commands.bats` が、リポジトリの `bin/` の実行ファイルも名指しできるコマンドとして認めるようにする。`bin/tests/spec-pr-skill.bats` に、本文の雛形の `uskn-loop run` を確かめるテストを足して失敗を確認する
- [ ] 6.5 `skills/spec-pr/SKILL.md` の本文の雛形の進め方に `uskn-loop run <このPRの番号>` の行を、報告の次の一歩にループを足す。6.4のテストが通ることを確認する

## 7. 結合の確認

- [ ] 7.1 `openspec validate add-loop-run --strict` と `make verify` が通ることを確認する
- [ ] 7.2 `uskn-harness sync` のあと、このハーネスの仕様PRを1つ選び、ユーザーが `uskn-loop run` を実行する。進捗コメント、ラウンドごとのpush、完了か停止の扱いを確かめる（試験の1件目）
