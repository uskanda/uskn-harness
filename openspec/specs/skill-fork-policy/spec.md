# skill-fork-policy Specification

## Purpose
スキルを会話の文脈を持たないforkで動かすか、インラインで動かすかに応じて、frontmatterに置ける設定を定める。モデルとeffortの指定を、費用が下がる形に限る。

## Requirements

### Requirement: forkのスキルは呼び出し側を待たせる
`context: fork` を持つスキルは、frontmatterに `background: false` を持たなければならない（MUST）。

#### Scenario: 別のスキルから呼ぶ
- **WHEN** `push` がSkillツールでforkの `commit` を呼ぶ
- **THEN** `push` は `commit` の報告を受け取ってからpushに進む

### Requirement: forkのスキルはユーザーに尋ねない
`context: fork` を持つスキルは、`allowed-tools` に `AskUserQuestion` を持ってはならない（MUST NOT）。

#### Scenario: 尋ねるスキルをforkにする
- **WHEN** `allowed-tools` に `AskUserQuestion` を持つスキルに `context: fork` を足す
- **THEN** batsのテストが失敗し、そのスキルの名前が出る

### Requirement: モデルとeffortはforkのスキルにだけ置く
`context: fork` を持たないスキルは、frontmatterに `model:` と `effort:` のどちらも持ってはならない（MUST NOT）。

#### Scenario: インラインのスキル
- **WHEN** `push` のfrontmatterを読む
- **THEN** `model:` と `effort:` のどちらも無い

### Requirement: モデルは別名で書く
スキルの `model:` は、`haiku`、`sonnet`、`opus`、`fable` のいずれかでなければならない（MUST）。

#### Scenario: バージョンを含む指定
- **WHEN** あるスキルの `model:` が `claude-sonnet-5` である
- **THEN** batsのテストが失敗し、そのスキルの名前が出る

### Requirement: haikuのスキルはeffortを持たない
`model: haiku` を持つスキルは、`effort:` を持ってはならない（MUST NOT）。

#### Scenario: haikuのスキルにeffortを足す
- **WHEN** `model: haiku` を持つスキルに `effort: low` を足す
- **THEN** batsのテストが失敗し、そのスキルの名前が出る

### Requirement: 規則のセンサー
batsのテストは、`skills/` 配下のすべての `SKILL.md` について、この能力の規則を確かめなければならない（MUST）。

#### Scenario: 規則に反するスキルを足す
- **WHEN** インラインのスキルに `effort: low` を足して `make verify` を走らせる
- **THEN** batsのテストが失敗し、そのスキルの名前が出る
