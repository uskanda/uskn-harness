# verify-gate Specification

## Purpose
エージェントが応答を終えようとしたとき、そのセッションで作業ツリーが変わっていれば検証規約を実行し、失敗している間は終了させない hook。

## Requirements

### Requirement: 変化があるときだけ実行
Stop hook は現在の指紋を計算しなければならない（MUST）。
開始時の `baseline`、または前回成功時に記録した `verified` と一致するときは、何もせず終了コード 0 で終わる。
`baseline` が無いときは現在の指紋を `baseline` として記録し、今回は検証しない。

#### Scenario: 読むだけのセッション
- **WHEN** ファイルを変更していない状態で Stop が発火する
- **THEN** 検証コマンドは実行されず、出力は空

#### Scenario: 成功後に変化なし
- **WHEN** 前回の Stop で検証が成功し、その後変更していない
- **THEN** 検証コマンドは再実行されない

### Requirement: 検証規約の探索
検証コマンドは `Makefile` に `verify` ターゲットがあれば `make verify`。
無ければ `package.json` の `scripts.verify` を使う。`pnpm-lock.yaml` があれば `pnpm run verify`、無ければ `npm run verify`。
どちらも無ければ何もしない（MUST）。

#### Scenario: Makefile
- **WHEN** リポジトリのルートに `verify:` ターゲットを持つ Makefile がある
- **THEN** `make verify` がリポジトリのルートで実行される

#### Scenario: 規約なし
- **WHEN** Makefile にも package.json にも verify が無い
- **THEN** 何も実行せず、出力は空

### Requirement: 失敗で block
検証が非ゼロで終わったとき、hook は `decision: block` と理由を返さなければならない（MUST）。
理由にはコマンド、終了コード、出力の末尾（最大 40 行）、ログの場所、回避方法（`USKN_SKIP_VERIFY=1`）を含める。
成功したときは現在の指紋を `verified` に記録し、何も出力しない。

#### Scenario: テスト失敗
- **WHEN** `make verify` が exit 2 で失敗する
- **THEN** JSON の `decision` が `block` で、`reason` にコマンド名と失敗出力が含まれる

#### Scenario: 成功
- **WHEN** `make verify` が成功する
- **THEN** 出力は空で、`sessions/<session_id>/verified` に指紋が書かれる

### Requirement: 実行しない条件
次のときは検証せず、終了コード 0 で終わらなければならない（MUST）。
`stop_hook_active` が true のとき。環境変数 `USKN_SKIP_VERIFY` が `1` のとき。
入力に `agent_type` があるとき（サブエージェント）。`cwd` が git 管理外のとき。

#### Scenario: 二重ブロックの防止
- **WHEN** `stop_hook_active` が true で、検証が失敗する状態
- **THEN** 出力は空

#### Scenario: 明示的な回避
- **WHEN** `USKN_SKIP_VERIFY=1` で Stop が発火する
- **THEN** 出力は空

### Requirement: 時間の上限
検証は hook の timeout（600 秒）内に収まるよう、570 秒で打ち切り、打ち切りは失敗として扱わなければならない（MUST）。

#### Scenario: 長い検証
- **WHEN** 検証が 570 秒を超える
- **THEN** block され、理由に打ち切りである旨が含まれる
