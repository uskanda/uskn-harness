## 1. 取り込み

- [x] 1.1 obra/superpowers v6.3.0 から 4 スキルの実行時ファイルを `skills/` にコピーする。各ディレクトリに MIT の `LICENSE` を置く
- [x] 1.2 `superpowers:` プレフィックスの参照をハーネスのスキル名に置き換える。`grep -r 'superpowers:' skills/` は空になる
- [x] 1.3 各 SKILL.md の frontmatter に `license: MIT` を入れ、本文の先頭に出所と変更点を書く

## 2. ハーネスへの適合

- [x] 2.1 `verification-before-completion` に verify 規約、Stop hook、tasks.md の突き合わせを足す
- [x] 2.2 `using-git-worktrees` の worktree をルート内に限り、baseline の確認を verify 規約に寄せる
- [x] 2.3 `test-driven-development` に verify 規約への言及を足す

## 3. 記録

- [x] 3.1 `deps.json` の `forks` を `vendored` にし、取り込み日と変更点を書く
- [x] 3.2 `templates/user/CLAUDE.md` の TDD と検証の行をスキル名で指す
- [x] 3.3 README を更新し、`make verify` を通してからコミットする
