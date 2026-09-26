# verify-gate Specification

## Purpose
エージェントが応答を終えようとしたとき、そのセッションで作業ツリーが変わっていれば検証規約を実行し、失敗している間は終了させないhook。

## Requirements

### Requirement: 変化があるときだけ実行
Stop hookは現在の指紋を計算しなければならない（MUST）。
開始時の `baseline`、または前回成功時に記録した `verified` と一致するときは、何もせず終了コード0で終わる。
`baseline` が無いときは現在の指紋を `baseline` として記録し、今回は検証しない。

#### Scenario: 読むだけのセッション
- **WHEN** ファイルを変更していない状態でStopが発火する
- **THEN** 検証コマンドは実行されず、出力は空

#### Scenario: 成功後に変化なし
- **WHEN** 前回のStopで検証が成功し、その後変更していない
- **THEN** 検証コマンドは再実行されない

### Requirement: 検証規約の探索
hookは `cwd` のgitルートで検証コマンドを決め、そこで実行しなければならない（MUST）。
`CLAUDE_PROJECT_DIR` がほかの場所を指していても、`cwd` のgitルートを使う。
検証コマンドは、`Makefile` に `verify-fast` ターゲットがあれば `make verify-fast`、無く `verify` ターゲットがあれば `make verify`。
どちらも無ければ `package.json` の `scripts.verify` を使う。`pnpm-lock.yaml` があれば `pnpm run verify`、無ければ `npm run verify`。
どれも無ければ何もしない（MUST）。

#### Scenario: Makefile
- **WHEN** リポジトリのルートに `verify:` ターゲットを持つMakefileがある
- **THEN** `make verify` がリポジトリのルートで実行される

#### Scenario: verify-fast がある
- **WHEN** リポジトリのルートのMakefileに `verify:` と `verify-fast:` の両方のターゲットがある
- **THEN** `make verify-fast` だけが実行される

#### Scenario: worktree
- **WHEN** `CLAUDE_PROJECT_DIR` が `~/repos/a` で、`cwd` が `~/repos/a/.claude/worktrees/w` のセッションでStopが発火する
- **THEN** 検証は `~/repos/a/.claude/worktrees/w` で実行される

#### Scenario: 規約なし
- **WHEN** Makefileにもpackage.jsonにもverifyが無い
- **THEN** 何も実行せず、出力は空

### Requirement: 失敗で block
検証が非ゼロで終わったとき、hookは `decision: block` と理由を返さなければならない（MUST）。
理由にはコマンド、終了コード、出力の末尾（最大40行）、ログの場所、回避方法（`USKN_SKIP_VERIFY=1`）を含める。
出力のJSONはトップレベルの `decision` と `reason` だけを持つ。Stop hookのschemaに無い `hookSpecificOutput` を付けてはならない（MUST NOT）。
成功したときは現在の指紋を `verified` に記録し、何も出力しない。

#### Scenario: テスト失敗
- **WHEN** `make verify` がexit 2で失敗する
- **THEN** JSONの `decision` が `block` で、`reason` にコマンド名と失敗出力が含まれる。`hookSpecificOutput` は無い

#### Scenario: 成功
- **WHEN** `make verify` が成功する
- **THEN** 出力は空で、`sessions/<session_id>/verified` に指紋が書かれる

### Requirement: 時間の上限
検証はhookのtimeout（600秒）内に収まるよう、570秒で打ち切り、打ち切りは失敗として扱わなければならない（MUST）。
GNUの `timeout` が無い環境では `gtimeout` を使い、それも無ければ同じ上限を別の方法でかける。打ち切りでは検証が起こしたプロセスもすべて止める。

#### Scenario: 長い検証
- **WHEN** 検証が570秒を超える
- **THEN** blockされ、理由に打ち切りである旨が含まれる

#### Scenario: timeout の無い macOS
- **WHEN** PATHに `timeout` と `gtimeout` のどちらも無い環境で、検証が上限を超える
- **THEN** 検証は打ち切られ、blockの理由に打ち切りである旨が含まれる

### Requirement: 検証を省く条件
次のときは検証せず、終了コード0で終わらなければならない（MUST）。
環境変数 `USKN_SKIP_VERIFY` が `1` のとき。入力に `agent_type` があるとき（サブエージェント）。`cwd` がgit管理外のとき。
`stop_hook_active` がtrueであることは、検証を省く理由にならない。

#### Scenario: 明示的な回避
- **WHEN** `USKN_SKIP_VERIFY=1` でStopが発火する
- **THEN** 出力は空

#### Scenario: サブエージェント
- **WHEN** 検証の失敗する状態で、入力に `agent_type` を持つStopが発火する
- **THEN** 検証は実行されず、出力は空

### Requirement: blockの回数の上限
検証の失敗が続く間、hookは1ターンに3回までblockしなければならない（MUST）。
`stop_hook_active` がfalseのStopをターンの始まりとし、その時点で回数を0に戻す。
`stop_hook_active` がtrueのStop（blockのあとの再試行）でも検証する。

#### Scenario: 再試行でも失敗
- **WHEN** blockのあと `stop_hook_active` がtrueのStopが発火し、検証がまだ失敗する
- **THEN** 再びblockされる

#### Scenario: 再試行で成功
- **WHEN** blockのあとエージェントが直し、`stop_hook_active` がtrueのStopで検証が成功する
- **THEN** 出力は空で、`verified` に指紋が書かれる

#### Scenario: 次のターン
- **WHEN** 前のターンで3回blockされ、次のターンの最初のStop（`stop_hook_active` がfalse）で検証が失敗する
- **THEN** blockされる

### Requirement: 上限に達したときの終わり方
同じターンで3回blockしたあと検証がまだ失敗しているとき、hookはblockせず、`systemMessage` を返さなければならない（MUST）。
`systemMessage` には、作業ツリーが失敗したまま終わること、コマンド、終了コード、ログの場所を書く。

#### Scenario: 4回目の失敗
- **WHEN** 同じターンで3回blockされたあと、`stop_hook_active` がtrueのStopで検証がまだ失敗する
- **THEN** JSONに `decision` は無く、`systemMessage` にコマンドとログの場所が含まれる

### Requirement: 変化の無いままの再試行
blockのあと作業ツリーが前回の失敗から変わらないままStopが発火したとき、hookは検証を再実行してはならない（MUST NOT）。
このときは前回の結果を失敗として扱い、回数の上限に従う。

#### Scenario: 直さずに終えようとする
- **WHEN** blockのあとファイルを変えずに、`stop_hook_active` がtrueのStopが発火する
- **THEN** 検証コマンドは実行されず、前回と同じ理由でblockされる
