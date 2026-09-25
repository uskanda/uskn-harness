## Why

AnthropicのOpus 5とOpus 5.5向けのプロンプトの手引きは、次の3点を挙げる。
1つ目は、モデルが言われなくても自分の作業を確かめること。検証を足す指示や、それを足す古いハーネスの足場は検証のやりすぎを生むので外す。
2つ目は、4.5以降のモデルがsystem promptによく従うこと。「CRITICAL: You MUST」のような強い言い方は過剰な発火を生むので、普通の言い方にする。
3つ目は、常に読み込まれる文を短く保つこと。
ADR-0001の1.5節も、常時ロードを目次と規則に限り、環境から分かることを書かないと決めている。
いまのユーザー層の `CLAUDE.md`、このリポジトリの `AGENTS.md`、方法論スキル、スキルの説明文には、この3点に反する記述が残っている。

## What Changes

- `templates/user/CLAUDE.md` を書き直す。残すのは言語、`/spec`・`/no-grilling`・`/ok` の短い説明、境界の1文（`/allow-repo` を含む）、検証規約の1行。
  テストを先に書くこと、文章の指針の参照先、UIの正本、決定の置き場も残す。
  消すのはrepo-contextの説明、gitスキルの一覧、`/archive-push` の説明、完了前の検証を促す文、textlintの指摘を直す文。
  worktreeの説明と、`systematic-debugging` への導線も消す
- このリポジトリの `AGENTS.md` から、ユーザー層と重なる記述（仕様決定の手順、検証の促し、言語、作業ディレクトリ外の扱い、Claude Code節）を消す。Layoutに `bin/` の行を足す
- `test-driven-development` と `systematic-debugging` を、肯定形の具体的な指示に書き直す。Iron Law、言い訳の表、Red Flags、「MANDATORY」、Final Ruleを消す。上流と分岐したことを `deps.json` の `forks` に記録し、再取り込みはしない
- `systematic-debugging` の説明文を、原因の分からないバグや失敗に絞る
- モデルが読むスキルの説明文を200文字以内にし、主な用途を先頭に置く。引数の説明は `argument-hint` に移す。`verify` の説明文からは、完了前に実行させる起動条件を外す
- `rebase`、`cleanup-merged`、`release`、`onboard-harness`、`audit-writing` に `disable-model-invocation: true` を付ける。`pr`、`sync-base`、`switch-base` はモデルから起動できるまま残す
- 説明文の長さ、引数の案内、ユーザーだけが起動するスキルの呼び出しを確かめるbatsのテストを足す

## Capabilities

### New Capabilities

- `skill-invocation`: スキルがどう起動されるかの規則。モデルが読む説明文の長さ、引数の案内の置き場、ユーザーだけが起動するスキルを別のスキルが呼ばないこと、それらのセンサー

### Modified Capabilities

- `user-layer-instructions`: 内容の一覧と大きさの上限を変える。Writing節からtextlintの文を外す。方法論スキルへの導線を、テストを先に書くことの1行にする
- `methodology-skills`: 出所の表記に、上流と分岐して再取り込みしないことを足す。指示を肯定形で書く要件を足す
- `git-workflow-skills`: `rebase`、`cleanup-merged`、`release` をユーザーだけが起動するスキルにする
- `onboard-skill`: `onboard-harness` をユーザーだけが起動するスキルにする
- `audit-writing-skill`: `audit-writing` をユーザーだけが起動するスキルにする

## Impact

- 配布物：`templates/user/CLAUDE.md`。各マシンで次に `uskn-harness sync` を実行すると `~/.claude/CLAUDE.md` が入れ替わる
- 指示ファイル：このリポジトリの `AGENTS.md`。プロダクトリポジトリ向けの `templates/repo/AGENTS.md` からも、ユーザー層と重なる2行を消す
- スキル：`skills/test-driven-development/`、`skills/systematic-debugging/`（参照ファイルを含む）の本文。すべてのスキルのfrontmatter
- ピン：`deps.json` の `forks` の2項目だけ。ほかの項目には触れない
- テスト：`bin/tests/skill-invocation.bats`（新規）、`bin/tests/uskn-harness.bats` のユーザー層の大きさのテスト
- 使い方：5つのスキルは、ユーザーが `/rebase` のように打ったときだけ動く。モデルがそれらを提案するときは、入力をユーザーに頼む
- 触れないもの：hook、`hooks.json`、`bin/uskn-harness`、`Makefile`、gitスキルと `ui-guidelines`・`en-writing` の本文、ADR
