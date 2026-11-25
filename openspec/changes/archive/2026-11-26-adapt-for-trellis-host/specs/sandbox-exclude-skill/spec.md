# Spec Delta

## ADDED Requirements

### Requirement: 閉じた環境では足さない
閉じた環境の間、スキルは、`uskn-harness sandbox-exclude` が終了コード2で返した理由をそのまま示し、終えなければならない（MUST）。
スキルは、別の方法でsandboxの外に出そうとしてはならない（MUST NOT）。
外に出すコマンドは端末の土台が決めることも伝える。

#### Scenario: 閉じた環境で道具を渡す
- **WHEN** 閉じた環境で、ユーザーが `/sandbox-exclude terraform` を実行する
- **THEN** スキルは、閉じた環境では足さない理由を示して終わり、端末別設定は変わらない
