## 1. 文書の修正

- [x] 1.1 AGENTS.md の Layout を直す。`hooks/` の行を削除する。plugins の行に hook 本体と bats を書く。templates の行に chezmoi を足す。AGENTS.md を `hooks/scripts` と `hooks/adapters` で grep して 0 件になることを確認する
- [x] 1.2 ADR-0001 §3 と §7 を直す。ADR-0001 を `hooks/scripts` と `trends` で grep して 0 件、`templates/chezmoi` で 1 件になることを確認する
- [x] 1.3 プラグイン README のアダプタの文を直す。README を `hooks/adapters` で grep して 0 件になることを確認する
- [x] 1.4 proposal §12.2 の冒頭に注記を足す。`docs/` の行から `principles.md`、`portability-matrix.md`、`trends/` を消す。§12.2 の節を表示して確認する

## 2. 実体の整理と検証

- [x] 2.1 ローカルの空ディレクトリ `hooks/` と `docs/trends/` を削除し、`ls hooks docs/trends` が失敗することを確認する
- [x] 2.2 `make verify` が通ることを確認する
- [x] 2.3 リポジトリの Markdown 全体を古いパスで grep する。対象語は `hooks/scripts/`、`hooks/adapters`、`principles.md`、`portability-matrix`。残りが proposal の記録部分、archive、引き継ぎ文書、この change だけであることを確認する
