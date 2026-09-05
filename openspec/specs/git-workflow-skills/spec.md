# git-workflow-skills Specification

## Purpose
どのリポジトリでも同じ名前で呼べるgitワークフロー用スキルの集合。ブランチ名は `branch-model` の解決結果に従い、プロジェクト固有の履歴を持たない。

## Requirements

### Requirement: スキルの集合と命名
システムは次の11スキルを提供しなければならない（MUST）。
`commit` `push` `pr` `sync-base` `switch-base` `rebase` `cleanup-merged` `pre-merge` `fix-ci` `release` `nessun-dorma`。
加えて `mr` `mr-main` `mr-qa` `merge-develop` `switch-develop-branch` をエイリアスとして提供する。
エイリアスは対応するスキルを呼ぶだけで、モデルからの自動起動を無効にする。

#### Scenario: エイリアスの起動
- **WHEN** ユーザーが `/mr-qa` を実行する
- **THEN** `pr` スキルが対象 `qa` で実行され、エイリアス自身は追加の手順を持たない

### Requirement: 本文の言語と生成物の言語
スキル本文は英語で書かれなければならない（MUST）。コミットメッセージ、PR / MRのタイトルと説明、ユーザーへの報告は、ユーザー層またはリポジトリの指示で定めた言語（既定は日本語）で生成しなければならない（MUST）。

#### Scenario: 既定の言語
- **WHEN** 言語に関する指示が無いリポジトリで `commit` を実行する
- **THEN** コミットメッセージは日本語

### Requirement: ブランチ名の固定を持たない
スキル本文は `develop` `main` `qa` などの具体名を規則として持ってはならない（MUST NOT）。対象ブランチはセッションに注入された `<repo-context>` を使い、無ければ `session-start.sh --plain branches` を実行して得る。

#### Scenario: repo-context が無いセッション
- **WHEN** `<repo-context>` が注入されていないセッションで `sync-base` を実行する
- **THEN** スキルは `session-start.sh --plain branches` を実行してintegrationを得てから進める

### Requirement: pr の対象と意味論
`pr` は引数で対象ブランチを受け取る。
引数なしは現在のブランチからintegrationへのPR / MRを作り、CI通過後のauto-mergeを有効にする。
引数がdefaultと一致し、かつintegrationと異なるときは、integrationからdefaultへのリリースPR / MRを作る。
そのタイトルは `<default> YYYYMMDD HH:MM`（JST）とする。
引数がqaと一致するときは現在のブランチからqaへのPR / MRを作る。
このときソースブランチをマージ時に削除してはならない（MUST NOT）。

#### Scenario: 引数なし
- **WHEN** featureブランチで `/pr` を実行する
- **THEN** 現在のブランチ → integrationのPR / MRが作られ、auto-mergeが設定される

#### Scenario: リリース PR
- **WHEN** defaultが `main`、integrationが `develop` のリポジトリで `/pr main` を実行する
- **THEN** `develop` → `main` のPR / MRが作られ、タイトルは `main YYYYMMDD HH:MM` 形式

#### Scenario: QA PR
- **WHEN** qaが `qa` のリポジトリで `/pr qa` を実行する
- **THEN** 現在のブランチ → `qa` のPR / MRが作られ、マージ時にソースブランチが残る

#### Scenario: QA ブランチが無い
- **WHEN** qaが無いリポジトリで `/pr qa` を実行する
- **THEN** スキルはPR / MRを作らず、QAブランチが未定義であることを報告する

### Requirement: auto-merge の安全弁
auto-mergeを設定する前にCIの存在を確認し、CIが現れないときは即時マージを避けて中断し、その旨をURLとともに報告しなければならない（MUST）。auto-merge設定後は状態を再確認し、即時マージされていた場合はその事実を報告する。

#### Scenario: チェックが登録されない
- **WHEN** PR作成後3分待ってもチェックが1件も現れない
- **THEN** auto-mergeを設定せず、PRのURLと理由を報告して終了する

### Requirement: 保護ブランチの扱い
`push` は保護判定を「AGENTS.md / CLAUDE.mdの明記 → ホストのAPI → ブランチ名の推定」の順で行う。
保護されたブランチに未コミットの変更があるときは、新規ブランチの作成をユーザーに確認しなければならない（MUST）。
`--force` 系のオプションを使ってはならない（MUST NOT）。

#### Scenario: 明記がある
- **WHEN** AGENTS.mdに「masterは保護されていない」と明記されている
- **THEN** APIでは判定せず、そのまま現在のブランチへpushする

### Requirement: 破壊的操作の抑制
`sync-base` と `switch-base` は未コミットの変更があれば何もせず中止しなければならない（MUST）。`sync-base` はfast-forwardを試み、できなければユーザーに確認せず `--no-ff` マージを行い、コンフリクト時はマージを中断したまま報告する。

#### Scenario: 未コミットの変更
- **WHEN** 作業ツリーに変更がある状態で `/switch-base` を実行する
- **THEN** ブランチは切り替わらず、変更ファイル一覧とともに中止が報告される

### Requirement: release のタグ形式
`release` はdefaultブランチの先端に `release_tag` 形式のタグを打たなければならない（MUST）。
既定は `vYY.MM.X` で、当月の最大Xに1を足す。
続けてGitHub / GitLabのリリースを作成する。同じタグやリリースが既にあれば作り直さない。

#### Scenario: 当月 2 回目
- **WHEN** 既に `v26.09.1` がありdefaultの先端にタグが無い
- **THEN** 新しいタグは `v26.09.2`

### Requirement: プロジェクト履歴を持たない
スキル本文は特定プロジェクトのIssue番号、廃止済みブランチの経緯、特定サービスの設定値を含んではならない（MUST NOT）。

#### Scenario: 監査
- **WHEN** `skills/git/**/SKILL.md` を `Issue #` や `staging` で検索する
- **THEN** 一致しない

### Requirement: Session トレーラ
`commit` は `<repo-context>` に `session:` があるとき、各コミットメッセージの末尾に `Session: <sid8>` トレーラを付けなければならない（MUST）。無いときは付けない。

#### Scenario: セッション内のコミット
- **WHEN** `<repo-context>` に `session: 3f2a9c1d` がある状態で `/commit` を実行する
- **THEN** 各コミットの末尾に `Session: 3f2a9c1d` がある
