## Purpose

ループが仕様PRを完了とみなす条件（完了基準）。機械で判定できる計算的センサーを土台にし、計算できない仕様との照合だけを、実装役と別の文脈で動く監査役に判定させる。

## ADDED Requirements

### Requirement: 完了基準の3層
完了基準は、計算的センサー、仕様の網羅、監査役の判定の3層でなければならない（MUST）。
3層のすべてを満たしたときだけ、ループは仕様PRを完了とみなさなければならない（MUST）。

#### Scenario: 監査役だけが通す
- **WHEN** 監査役がpassを返すが、tasks.mdに未完了の行が残っている
- **THEN** 完了とはみなされない

### Requirement: 検証規約
計算的センサーは、そのリポジトリの検証規約をworktreeの最上位で実行しなければならない（MUST）。
検証規約は `make verify`、無ければ `pnpm run verify` か `npm run verify` の順に探す。検証は全体を走らせ、`make verify-fast` は使わない。
検証規約が見つからないリポジトリでは、`uskn-loop run` はループを始めずに止まらなければならない（MUST）。

#### Scenario: 検証の失敗
- **WHEN** 実装役が終わったあと、`make verify` が終了コード2を返す
- **THEN** 計算的センサーは失敗とし、出力の末尾を記録する

#### Scenario: 検証規約が無い
- **WHEN** Makefileにもpackage.jsonにもverifyが無いリポジトリで `uskn-loop run` を実行する
- **THEN** ループは始まらず、報告は検証規約の不在を伝える

### Requirement: 仕様の検証
計算的センサーは、`openspec validate <change> --strict` を実行し、失敗を計算的センサーの失敗としなければならない（MUST）。

#### Scenario: 仕様の崩れ
- **WHEN** 実装役がspecのシナリオの見出しを `###` に変える
- **THEN** 計算的センサーは失敗する

### Requirement: tasks.mdの完了
tasks.mdにチェックの付いていない行が残っているとき、計算的センサーは失敗しなければならない（MUST）。

#### Scenario: 未完了の行
- **WHEN** tasks.mdに `- [ ] 2.1` が残っている
- **THEN** 計算的センサーは失敗し、残った行が次の実装役に渡される

### Requirement: 未コミットの変更
実装役が終わったあとに未コミットの変更が残っているとき、計算的センサーは失敗しなければならない（MUST）。

#### Scenario: コミットし忘れ
- **WHEN** 実装役が `src/a.ts` を変えたままコミットせずに終わる
- **THEN** 計算的センサーは失敗し、`src/a.ts` の変更はpushされない

### Requirement: テストの削除とskip
基底ブランチとの差分がテストファイルを削除しているとき、計算的センサーはそれを修正必須の失敗としなければならない（MUST）。
基底ブランチとの差分がskipの印を追加しているとき、計算的センサーはそれを修正必須の失敗としなければならない（MUST）。
tasks.mdがその削除かskipを明示しているときは、失敗としてはならない（MUST NOT）。
skipの印は、`.skip(`、`xit(`、`xdescribe(`、`@pytest.mark.skip`、Goのt.Skip、batsの `skip` などとする。

#### Scenario: テストを消して通す
- **WHEN** 実装役が失敗するテストファイルを消し、tasks.mdにその指示は無い
- **THEN** 計算的センサーは修正必須の失敗とし、消したファイルの名前を記録する

### Requirement: 検証の設定の変更
基底ブランチとの差分が検証の設定を変えているとき、計算的センサーはそのファイルを監査役に確認させる項目として渡さなければならない（MUST）。
検証の設定は、Makefileのverifyのターゲット、package.jsonのscripts、CIの設定、textlintの設定とする。

#### Scenario: Makefileの変更
- **WHEN** 実装役がMakefileのverifyのターゲットを書き換える
- **THEN** 監査役への入力に、Makefileを確認する項目が含まれる

### Requirement: 監査役の起動
監査役は、実装役とは別の `claude -p` として起動しなければならない（MUST）。
起動の条件は、Opus 5.5、effort high、1回あたり `--max-budget-usd 3` と20分の時間の上限とする。
監査役に与える道具は、読み取り（Read、Grep、Glob）とBashに限らなければならない（MUST）。
監査役にEdit、Write、NotebookEditを与えてはならない（MUST NOT）。

#### Scenario: 監査役の道具
- **WHEN** 監査役を起動する
- **THEN** EditとWriteは使えず、テストと検証のコマンドはBashで実行できる

### Requirement: 仕様の網羅
監査役は、変更のspecsにある各シナリオについて、そのシナリオを確かめるテストを挙げなければならない（MUST）。
テストを挙げられないシナリオがあるとき、監査役の判定はfailでなければならない（MUST）。

#### Scenario: テストの無いシナリオ
- **WHEN** specsに3つのシナリオがあり、そのうち1つを確かめるテストが無い
- **THEN** 判定はfailで、そのシナリオが修正必須の指摘に入る

### Requirement: 判定の形
監査役は、`--json-schema` で次の4つの欄を持つ判定を返さなければならない（MUST）。

- 全体の判定：passかfail。
- シナリオごとの対応：シナリオ名、それを確かめるテスト、判定。
- 指摘の一覧：重さ（修正必須か推奨）、ファイルと行、要約、根拠。
- 人の判断が要るときの問い：無ければ空。

ループは判定を `structured_output` から読まなければならない（MUST）。

#### Scenario: 判定の読み取り
- **WHEN** 監査役が修正必須の指摘を1件含む判定を返す
- **THEN** ループはその判定をfailとして記録し、指摘を次のラウンドに渡す

### Requirement: 作業ツリーの復元
監査役が終わったあとにworktreeの追跡ファイル、未追跡ファイル、HEADのどれかが監査の前と違うとき、ループはworktreeを監査の前の状態に戻さなければならない（MUST）。

#### Scenario: 監査役がファイルを作る
- **WHEN** 監査役がテストの実行で `tmp/out.log` を作る
- **THEN** 監査のあと、`tmp/out.log` は消えている
