## ADDED Requirements

### Requirement: sandbox の外で動かすコマンドの追加
`uskn-harness sandbox-exclude <pattern>` は、端末別設定の `sandbox.excludedCommands` にパターンを1つ足さなければならない（MUST）。
端末別設定の置き場は `~/.config/uskn-harness/settings.json` である。
既にあるパターンは足さない。端末別設定が無ければ作る。
続けて、ユーザー層の設定の手順だけをsyncと同じ規則で実行し、liveに反映する。
`<pattern>` が空のときと、`*` だけのときは、何も変えずに終了コード2で終える。

#### Scenario: terraform を足す
- **WHEN** `uskn-harness sandbox-exclude 'terraform *'` を実行する
- **THEN** 端末別設定とliveの `sandbox.excludedCommands` に `terraform *` があり、設定断片の要素もliveに残る

#### Scenario: すべてを外に出そうとする
- **WHEN** `uskn-harness sandbox-exclude '*'` を実行する
- **THEN** 端末別設定は変わらず、終了コードは2

### Requirement: sandbox の外で動かすコマンドの一覧と削除
`uskn-harness sandbox-exclude --list` は、liveの `sandbox.excludedCommands` を1行ずつ出力しなければならない（MUST）。
各行には、設定断片の要素か端末別設定の要素かを示す。
`uskn-harness sandbox-exclude --remove <pattern>` は、端末別設定からそのパターンを消し、liveに反映しなければならない（MUST）。
設定断片の要素は `--remove` で消してはならない（MUST NOT）。消そうとしたときは、設定断片を直すPRが要ることを出力し、終了コード2で終える。

#### Scenario: 端末で足したものを外す
- **WHEN** `terraform *` を足した後に `uskn-harness sandbox-exclude --remove 'terraform *'` を実行する
- **THEN** 端末別設定とliveの `sandbox.excludedCommands` から `terraform *` が消える

#### Scenario: 既定値を外そうとする
- **WHEN** `uskn-harness sandbox-exclude --remove 'git *'` を実行する
- **THEN** 何も変わらず、出力に設定断片を直すPRの案内が含まれ、終了コードは2
