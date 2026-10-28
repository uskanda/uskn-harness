## MODIFIED Requirements

### Requirement: chezmoi の拒否の解除
セッションの許可ファイルがchezmoiのsource directoryを覆うとき、hookはchezmoiの下位コマンドを拒否してはならない（MUST NOT）。
source directoryは次の順に決める。コマンドの `--source` か `-S` の値。無ければ `chezmoi source-path` の出力。
それも得られなければ `~/.local/share/chezmoi`。
プロジェクトルートや許可リストに含まれることでは解除しない。
拒否の理由には、解除に使う `/add-dir <path>` の `<path>` として、そのsource directoryを書く。

#### Scenario: dotfiles を許可したあと
- **WHEN** source directoryが `~/dotfiles` で、ユーザーが `/add-dir ~/dotfiles` を実行したあと `chezmoi apply` を実行しようとする
- **THEN** 何も出力しない

#### Scenario: 許可が無い
- **WHEN** 許可ファイルが無い状態で `chezmoi apply` を実行しようとする
- **THEN** 拒否され、理由にsource directoryと `/add-dir` が含まれる

### Requirement: 許可ファイルの保護
コマンドが許可ファイル `sessions/<session_id>/allow` を名指しするとき、hookは `permissionDecision: deny` を返さなければならない（MUST）。
リダイレクト先や書く操作の対象の実体が許可ファイルのときも、同じく拒否する。symlinkや相対パスを通した場合を含む。
理由には、許可ファイルを書くのは `DirectoryAdded` のhookだけで、中身は `allow-repo.sh --list` で読める旨を書く。
許可ファイルに何が書かれていても、この拒否は解除しない。

#### Scenario: リダイレクトで許可を足す
- **WHEN** `echo ~/repos/b >> ~/.local/state/uskn-harness/sessions/<session_id>/allow` を実行しようとする
- **THEN** 拒否される

#### Scenario: allow-repo.sh の実行
- **WHEN** `allow-repo.sh --list --session <sid8>` を実行しようとする
- **THEN** 何も出力しない
