## MODIFIED Requirements

### Requirement: 内容
`templates/user/CLAUDE.md` は次を含まなければならない（MUST）。

- 先頭行の管理印（`<!-- managed by uskn-harness; edit templates/user/CLAUDE.md -->`）
- チャットと生成物の言語（日本語）
- 仕様決定は `/spec` でgrillingを通してからOpenSpecの成果物を作ること。単純に見える変更には `/no-grilling` を提案し、ユーザーが選ぶこと
- ユーザーは提案に `/ok` で答えられ、`/ok` は提案が名指しした次の入力へ進むこと
- 他リポジトリへの変更はPRかhandoffで渡すこと。プロジェクトルートの外を直接直すには、ユーザーが `/allow-repo` を実行すること
- 検証は `make verify` → `pnpm run verify` / `npm run verify` の規約に従うこと。verify gateがそれを実行すること
- 過去の決定の置き場（変更のアーカイブ、ADR、コミットメッセージ）

全体で60行以内。バイト数は2,000以内。

#### Scenario: 行数
- **WHEN** ファイルの行数を数える
- **THEN** 60行以下

#### Scenario: 大きさ
- **WHEN** ファイルのバイト数を数える
- **THEN** 2,000以下

#### Scenario: 環境が伝えること
- **WHEN** `templates/user/CLAUDE.md` を読む
- **THEN** `<repo-context>` の説明とgitスキルの一覧は無い。どちらもSessionStart hookの出力とスキルの一覧が伝える

### Requirement: Writing 節
ユーザー層の `CLAUDE.md` は、文章の指針への導線を含まなければならない（MUST）。
日本語の文章は `ja-writing`、人が読む英語の文章は `en-writing`、スキルと指示ファイルは `writing-for-agents` に従う。
textlintの指摘を直してから終えることは、textlint hookの返す文が伝える。ユーザー層の `CLAUDE.md` はこの文を持たない。

#### Scenario: hook の指摘
- **WHEN** textlint hookが指摘を返す
- **THEN** hookの返す文が、直してから終えることと `ja-writing` を伝える。エージェントは指摘を直してから作業を終えたと報告する

### Requirement: 方法論スキルへの導線
ユーザー層の `CLAUDE.md` は、スクリプトやコードに振る舞いを足すとき失敗するテストを先に書くことを含まなければならない（MUST）。
その行は `test-driven-development` を名指しする。
原因の分からない失敗への導線は、`systematic-debugging` の説明文が持つ。
完了の前の確認はverify gateに任せ、ユーザー層の `CLAUDE.md` は完了と言う前に検証するよう求めてはならない（MUST NOT）。
`sync` が導入しないスキルの名前を書いてはならない（MUST NOT）。

#### Scenario: 新しい振る舞い
- **WHEN** スクリプトに振る舞いを足す
- **THEN** エージェントは `test-driven-development` に従い、失敗するテストを先に書く

#### Scenario: テスト失敗
- **WHEN** テストが失敗し、原因が分からない
- **THEN** エージェントは `systematic-debugging` の説明文に従い、修正案を出す前に原因を調べる

#### Scenario: 完了の報告
- **WHEN** エージェントが作業を終えようとする
- **THEN** ユーザー層の `CLAUDE.md` に、その前に検証せよという文は無い。作業ツリーが変わっていれば、verify gateが検証規約を実行する

#### Scenario: 削除したスキル
- **WHEN** `templates/user/CLAUDE.md` を `verification-before-completion`、`using-git-worktrees`、`pre-merge` で検索する
- **THEN** 一致しない
