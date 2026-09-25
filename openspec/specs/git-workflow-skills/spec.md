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
`<repo-context>` に保護ブランチの宣言があるとき、`push` は宣言だけで保護を判定しなければならない（MUST）。
このとき `push` は、指示ファイルの読み込み、ホストのAPI、ブランチ名からの推定を使ってはならない（MUST NOT）。
宣言が無いとき、`push` は「AGENTS.md / CLAUDE.mdの明記 → ホストのAPI → ブランチ名からの推定」の順で保護を判定する。
保護されたブランチに未コミットの変更があるときは、新規ブランチの作成をユーザーに確認しなければならない（MUST）。
`--force` 系のオプションを使ってはならない（MUST NOT）。

#### Scenario: 宣言が none
- **WHEN** `<repo-context>` に `protected: none (AGENTS.md)` があり、`main` に未コミットの変更がある
- **THEN** ファイルとAPIを見ずにcommitし、`main` へpushする

#### Scenario: 宣言のパターンに一致
- **WHEN** `<repo-context>` に `protected: main, release/* (AGENTS.md)` があり、`release/1.2` に未コミットの変更がある
- **THEN** APIを呼ばずに保護ブランチと判定し、新規ブランチの作成をユーザーに確認する

#### Scenario: 明記がある
- **WHEN** 保護ブランチの宣言が無く、AGENTS.mdに「masterは保護されていない」と明記されている
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

### Requirement: commit の実行の形
`commit` はforkで動き、`model: sonnet` と `effort: low` を使わなければならない（MUST）。

#### Scenario: ユーザーが直接打つ
- **WHEN** ユーザーが `/commit` を打つ
- **THEN** sonnetのsubagentが会話の文脈を持たずにコミットし、報告だけが返る

### Requirement: commit の引数
`commit` は引数を `[課題ID] [指示の文]` として読まなければならない（MUST）。
最初の語が数字か、`#` の付いた数字のとき、それを課題IDとし、各要約行の先頭に `#<番号>` と空白を付ける。
残りの文は、コミットの順番、分け方、要約行、本文を縛る指示として従う。
引数が無いときは、課題IDも追加の指示も無い動きでコミットする。

#### Scenario: 課題IDだけ
- **WHEN** `/commit 123` を実行する
- **THEN** 各要約行が `#123` と空白で始まる

#### Scenario: 指示の文
- **WHEN** `archive-push` が、archiveのパスを1つのコミットにして要約行を指定する指示の文を引数で渡す
- **THEN** archiveのパスは、指定された要約行を持つ1つのコミットになる

#### Scenario: 引数なし
- **WHEN** 引数なしで `/commit` を実行する
- **THEN** 変更の目的だけでコミットを分け、要約行に番号を付けない

### Requirement: commit の分割
`commit` は変更を目的ごとに1〜5個のコミットに分けなければならない（MUST）。
目的が1つの変更は、1つのコミットにする。

#### Scenario: 目的が1つの変更
- **WHEN** 1つの目的のための実装、テスト、specが未コミットで残っている
- **THEN** コミットは1つできる

### Requirement: Session トレーラ
`commit` は各コミットメッセージの末尾に `Session: <sid8>` トレーラを付けなければならない（MUST）。
`<sid8>` はセッションIDの先頭8文字で、`${CLAUDE_SESSION_ID}` から得る。
セッションIDを得られないときだけ、トレーラを付けない。

#### Scenario: セッション内のコミット
- **WHEN** IDの先頭が `3f2a9c1d` のセッションから `/commit` を実行する
- **THEN** 各コミットの末尾に `Session: 3f2a9c1d` がある

#### Scenario: 別のスキルから呼んだコミット
- **WHEN** `push` から呼ばれたforkの `commit` がコミットする
- **THEN** トレーラの値は、`push` を実行したセッションのIDの先頭8文字になる

### Requirement: 日本語の成果物の検査
`commit` と `pr` スキルは、日本語で書いた本文をtextlintで確認しなければならない（MUST）。
本文はファイルではないため、一時ファイルに書いてから検査する。
textlintが使えないときは検査を飛ばし、その旨を報告する。指摘が残るときは直してから確定する。

#### Scenario: 日本語のコミットメッセージ
- **WHEN** 日本語のコミットメッセージを書く
- **THEN** 確定の前にtextlintで確認され、指摘があれば直される

#### Scenario: textlint が無い
- **WHEN** textlintがPATHに無い
- **THEN** 検査は飛ばされ、コミットは続行する
