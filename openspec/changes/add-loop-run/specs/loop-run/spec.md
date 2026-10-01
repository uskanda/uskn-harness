## Purpose

1つの仕様PRについて、実装役、計算的センサー、監査役をラウンドごとに順に動かし、完了基準を満たすか停止条件に達するまで繰り返すコマンド `uskn-loop run`。段階1では手元から手動で起動する。

## ADDED Requirements

### Requirement: 起動
`uskn-loop run <番号またはURL>` は、対象のPRかMRを持つリポジトリのクローンの中で実行しなければならない（MUST）。
クローンの外で実行されたとき、`uskn-loop run` は何も作らずに止まり、理由を報告しなければならない（MUST）。
`uskn-loop run` は、originのURLからホストがGitHubかGitLabかを判定し、GitHubでは `gh`、GitLabでは `glab` を使わなければならない（MUST）。

#### Scenario: GitHubのクローンで起動する
- **WHEN** originがGitHubのクローンで `uskn-loop run 12` を実行する
- **THEN** PR #12を対象に、`gh` で情報を取得する

#### Scenario: GitLabのクローンで起動する
- **WHEN** originがGitLabのクローンで `uskn-loop run 7` を実行する
- **THEN** 7番のMRを対象に、`glab` で情報を取得する

### Requirement: 受け付け条件
`uskn-loop run` は、対象が次の4条件をすべて満たすときだけループを始めなければならない（MUST）。

- PRかMRがopenである
- headのブランチがforkではなく、同じリポジトリにある
- 作成者が、`gh` か `glab` でログインしているユーザーである
- archiveされていないchangeを、ちょうど1つ追加している。そのchangeの必須の成果物がそろっている

条件を1つでも満たさないとき、`uskn-loop run` はworktreeとコメントを作らずに止まり、満たさない条件を報告しなければならない（MUST）。

#### Scenario: forkからのPR
- **WHEN** headのブランチがforkにあるPRを渡す
- **THEN** ループは始まらず、forkであることが報告される

#### Scenario: 他人のPR
- **WHEN** 作成者が別のユーザーのPRを渡す
- **THEN** ループは始まらず、PRにコメントは書かれない

#### Scenario: changeが2つ
- **WHEN** 2つのchangeを追加しているPRを渡す
- **THEN** ループは始まらず、2つのchangeの名前が報告される

### Requirement: 二重実行の防止
同じPRかMRに対する `uskn-loop run` が既に動いている間、2つ目の `uskn-loop run` は何もせずに止まらなければならない（MUST）。

#### Scenario: 2つ目の起動
- **WHEN** PR #12のループが動いている間に、別の端末で `uskn-loop run 12` を実行する
- **THEN** 2つ目は、動いているループがあることを報告して終わる

### Requirement: 作業場所
`uskn-loop run` は、PRのheadのブランチを元にしたworktreeを作り、そこで作業しなければならない（MUST）。
worktreeの場所は、手元のクローンの `.claude/worktrees/loop-pr-<番号>` とする。
同じPRの2回目以降の実行では、`uskn-loop run` は既存のworktreeを使い回さなければならない（MUST）。
`uskn-loop run` は、実行したときの作業ツリーのファイルとブランチを変えてはならない（MUST NOT）。

#### Scenario: 作業ツリーに触れない
- **WHEN** 手元で `main` に未コミットの変更がある状態で `uskn-loop run 12` を実行する
- **THEN** 手元の作業ツリーとブランチはそのままで、作業は `.claude/worktrees/loop-pr-12` で行われる

### Requirement: 状態の記録と再開
`uskn-loop run` は、ラウンドごとの判定、費用の見積もり、ログを記録しなければならない（MUST）。
記録の場所は、状態ディレクトリの下の `loop/<host>/<owner>/<repo>/<番号>/` とする。
同じPRで中断したあとに再実行したとき、`uskn-loop run` はラウンドの数えと費用の合計を引き継いで続けなければならない（MUST）。
`--reset` が付いたとき、`uskn-loop run` は記録を捨てて1ラウンド目から始めなければならない（MUST）。

#### Scenario: 中断からの再開
- **WHEN** 2ラウンド目の途中で中断し、同じPRで `uskn-loop run 12` を再実行する
- **THEN** ラウンドの数えは2から続き、費用の合計は中断前の額を含む

#### Scenario: 最初から
- **WHEN** `uskn-loop run 12 --reset` を実行する
- **THEN** 1ラウンド目から始まる

### Requirement: ラウンドの流れ
各ラウンドで、`uskn-loop run` は実装役、計算的センサー、監査役の順に動かさなければならない（MUST）。
計算的センサーが1つでも失敗したラウンドでは、`uskn-loop run` は監査役を起動してはならない（MUST NOT）。

#### Scenario: 検証の失敗
- **WHEN** 実装役のあとで検証規約が失敗する
- **THEN** そのラウンドでは監査役は起動されず、失敗の出力が次のラウンドの実装役に渡される

### Requirement: 実装役の起動
`uskn-loop run` は、実装役を無人の `claude -p` として起動しなければならない（MUST）。
起動の条件は、権限モードauto、`--permission-prompts none`、1回あたり `--max-budget-usd 10` と60分の時間の上限とする。
1ラウンド目では、実装役への指示は `/opsx:apply <change>` でなければならない（MUST）。
2ラウンド目以降では、実装役への指示は、前のラウンドの修正必須の指摘と、失敗した計算的センサーの出力を含まなければならない（MUST）。
実装役のモデルとeffortは、ユーザー設定の既定値に従う。

#### Scenario: 2ラウンド目の指示
- **WHEN** 1ラウンド目の監査役が修正必須の指摘を2件返す
- **THEN** 2ラウンド目の実装役への指示に、その2件の要約とファイルの場所が含まれる

### Requirement: ラウンドごとのpush
各ラウンドで実装役が終わったとき、`uskn-loop run` は新しいコミットをPRのheadのブランチへpushしなければならない（MUST）。
`uskn-loop run` は、PRのheadのブランチ以外のブランチへpushしてはならない（MUST NOT）。

#### Scenario: 途中経過が見える
- **WHEN** 1ラウンド目の実装役が3つのコミットを作る
- **THEN** 監査役の判定を待たずに、その3つのコミットがPRに現れる

### Requirement: 停止条件
`uskn-loop run` は、次のどれかに当たったとき、ループを止めなければならない（MUST）。

- ラウンドの数が5に達し、完了基準を満たしていない
- PRごとの費用の見積もりの合計が40ドルを超えた
- 連続する2ラウンドで、修正必須の指摘と失敗した計算的センサーの集合が同じだった
- 監査役が、人の判断が要る問いを返した
- 監査役が、決まった形の判定を返さなかった
- pushが拒否された
- PRかMRが基底ブランチと衝突している

費用は、`claude -p` が返す `total_cost_usd` の見積もりで数える。

#### Scenario: 進展なし
- **WHEN** 2ラウンド目と3ラウンド目で、修正必須の指摘が同じ1件だけだった
- **THEN** 3ラウンド目の終わりでループが止まる

#### Scenario: 回数の上限
- **WHEN** 5ラウンド目が終わっても完了基準を満たさない
- **THEN** ループが止まり、6ラウンド目は始まらない

### Requirement: 完了時の扱い
完了基準を満たしたとき、`uskn-loop run` はPRかMRのdraftを解除し、worktreeを消し、終了コード0で終わらなければならない（MUST）。

#### Scenario: 完了
- **WHEN** 2ラウンド目で完了基準を満たす
- **THEN** PRはdraftでなくなり、`.claude/worktrees/loop-pr-12` は消え、終了コードは0

### Requirement: 停止時の扱い
停止条件に当たったとき、`uskn-loop run` はPRかMRをdraftのまま残し、worktreeを残し、終了コード3で終わらなければならない（MUST）。

#### Scenario: 停止
- **WHEN** 監査役が人の判断が要る問いを返す
- **THEN** PRはdraftのままで、worktreeは残り、終了コードは3

### Requirement: 人の操作に残すもの
`uskn-loop run` は、PRかMRをマージしてはならない（MUST NOT）。
`uskn-loop run` は、changeをarchiveしてはならない（MUST NOT）。
`uskn-loop run` は、PRかMRにラベルを付けてはならない（MUST NOT）。

#### Scenario: 完了後
- **WHEN** 完了基準を満たしてループが終わる
- **THEN** PRはopenのままで、`openspec/changes/<change>/` はarchiveされていない
