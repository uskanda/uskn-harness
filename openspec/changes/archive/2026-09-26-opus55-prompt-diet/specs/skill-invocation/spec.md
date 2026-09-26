## Purpose

スキルがどう起動されるかの規則。モデルが常に読む説明文を短く保ち、引数の案内を入力補完へ移し、ユーザーだけが起動するスキルを別のスキルが呼ばないようにする。

## ADDED Requirements

### Requirement: 説明文の長さ
`disable-model-invocation: true` を持たないスキルは、`description` と `when_to_use` を合わせて200文字以内にしなければならない（MUST）。
主な用途を先頭に書く。

#### Scenario: 長い説明文
- **WHEN** モデルから起動できるスキルの `description` を201文字にする
- **THEN** batsのテストが失敗し、そのスキルの名前と文字数が出る

#### Scenario: ユーザーだけが起動するスキル
- **WHEN** `disable-model-invocation: true` を持つスキルの `description` が200文字を超える
- **THEN** テストは失敗しない。その説明文はモデルの文脈に入らない

### Requirement: 引数の案内
引数を読むスキルは、引数の形をfrontmatterの `argument-hint` に書かなければならない（MUST）。
引数を読むスキルとは、本文が `$ARGUMENTS` を使うか、`## Arguments` か `## Argument` の見出しを持つスキルである。

#### Scenario: argument-hint の無いスキル
- **WHEN** 本文が `$ARGUMENTS` を使うスキルから `argument-hint` を消す
- **THEN** batsのテストが失敗し、そのスキルの名前が出る

#### Scenario: 引数の詳しい意味
- **WHEN** `pr` の引数ごとの動きを知りたい
- **THEN** 詳しい意味は本文にあり、`description` には無い

### Requirement: ユーザーだけが起動するスキルを呼ばない
スキルの本文は、`disable-model-invocation: true` を持つスキルをSkillツールで実行する手順を含んではならない（MUST NOT）。
そうしたスキルが要る場面では、ユーザーに入力を頼む。

#### Scenario: 呼び出しを足す
- **WHEN** あるスキルの本文に、`Run the Skill tool with` の形で `rebase` を実行する手順を足す
- **THEN** batsのテストが失敗し、呼ぶ側と呼ばれる側の名前が出る

### Requirement: 規則のセンサー
batsのテストは、`skills/` 配下のすべての `SKILL.md` について、この能力の規則を確かめなければならない（MUST）。

#### Scenario: make verify
- **WHEN** 規則に反するスキルを足して `make verify` を実行する
- **THEN** batsのテストが失敗し、そのスキルの名前が出る
