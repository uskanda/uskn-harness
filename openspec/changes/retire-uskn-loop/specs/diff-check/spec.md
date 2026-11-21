## Purpose

基底ブランチとの差分から、テストファイルの削除、skipの印の追加、検証の設定の変更を見つける。テストを消すか止めて検証を通した変更を、エージェントが報告の前に見つけられる。

## ADDED Requirements

### Requirement: 比べる範囲
`uskn-diff-check --base <ref> [DIR]` は、`<ref>` とHEADのmerge-baseから、DIRの作業ツリーまでの差分を調べなければならない（MUST）。
DIRを省いたときは、現在のディレクトリを含むgitの作業ツリーを調べる。
差分は、コミット済みの変更と、まだコミットしていない追跡中のファイルの変更を含む。
未追跡のファイルは調べない。

#### Scenario: コミット前の削除
- **WHEN** 追跡中の `tests/a.test.ts` を消し、コミットせずに `uskn-diff-check --base origin/main` を実行する
- **THEN** `test-deleted tests/a.test.ts` が出力される

### Requirement: テストファイルの削除
差分がテストファイルを消しているとき、`uskn-diff-check` はそのパスを `test-deleted <path>` の1行で出力しなければならない（MUST）。
テストファイルは、パスに `test`、`spec`、`__tests__` のいずれかを含むか、`.bats` で終わるファイルとする。
`openspec/` の下のファイルはテストファイルとみなしてはならない（MUST NOT）。

#### Scenario: 仕様の文書を消す
- **WHEN** 差分が `openspec/specs/x/spec.md` を消している
- **THEN** `test-deleted` の行は出力されない

### Requirement: skipの印の追加
差分がテストファイルにskipの印の行を足しているとき、`uskn-diff-check` は `skip-added <path>: <行>` の1行で出力しなければならない（MUST）。
skipの印は、ファイルの種類ごとに次のものとする。

- `.bats`：行頭の `skip`
- JavaScriptとTypeScript：`.skip(`、`xit(`、`xdescribe(`、`xtest(`
- Python：`@pytest.mark.skip`、`unittest.skip`
- Goの `_test.go`：`t.Skip`、`t.Skipf`、`t.SkipNow` の呼び出し

#### Scenario: Goのテストを止める
- **WHEN** 差分が `pkg/a_test.go` に `t.Skip` を呼ぶ行を足している
- **THEN** `skip-added pkg/a_test.go:` で始まる行が出力される

### Requirement: 検証の設定の変更
差分が検証の設定のファイルを変えているとき、`uskn-diff-check` はそのパスを `verify-setting <path>` の1行で出力しなければならない（MUST）。
検証の設定のファイルは、`Makefile`、`GNUmakefile`、`package.json`、`.gitlab-ci.yml` とする。
`.github/workflows/` の下のファイルとtextlintの設定も含む。
この行だけでは、終了コードを1にしてはならない（MUST NOT）。変更に理由があるかは、読む人か監査役が判断する。

#### Scenario: Makefileだけを変えた
- **WHEN** 差分が `Makefile` だけを変えている
- **THEN** `verify-setting Makefile` が出力され、終了コードは0

### Requirement: 許可の元のファイル
`--allow-from <file>` が渡されたとき、`uskn-diff-check` は、そのファイルに書かれたパスを出力から除かなければならない（MUST）。
除くのは `test-deleted` と `skip-added` の行だけとする。
書かれているかは、パスの文字列がファイルの中にそのまま現れるかで決める。
変更の `tasks.md` を渡すと、tasksが求めた削除とskipを除いて判定できる。

#### Scenario: tasksが削除を求めている
- **WHEN** 差分が `tests/old.bats` を消し、変更の `tasks.md` にそのファイルを消す項目がある。その `tasks.md` を `--allow-from` に渡して実行する
- **THEN** `test-deleted tests/old.bats` は出力されず、終了コードは0

### Requirement: 終了コード
`test-deleted` か `skip-added` の行を1つでも出力したとき、`uskn-diff-check` は終了コード1で終わらなければならない（MUST）。
それ以外で判定できたときは、終了コード0で終わらなければならない（MUST）。
`<ref>` が無いときや、merge-baseが求まらないとき、作業ツリーの外で実行したときは、終了コード2で終わり、標準エラーに理由を出さなければならない（MUST）。
判定は、gitだけで行う。

#### Scenario: 比べる先が無い
- **WHEN** `origin/main` の無いリポジトリで `uskn-diff-check --base origin/main` を実行する
- **THEN** 終了コードは2で、標準出力は空

#### Scenario: 何も見つからない
- **WHEN** 差分が `src/a.ts` だけを変えている
- **THEN** 何も出力されず、終了コードは0
