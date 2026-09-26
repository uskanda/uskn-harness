## MODIFIED Requirements

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

## REMOVED Requirements

### Requirement: 実行しない条件
**Reason**: `stop_hook_active` がtrueのときに黙ると、blockのあとの再試行が検証されずに終わる。この条件を外した要件「検証を省く条件」に置き換える。
**Migration**: 残りの条件（`USKN_SKIP_VERIFY=1`、サブエージェント、git管理外）は「検証を省く条件」が引き継ぐ。blockの繰り返しは「blockの回数の上限」が抑える。

## ADDED Requirements

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
