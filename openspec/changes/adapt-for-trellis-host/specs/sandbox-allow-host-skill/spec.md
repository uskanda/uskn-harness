# Spec Delta

## ADDED Requirements

### Requirement: 閉じた環境では足さない
閉じた環境の間、スキルは、`uskn-harness sandbox-allow-host` が終了コード2で返した理由をそのまま示し、終えなければならない（MUST）。
スキルは、別の方法で接続先を足そうとしてはならない（MUST NOT）。
接続先は端末の土台が決めることも伝える。

#### Scenario: 閉じた環境でホストを渡す
- **WHEN** 閉じた環境で、ユーザーが `/sandbox-allow-host <gl.example.test>` を実行する
- **THEN** スキルは、閉じた環境では足さない理由を示して終わり、端末別設定は変わらない
