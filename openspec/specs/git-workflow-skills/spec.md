# git-workflow-skills Specification

## Purpose
どのリポジトリでも同じ名前で呼べる git ワークフロー用スキルの集合。ブランチ名は `branch-model` の解決結果に従い、プロジェクト固有の履歴を持たない。

## Requirements

### Requirement: スキルの集合と命名
システムは `commit` `push` `pr` `sync-base` `switch-base` `rebase` `cleanup-merged` `pre-merge` `fix-ci` `release` `nessun-dorma` の 11 スキルを提供しなければならない（MUST）。加えて `mr` `mr-main` `mr-qa` `merge-develop` `switch-develop-branch` は対応するスキルを呼ぶだけのエイリアスとして提供し、モデルからの自動起動を無効にする。

#### Scenario: エイリアスの起動
- **WHEN** ユーザーが `/mr-qa` を実行する
- **THEN** `pr` スキルが対象 `qa` で実行され、エイリアス自身は追加の手順を持たない

### Requirement: 本文の言語と生成物の言語
スキル本文は英語で書かれなければならない（MUST）。コミットメッセージ、PR / MR のタイトルと説明、ユーザーへの報告は、ユーザー層またはリポジトリの指示で定めた言語（既定は日本語）で生成しなければならない（MUST）。

#### Scenario: 既定の言語
- **WHEN** 言語に関する指示が無いリポジトリで `commit` を実行する
- **THEN** コミットメッセージは日本語

### Requirement: ブランチ名の固定を持たない
スキル本文は `develop` `main` `qa` などの具体名を規則として持ってはならない（MUST NOT）。対象ブランチはセッションに注入された `<repo-context>` を使い、無ければ `session-start.sh --plain branches` を実行して得る。

#### Scenario: repo-context が無いセッション
- **WHEN** `<repo-context>` が注入されていないセッションで `sync-base` を実行する
- **THEN** スキルは `session-start.sh --plain branches` を実行して integration を得てから進める

### Requirement: pr の対象と意味論
`pr` は引数で対象ブランチを受け取る。引数なしは現在のブランチから integration への PR / MR を作り、CI 通過後の auto-merge を有効にする。引数が default と一致し integration と異なるときは、integration から default へのリリース PR / MR を作り、タイトルは `<default> YYYYMMDD HH:MM`（JST）とする。引数が qa と一致するときは現在のブランチから qa への PR / MR を作り、ソースブランチをマージ時に削除してはならない（MUST NOT）。

#### Scenario: 引数なし
- **WHEN** feature ブランチで `/pr` を実行する
- **THEN** 現在のブランチ → integration の PR / MR が作られ、auto-merge が設定される

#### Scenario: リリース PR
- **WHEN** default が `main`、integration が `develop` のリポジトリで `/pr main` を実行する
- **THEN** `develop` → `main` の PR / MR が作られ、タイトルは `main YYYYMMDD HH:MM` 形式

#### Scenario: QA PR
- **WHEN** qa が `qa` のリポジトリで `/pr qa` を実行する
- **THEN** 現在のブランチ → `qa` の PR / MR が作られ、マージ時にソースブランチが残る

#### Scenario: QA ブランチが無い
- **WHEN** qa が無いリポジトリで `/pr qa` を実行する
- **THEN** スキルは PR / MR を作らず、QA ブランチが未定義であることを報告する

### Requirement: auto-merge の安全弁
auto-merge を設定する前に CI の存在を確認し、CI が現れないときは即時マージを避けて中断し、その旨を URL とともに報告しなければならない（MUST）。auto-merge 設定後は状態を再確認し、即時マージされていた場合はその事実を報告する。

#### Scenario: チェックが登録されない
- **WHEN** PR 作成後 3 分待ってもチェックが 1 件も現れない
- **THEN** auto-merge を設定せず、PR の URL と理由を報告して終了する

### Requirement: 保護ブランチの扱い
`push` は保護判定を「AGENTS.md / CLAUDE.md の明記 → ホストの API → ブランチ名の推定」の順で行い、保護されたブランチに未コミットの変更がある場合は新規ブランチの作成をユーザーに確認しなければならない（MUST）。`--force` 系のオプションを使ってはならない（MUST NOT）。

#### Scenario: 明記がある
- **WHEN** AGENTS.md に「master は保護されていない」と明記されている
- **THEN** API 判定を行わず、そのまま現在のブランチへ push する

### Requirement: 破壊的操作の抑制
`sync-base` と `switch-base` は未コミットの変更があれば何もせず中止しなければならない（MUST）。`sync-base` は fast-forward を試み、できなければユーザーに確認せず `--no-ff` マージを行い、コンフリクト時はマージを中断したまま報告する。

#### Scenario: 未コミットの変更
- **WHEN** 作業ツリーに変更がある状態で `/switch-base` を実行する
- **THEN** ブランチは切り替わらず、変更ファイル一覧とともに中止が報告される

### Requirement: release のタグ形式
`release` は default ブランチの先端に `release_tag` 形式（既定 `vYY.MM.X`、当月の最大 X に 1 を足す）のタグを打ち、GitHub / GitLab のリリースを作成しなければならない（MUST）。同じタグやリリースが既にあれば作り直さない。

#### Scenario: 当月 2 回目
- **WHEN** 既に `v26.09.1` があり default の先端にタグが無い
- **THEN** 新しいタグは `v26.09.2`

### Requirement: プロジェクト履歴を持たない
スキル本文は特定プロジェクトの Issue 番号、廃止済みブランチの経緯、特定サービスの設定値を含んではならない（MUST NOT）。

#### Scenario: 監査
- **WHEN** `skills/git/**/SKILL.md` を `Issue #` や `staging` で検索する
- **THEN** 一致しない

### Requirement: Session トレーラ
`commit` は `<repo-context>` に `session:` があるとき、各コミットメッセージの末尾に `Session: <sid8>` トレーラを付けなければならない（MUST）。無いときは付けない。

#### Scenario: セッション内のコミット
- **WHEN** `<repo-context>` に `session: 3f2a9c1d` がある状態で `/commit` を実行する
- **THEN** 各コミットの末尾に `Session: 3f2a9c1d` がある
