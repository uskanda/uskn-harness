# spec-skill Specification

## Purpose
アイデアから OpenSpec の成果物一式までを 1 つの入口で通すスキル。インタビューを省いて成果物を作ることができない構造にする。

## Requirements

### Requirement: インタビュー先行
`spec` は成果物を作る前に grilling スキルでインタビューしなければならない（MUST）。
frontier が空になり、ユーザーが共有理解を確認するまで `openspec new change` を実行してはならない（MUST NOT）。

#### Scenario: 確認前
- **WHEN** ユーザーが質問に答えている途中
- **THEN** change ディレクトリはまだ存在しない

### Requirement: 実際の対話を記録する
`spec` は確認後に change を作り、行った対話から `grilling.md` を書かなければならない（MUST）。表の各行は実際に出した質問と選ばれた案、出典（ラウンドと番号）を持つ。対話に無い決定を書いてはならない（MUST NOT）。

#### Scenario: 記録の内容
- **WHEN** 2 ラウンド 7 問のインタビューを終えて change を作る
- **THEN** `grilling.md` の表は 7 行で、出典に各ラウンドと番号がある

### Requirement: 成果物の生成モード
既定では `grilling.md` の後に proposal / specs / design / tasks を依存順に一括生成する。引数に `--step` があるときは成果物を 1 つ書くごとにユーザーの確認を待たなければならない（MUST）。引数が既存の change 名なら、その change の未完了アーティファクトから続ける。

#### Scenario: 一括
- **WHEN** `/spec add-x` を実行し確認を終える
- **THEN** 4 つの成果物が続けて作られ、最後に `openspec status` の結果が示される

#### Scenario: 段階
- **WHEN** `/spec add-x --step` を実行する
- **THEN** proposal の後で確認が求められ、承認まで specs は作られない

### Requirement: 実装に進まない
`spec` は成果物を作り終えたら停止し、実装は `/opsx:apply` に委ねなければならない（MUST）。

#### Scenario: 終了時
- **WHEN** tasks.md まで作り終える
- **THEN** コードは変更されず、apply への案内で終わる
