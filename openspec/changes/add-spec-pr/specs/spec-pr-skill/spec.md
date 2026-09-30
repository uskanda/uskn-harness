## Purpose

OpenSpecの変更1つを、統合ブランチ向けのdraftの仕様PR（GitLabではMR）にするスキル。仕様を人とループの両方が読める作業指示として、決まった形でリモートに置く。

## ADDED Requirements

### Requirement: 対象の変更を決める
引数が既存のchange名のとき、`spec-pr` はそのchangeを対象にしなければならない（MUST）。
引数がアイデアのとき、`spec-pr` は先に `spec` を呼んで成果物を作り、できたchangeを対象にしなければならない（MUST）。
引数が空で進行中のchangeが複数あるとき、`spec-pr` はどれを対象にするかをユーザーに尋ねなければならない（MUST）。

#### Scenario: change名を渡す
- **WHEN** 進行中のchange `add-x` があり、`/spec-pr add-x` を実行する
- **THEN** `add-x` の仕様PRを作る

#### Scenario: アイデアを渡す
- **WHEN** `/spec-pr ログイン画面にパスワードの再設定を足す` を実行する
- **THEN** 先に `spec` のgrillingが始まり、成果物ができてから仕様PRを作る

#### Scenario: 候補が複数
- **WHEN** 進行中のchangeが2つあり、引数なしで `/spec-pr` を実行する
- **THEN** どちらを対象にするかを尋ね、答えを待つ

### Requirement: 成果物と検証を確かめる
対象のchangeの必須の成果物が欠けているとき、`spec-pr` はブランチとPRを作らずに止まり、欠けた成果物を報告しなければならない（MUST）。
`openspec validate <name> --strict` が失敗するとき、`spec-pr` はブランチとPRを作らずに止まり、失敗の出力を報告しなければならない（MUST）。

#### Scenario: tasks.md が無い
- **WHEN** `add-x` にtasks.mdが無い状態で `/spec-pr add-x` を実行する
- **THEN** ブランチとPRは作られず、欠けている成果物が報告される

### Requirement: 公開済みのchangeを扱わない
対象のchangeのディレクトリが統合ブランチのリモートに既にあるとき、`spec-pr` は止まって報告しなければならない（MUST）。
対象のchangeのディレクトリがローカルのコミットにだけあり、まだpushされていないとき、`spec-pr` は履歴を書き換えずに止まって報告しなければならない（MUST）。

#### Scenario: 統合ブランチに入っている
- **WHEN** 統合ブランチを `main` とし、`openspec/changes/add-x/` が `origin/main` に既にある
- **THEN** 仕様PRは作られず、報告はchangeを公開済みと伝える

### Requirement: ブランチとコミット
`spec-pr` は、統合ブランチのリモートの最新から `change/<name>` を作り、changeのディレクトリだけを1つのコミットにしなければならない（MUST）。
対象と無関係な未コミットの変更を、`spec-pr` はコミットしてはならない（MUST NOT）。
同じ名前のブランチがローカルかリモートに既にあるとき、`spec-pr` は止まって報告しなければならない（MUST）。

#### Scenario: 別の作業が残っている
- **WHEN** `src/a.ts` に未コミットの変更がある状態で `/spec-pr add-x` を実行する
- **THEN** `change/add-x` のコミットは `openspec/changes/add-x/` だけを含み、`src/a.ts` は未コミットのまま残る

#### Scenario: ブランチが既にある
- **WHEN** リモートに `change/add-x` が既にある
- **THEN** 何も作られず、報告は既存のブランチの名前を示す

### Requirement: draftのPRかMRを作る
repo-contextのplatformがgithubのとき、`spec-pr` は統合ブランチ向けのdraft PRを作らなければならない（MUST）。
repo-contextのplatformがgitlabのとき、`spec-pr` は統合ブランチ向けのdraft MRを作らなければならない（MUST）。
`spec-pr` は仕様PRに自動マージを設定してはならない（MUST NOT）。

#### Scenario: GitHub
- **WHEN** GitHubのリポジトリで `/spec-pr add-x` を実行する
- **THEN** `change/add-x` から統合ブランチへのdraft PRができ、自動マージは設定されていない

#### Scenario: GitLab
- **WHEN** GitLabのリポジトリで `/spec-pr add-x` を実行する
- **THEN** `change/add-x` から統合ブランチへのdraft MRができ、マージ時の自動マージは設定されていない

### Requirement: タイトルと本文
`spec-pr` は、proposalの要点を1行にしたタイトルを付けなければならない（MUST）。
本文は、proposalの要約、成果物へのリンク、進め方の3つを持たなければならない（MUST）。
進め方は次の3つを示す。

- ループでの実装：`uskn-loop run <番号>`
- 手元での実装：ブランチを切り替えて `/opsx:apply <name>`
- 確認後の仕上げ：PRのブランチで `/archive-push <name>` を実行してからマージする

`spec-pr` はtasks.mdの項目を本文に写してはならない（MUST NOT）。

#### Scenario: 本文の中身
- **WHEN** 仕様PRの本文を読む
- **THEN** 要約、proposal・specs・design・tasksへのリンク、進め方の3つがあり、tasksのチェックリストは無い

### Requirement: 元のブランチに戻る
仕様PRを作り終えたとき、`spec-pr` は実行前のブランチに戻り、PRかMRのURLを報告しなければならない（MUST）。

#### Scenario: 作成後
- **WHEN** `main` で `/spec-pr add-x` を実行し、仕様PRができる
- **THEN** 作業ツリーは `main` に戻り、報告にPRのURLがある

### Requirement: エージェントからも呼べる
`spec-pr` は `disable-model-invocation: true` を持ってはならない（MUST NOT）。

#### Scenario: ユーザーの依頼
- **WHEN** ユーザーが「このchangeを仕様PRにして」と頼む
- **THEN** エージェントが `spec-pr` を呼び、仕様PRを作る

#### Scenario: センサー
- **WHEN** `make verify` を実行する
- **THEN** batsのテストが、`spec-pr` のfrontmatterの `name` が `spec-pr` であることと、`disable-model-invocation: true` が無いことを確かめる
