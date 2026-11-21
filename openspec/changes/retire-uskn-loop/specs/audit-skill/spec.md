## Purpose

実装したOpenSpecの変更を、実装と別の文脈で、specsと検証の結果に照らして判定する。外側のループの無い端末でも、自己評価の甘さを避けた完了の判定ができるようにする。

## ADDED Requirements

### Requirement: 会話の文脈を持たない実行
`audit` スキルは、frontmatterに `context: fork` と `background: false` を持たなければならない（MUST）。
`audit` スキルの `allowed-tools` は、`Bash`、`Read`、`Grep`、`Glob` だけでなければならない（MUST）。
`Edit`、`Write`、`NotebookEdit`、`AskUserQuestion` を持ってはならない（MUST NOT）。

#### Scenario: frontmatterの検査
- **WHEN** `skills/audit/SKILL.md` のfrontmatterを読む
- **THEN** `context: fork` と `background: false` があり、`allowed-tools` に `Edit` と `Write` が無い

### Requirement: 対象の変更
引数で変更の名前が渡されたとき、`audit` はその変更を判定しなければならない（MUST）。
引数が無いとき、`audit` は `uskn-archive-check --base origin/<統合ブランチ>` が出力した変更をすべて判定しなければならない（MUST）。
対象が1つも無いとき、`audit` は判定せずに、対象が無いことを報告しなければならない（MUST）。

#### Scenario: 引数なし
- **WHEN** ブランチが未archiveの変更 `add-x` に手を付けていて、引数なしで `/audit` を実行する
- **THEN** `add-x` が判定される

### Requirement: 未コミットの変更があるとき
作業ツリーに未コミットの変更があるとき、`audit` は判定を始めずに、先にコミットするよう報告しなければならない（MUST）。

#### Scenario: コミットし忘れ
- **WHEN** `src/a.ts` を変えたままコミットせずに `/audit add-x` を実行する
- **THEN** 判定は行われず、報告は `src/a.ts` の変更とコミットを求める

### Requirement: 計算的な確認
`audit` は、判定の前に4つの確認を自分で実行しなければならない（MUST）。
4つとは、検証規約、`openspec validate <name> --strict`、tasks.mdの未完了の行、`uskn-diff-check` である。
`uskn-diff-check` には、比べる先として `origin/<統合ブランチ>` を、許可の元のファイルとして変更の `tasks.md` を渡す。
これらのどれかが失敗したとき、判定はfailでなければならない（MUST）。

#### Scenario: 消したテスト
- **WHEN** 差分がテストファイルを消していて、tasks.mdにその指示が無い
- **THEN** 判定はfailで、消したファイルが修正必須の指摘に入る

### Requirement: シナリオごとのテスト
`audit` は、変更のspecsにある各シナリオについて、それを確かめるテストを挙げて実行しなければならない（MUST）。
テストを挙げられないシナリオがあるとき、判定はfailでなければならない（MUST）。

#### Scenario: テストの無いシナリオ
- **WHEN** specsに3つのシナリオがあり、そのうち1つを確かめるテストが無い
- **THEN** 判定はfailで、そのシナリオが修正必須の指摘に入る

### Requirement: 修正必須の範囲
`audit` が修正必須とする指摘は、次のものに限らなければならない（MUST）。

- 満たされていない要件かシナリオ
- テストの無いシナリオ
- 変更の成果物に理由の書かれていない検証の設定の変更
- 明らかな不具合
- 失敗した計算的な確認

書き方や好みについての指摘は、修正必須にしてはならない（MUST NOT）。

#### Scenario: 書き方の指摘
- **WHEN** 監査役が、変数の名前の好みについて指摘を見つける
- **THEN** その指摘は推奨にとどまり、判定を変えない

### Requirement: 判定の形
`audit` は、変更ごとに次の4つを報告しなければならない（MUST）。

- 全体の判定：passかfail
- シナリオごとの対応：シナリオ名、それを確かめるテスト、passかfail
- 指摘の一覧：重さ（修正必須か推奨）、ファイルと行、要約、根拠
- 人の判断が要るときの問い：無ければ書かない

#### Scenario: 修正必須の指摘が1件
- **WHEN** 他は通り、明らかな不具合が1件見つかる
- **THEN** 全体の判定はfailで、指摘の一覧にその不具合が修正必須として載る

### Requirement: 作業ツリーを変えない
`audit` は、追跡中のファイルとHEADを、判定の前と同じ状態で終えなければならない（MUST）。
判定の間に追跡中のファイルが変わったとき、`audit` は変わったファイルを報告し、HEADの内容に戻さなければならない（MUST）。
未追跡のファイルは消さずに報告する。

#### Scenario: テストが出力を書く
- **WHEN** テストの実行で、追跡中の `testdata/out.json` が書き換わる
- **THEN** 報告に `testdata/out.json` が載り、ファイルはHEADの内容に戻っている
