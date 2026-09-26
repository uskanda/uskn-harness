## 1. センサーを先に書く

- [x] 1.1 `bin/tests/skill-invocation.bats` を足す。確かめるのは次の3つ。
  モデルから起動できるスキルの説明文が200文字以内であること。引数を読むスキルが `argument-hint` を持つこと。
  Skillツールで名指しされたスキルが `disable-model-invocation` を持たないこと。
  変更前のスキルで、説明文と引数のテストが失敗し、スキルの名前が出ることを確かめる
- [x] 1.2 `bin/tests/uskn-harness.bats` のユーザー層の大きさのテストに、2,000バイトの上限を足す。変更前の `templates/user/CLAUDE.md`（3,595バイト）で失敗することを確かめる

## 2. スキルのfrontmatter

- [x] 2.1 `disable-model-invocation: true` を5つのスキルに付ける。対象は `rebase`、`cleanup-merged`、`release`、`onboard-harness`、`audit-writing`。
  説明文は人が読む1行にする。
  `bats bin/tests/skill-invocation.bats bin/tests/skill-fork-policy.bats` が通ることを確かめる
- [x] 2.2 `disable-model-invocation` を持たないスキルの説明文を、用途を先頭にして200文字以内にする。引数の説明は、引用符で囲んだ `argument-hint` へ移す。`verify` の説明文から完了前の起動条件を外す。1.1の説明文と引数のテストが通ることを確かめる
- [x] 2.3 `allow-repo`、`archive-push`、`ok` の説明文から引数の説明を外し、`argument-hint` へ移す。`allow-repo` の説明文から「Never run this on your own initiative」を外す。`make verify-skills` が通ることを確かめる

## 3. 方法論スキル

- [x] 3.1 `skills/test-driven-development/SKILL.md` を肯定形で書き直す。
  Iron Law、言い訳の表、Red Flags、MANDATORY、Final Rule、完了前の確認の一覧、状態遷移図を消す。
  Harness Notesは、検証規約とgateの関係に合わせる。
  約190行になることと、次の `grep` が何も出さないことを確かめる。
  `grep -nE 'Iron Law|Red Flags|MANDATORY|TodoWrite' skills/test-driven-development/SKILL.md`
- [x] 3.2 `skills/systematic-debugging/SKILL.md` を肯定形で書き直し、説明文を原因の分からない失敗に絞る。4つの段階、3回の修正で設計を疑う手順、参照ファイルへの導線を残す。3.1と同じ `grep` が何も出さず、約170行になることを確かめる
- [x] 3.3 `root-cause-tracing.md` の「NEVER fix just the symptom」と、`defense-in-depth.md` の大文字の「EVERY」を普通の言い方にする。`grep -n 'NEVER\|EVERY' skills/systematic-debugging/*.md` が何も出さないことを確かめる
- [x] 3.4 `deps.json` の `forks` の2項目に `diverged` と `note` を足し、`changes` に書き直しの1行を足す。`git diff deps.json` が `forks` の中だけを変えていることを確かめる

## 4. 常に読み込まれる指示

- [x] 4.1 `templates/user/CLAUDE.md` をgrilling.mdのQ12どおりに書き直す。1.2のテストと、削除したスキルの名前が無いことのテストが通ることを確かめる
- [x] 4.2 `AGENTS.md` からユーザー層と重なる記述を消し、Layoutに `bin/` の行を足す。`plugins/uskn-harness/` の行を、スキルが呼ぶ短いコマンドも含む書き方にする。`plugins/uskn-harness/hooks/scripts/terms-check.sh AGENTS.md` が通ることを確かめる

## 5. 強調と検証を促す文の点検

- [x] 5.1 `skills/` と `templates/` を、大文字の強調（MUST、NEVER、CRITICAL、IMPORTANT）と、確かめ直しや検証の追加を促す文で検索する。見つかった箇所を普通の言い方にするか、hookが強制するなら消す。残した箇所は理由をdesign.mdに書く

## 6. 測定と全体の確認

- [x] 6.1 `design.md` の測定の表を埋める。測るのは、モデルが読む説明文の合計の文字数と、2つの方法論スキルの行数とバイト数。
  `templates/user/CLAUDE.md` と `AGENTS.md` のバイト数も測る
- [x] 6.2 `make verify` と `openspec validate opus55-prompt-diet --strict` が通ることを確かめる
