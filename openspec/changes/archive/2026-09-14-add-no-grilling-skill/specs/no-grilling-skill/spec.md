## Purpose

ユーザーの指示があるときだけgrillingのインタビューを省略し、その旨を `grilling.md` に残してから成果物を作るスキル。簡単な改修で質問のラウンドを省きつつ、省略した事実をarchiveに残す。

## ADDED Requirements

### Requirement: 省略はユーザーの指示に限る
エージェントが省略を言い出すとき、`no-grilling` は `AskUserQuestion` で省略するかを尋ねなければならない（MUST）。
ユーザーが省略を選ぶまで、`no-grilling` は `openspec new change` を実行してはならない（MUST NOT）。
ユーザーが自分で `/no-grilling` を実行したときは、その実行を指示とみなす。

#### Scenario: エージェントの提案
- **WHEN** エージェントがtypo修正を簡単な改修と判断し、no-grillingを使おうとする
- **THEN** 省略するかの質問が出て、ユーザーが答えるまで変更のディレクトリは作られない

#### Scenario: ユーザーの実行
- **WHEN** ユーザーが `/no-grilling fix-readme-typo` を実行する
- **THEN** 省略の確認を求めずに変更を作る

### Requirement: 省略を記録する
`no-grilling` は変更を作ったら、テンプレートの見出しと表を残した `grilling.md` を書かなければならない（MUST）。
表は「grillingの省略」の1行で、省略する理由を持つ。
状態の行は「grillingは省略した。ユーザーの指示を<YYYY-MM-DD>に確認済み」とする。

#### Scenario: 記録の内容
- **WHEN** 2026-09-14に理由「READMEのtypo修正のみ」で省略する
- **THEN** `grilling.md` の表は1行で理由を含み、状態の行は「grillingは省略した。ユーザーの指示を2026-09-14に確認済み」になる

### Requirement: インタビューの記録を上書きしない
対象の変更に `grilling.md` がすでにあるとき、`no-grilling` はそれを書き換えてはならない（MUST NOT）。

#### Scenario: 記録済みの変更
- **WHEN** `grilling.md` がある変更の名前を渡して `/no-grilling` を実行する
- **THEN** `grilling.md` は変わらず、残りの成果物の作成だけを続ける

### Requirement: 成果物まで作って止まる
`no-grilling` は省略記録の後、`spec` スキルと同じ手順でproposal、specs、design、tasksを作らなければならない（MUST）。
引数に `--step` があるときは、成果物を1つ書くごとにユーザーの確認を待たなければならない（MUST）。
作り終えたら、`no-grilling` はコードを変えずに `/opsx:apply` を案内して止まらなければならない（MUST）。

#### Scenario: 一括
- **WHEN** `/no-grilling fix-readme-typo` を実行する
- **THEN** `grilling.md` に続いて4つの成果物が作られ、`/opsx:apply fix-readme-typo` の案内で終わる

#### Scenario: 段階
- **WHEN** `/no-grilling fix-readme-typo --step` を実行する
- **THEN** proposalの後で確認が求められ、承認までspecsは作られない
