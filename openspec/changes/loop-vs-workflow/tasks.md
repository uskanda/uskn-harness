# Tasks

## 1. 文書

- [x] 1.1 `docs/adr/0007-loop-runner.md` の「検討した代替案」の表に、Workflowの行を足す。退けた理由には、スクリプトがシェルに触れず計算的なセンサーの終了コードで分岐できないこと、エージェントごとにツールを絞れないこと、hookが動くか文書に無いことを書く。textlintとterms-checkが通ることを確かめる
- [x] 1.2 `docs/loop-engineering-2026-09.md` の実装役と監査役の行の「退けた案」に、Workflowを足す。textlintとterms-checkが通ることを確かめる

## 2. 統合

- [x] 2.1 `openspec validate loop-vs-workflow --strict` と `make verify VERIFY_STRICT=1` が通ることを確かめる
- [ ] 2.2 PRをmainへマージする
