## ADDED Requirements

### Requirement: 未archiveの変更を持った統合の操作の拒否
統合の操作をしようとしたとき、`uskn-archive-check` が該当ありを返すなら、hookは `permissionDecision: deny` を返さなければならない（MUST）。
理由には、該当した変更の名前と、`/archive-push <name>` を実行するか `.archive-later` で宣言するかの案内を含める。
統合の操作と比べる先は、次のとおりとする。作業ディレクトリは、それまでの `cd` とgitの `-C` で決まる。

- `gh pr merge` と `glab mr merge`：`origin/<統合ブランチ>`
- 送り先が既定ブランチか統合ブランチの `git push`：`origin/<送り先>`。送り先は、refspecがあればその送り先、無ければ上流のブランチ、上流も無ければ現在のブランチとする

#### Scenario: 未archiveの変更があるときの gh pr merge
- **WHEN** `origin/main` から分かれて変更 `add-x` を足したブランチで、`gh pr merge 12 --auto --merge` を実行しようとする
- **THEN** 拒否され、理由に `add-x` と `/archive-push` が含まれる

#### Scenario: main への git push
- **WHEN** 統合ブランチが `main` で、変更 `add-x` を足した `main` から `git push origin main` を実行しようとする
- **THEN** 拒否される

#### Scenario: 作業ブランチへの git push
- **WHEN** 同じ変更を足した `change/add-x` から `git push -u origin HEAD` を実行しようとする
- **THEN** この判定では何も出力しない

#### Scenario: archive保留の宣言
- **WHEN** 変更 `add-x` に `.archive-later` があり、`gh pr merge 12` を実行しようとする
- **THEN** この判定では何も出力しない

### Requirement: 判定できない統合の操作は止めない
`uskn-archive-check` が判定できないとき（終了コード2）、hookはその統合の操作を拒否してはならない（MUST NOT）。

#### Scenario: 比べる先が無い
- **WHEN** `origin/main` の無いリポジトリで、`gh pr merge 12` を実行しようとする
- **THEN** この判定では何も出力しない
