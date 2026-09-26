## MODIFIED Requirements

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
