# ci-verify Specification

## Purpose
GitHub Actions で検証規約 `make verify` を走らせ、道具が無いまま緑になる穴を strict モードで閉じる。
Stop hook が走らないセッション（利用上限や中断）の変更も、push されれば検証される。

## Requirements

### Requirement: workflow のトリガーと内容
リポジトリは `.github/workflows/verify.yml` を持たなければならない（MUST）。
main への push、pull_request、workflow_dispatch で起動し、`make verify VERIFY_STRICT=1` を実行する。
同じ ref で実行中のジョブは新しい実行が cancel する。

#### Scenario: main への push
- **WHEN** main に commit を push する
- **THEN** workflow が起動し、`make verify` が失敗すれば run は失敗として表示される

#### Scenario: 手動実行
- **WHEN** GitHub の UI または `gh workflow run verify` で起動する
- **THEN** 同じ検証が走る

### Requirement: 道具はローカルと同じピンで入れる
workflow は道具を `uskn-harness sync --tools` で入れなければならない（MUST）。対象は mise.toml の道具（node、bats、shellcheck）と、`deps.json` でピンした npm global の CLI。
workflow に版を直書きしない。

#### Scenario: ピンの更新
- **WHEN** `deps.json` の textlint の version を上げて push する
- **THEN** workflow は変更なしで新しい版を入れて検証する

### Requirement: strict モード
`make verify VERIFY_STRICT=1` は、道具が無くて skip していたチェックを失敗にしなければならない（MUST）。
対象は openspec、openspec schema、shellcheck、bats、claude plugin validate、textlint、designmd。
失敗の出力にはチェック名と `VERIFY_STRICT` を含める。`VERIFY_STRICT` が未設定または `0` のときは今までどおり skip して終了コード 0。

#### Scenario: designmd が無い（strict）
- **WHEN** designmd が PATH に無い状態で `make verify-design VERIFY_STRICT=1` を実行する
- **THEN** 終了コードは非ゼロで、出力に `[design.md]` と `VERIFY_STRICT` が含まれる

#### Scenario: designmd が無い（既定）
- **WHEN** designmd が PATH に無い状態で `make verify-design` を実行する
- **THEN** 終了コードは 0 で、出力に `skipped` が含まれる

### Requirement: plugin validate を CI で走らせる
workflow は claude CLI を npm で入れなければならない（MUST）。`make verify` の `claude plugin validate --strict` は strict の対象に含める。
CLI がログインを要求するなど CI で安定しないと分かったときは、この要件を外して strict の免除対象にする。

#### Scenario: hooks.json の破損
- **WHEN** `plugins/uskn-harness/hooks/hooks.json` を壊して push する
- **THEN** workflow は `claude plugin validate --strict` で失敗する
