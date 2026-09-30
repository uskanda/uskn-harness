## Why

`/spec` で仕様をまとめたあと、それをPRにする作業は手で行っている。ブランチを切ってchangeのディレクトリだけをコミットし、draftのPRを作る。
続くchange `add-loop-run` のループは、OpenSpecの変更を含むPR（仕様PR）を作業指示として受け取る。そのため、仕様PRを同じ形で確実に作る入口が先に要る。

## What Changes

- 新しいスキル `spec-pr` を追加する。引数がアイデアなら先に `spec` を呼んで成果物を作り、既存のchange名ならそのまま使う
- 前提は、成果物がすべてそろい、`openspec validate <name> --strict` が通ること。満たさなければ止まって報告する
- 統合ブランチの最新から `change/<name>` を切り、changeのディレクトリだけをコミットしてpushする。作り終えたら元のブランチに戻る
- 統合ブランチ向けのdraft PRを作る。GitLabではdraft MRを作る。自動マージは付けない。`pr` スキルの統合モードは自動マージを付けるので、その経路は使わない
- タイトルはproposalの要点を1行にする。本文はproposalの要約、成果物へのリンク、進め方（手元での実装、確認後の `/archive-push`）にする。tasksは本文に写さない。ループでの実装の案内は、ループ本体と一緒に `add-loop-run` が足す
- エージェントからも呼べる（`disable-model-invocation` を付けない）
- `/spec` の最後の案内に、`/opsx:apply <name>` と並べて `/spec-pr <name>` を示す
- batsのテストでfrontmatterを確かめる

## Capabilities

### New Capabilities

- `spec-pr-skill`: OpenSpecの変更1つを、統合ブランチ向けのdraftの仕様PRにするスキル

### Modified Capabilities

- `spec-skill`: 終了時の案内に、実装の入口 `/opsx:apply` に加えて仕様PRの入口 `/spec-pr` を示す

## Impact

- 新規：`skills/spec-pr/SKILL.md`。`uskn-harness sync` が他の自前スキルと同じく配る
- 新規：`bin/tests/spec-pr-skill.bats`
- 変更：`skills/spec/SKILL.md` の終了の節
- 文書：`README.md` の機能の表の「仕様づくり」の行
- 依存：`spec`、`commit` の各スキル、`gh` と `glab`、SessionStart hookのrepo-context（platform、統合ブランチ）
- 用語：「仕様PR」は用語集に登録済み
