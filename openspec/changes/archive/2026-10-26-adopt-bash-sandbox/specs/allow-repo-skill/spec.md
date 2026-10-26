## ADDED Requirements

### Requirement: /add-dir の案内
許可を記録したとき、`allow-repo` スキルは、続けて `/add-dir <path>` を打つようユーザーに案内しなければならない（MUST）。
`<path>` は、許可ファイルに記録した実体のパスである。
sandboxの中のBashは、`/add-dir` で足したディレクトリにだけ書けるため。
スキルが `/add-dir` を自分で実行してはならない（MUST NOT）。ルートの外への書き込みを許すのは、ユーザーだけだからである。

#### Scenario: 許可の後の報告
- **WHEN** ユーザーが `/allow-repo ~/dotfiles` を実行する
- **THEN** 報告に、`~/dotfiles` の実体のパスを引数にした `/add-dir` の案内が含まれる

#### Scenario: 一覧の表示
- **WHEN** ユーザーが `/allow-repo --list` を実行する
- **THEN** `/add-dir` の案内は出ない
