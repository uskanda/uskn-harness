## MODIFIED Requirements

### Requirement: スキル向けの短いコマンド
プラグインは `bin/` に、スキルがBashで呼ぶ補助スクリプトの短いコマンドを持たなければならない（MUST）。
`uskn-repo-context` は `session-start.sh` を、`uskn-terms-check` は `terms-check.sh` を、同じ引数で実行する。
`uskn-archive-check` も同じく、`archive-check.sh` を同じ引数で実行する。
終了コードと出力は、元のスクリプトと同じにする。
プラグインがsymlinkを通して読み込まれていても動く。

#### Scenario: ブランチモデルの取得
- **WHEN** gitリポジトリの中で `uskn-repo-context --plain branches` を実行する
- **THEN** `session-start.sh --plain branches` と同じ4行が出力される

#### Scenario: 用語の検査
- **WHEN** 実在しない名前を含む文書に `uskn-terms-check` を実行する
- **THEN** 指摘が出力され、終了コードは1

#### Scenario: 未archiveの変更の判定
- **WHEN** 未archiveの変更を足したブランチで `uskn-archive-check --base origin/main` を実行する
- **THEN** `archive-check.sh --base origin/main` と同じ出力と終了コードになる

## ADDED Requirements

### Requirement: 未archiveの変更の判定
`uskn-archive-check --base <ref>` は、未archiveの変更を1行に1つ出力しなければならない（MUST）。
対象は、`<ref>` とHEADのmerge-baseからHEADまでの差分で手を付けられ、HEADでまだarchiveされていない変更である。
変更とは `openspec/changes/<name>/` のことで、`openspec/changes/archive/` の下は数えない。
HEADの木で `openspec/changes/<name>/.archive-later` を持つ変更は、出力してはならない（MUST NOT）。
終了コードは、出力があれば1、無ければ0とする。
判定は、gitだけで行う。

#### Scenario: 変更を足したブランチ
- **WHEN** `origin/main` から分かれ、`openspec/changes/add-x/proposal.md` をコミットしたブランチで実行する
- **THEN** `add-x` が出力され、終了コードは1

#### Scenario: archive 済み
- **WHEN** 同じブランチで、`add-x` を `openspec/changes/archive/` へ移してコミットした後に実行する
- **THEN** 何も出力されず、終了コードは0

#### Scenario: archive保留の宣言
- **WHEN** `openspec/changes/add-x/.archive-later` もコミットしたブランチで実行する
- **THEN** 何も出力されず、終了コードは0

#### Scenario: ブランチが手を付けていない変更
- **WHEN** `origin/main` にもとからある変更 `old-y` に、ブランチが手を付けていない
- **THEN** `old-y` は出力されない

### Requirement: 判定できないときの終了コード
`<ref>` が無いときや、作業ツリーの外で実行したときなど判定できないとき、`uskn-archive-check` は終了コード2で終わり、標準エラーに理由を出さなければならない（MUST）。

#### Scenario: 比べる先が無い
- **WHEN** `origin/main` の無いリポジトリで `uskn-archive-check --base origin/main` を実行する
- **THEN** 終了コードは2で、標準出力は空
