# ci-verify Specification

## Purpose
GitHub Actionsで検証規約 `make verify` を走らせ、道具が無いまま緑になる穴をstrictモードで閉じる。
Stop hookが走らないセッション（利用上限や中断）の変更も、pushされれば検証される。

## Requirements

### Requirement: workflow のトリガーと内容
リポジトリは `.github/workflows/verify.yml` を持たなければならない（MUST）。
mainへのpush、pull_request、workflow_dispatchで起動し、`make verify VERIFY_STRICT=1` を実行する。
同じrefで実行中のジョブは新しい実行がcancelする。

#### Scenario: main への push
- **WHEN** mainにcommitをpushする
- **THEN** workflowが起動し、`make verify` が失敗すればrunは失敗として表示される

#### Scenario: 手動実行
- **WHEN** GitHubのUIまたは `gh workflow run verify` で起動する
- **THEN** 同じ検証が走る

### Requirement: 道具はローカルと同じピンで入れる
workflowは道具を `uskn-harness sync --tools` で入れなければならない（MUST）。対象はmise.tomlの道具（node、bats、shellcheck）と、`deps.json` でピンしたnpm globalのCLI。
workflowに版を直書きしない。

#### Scenario: ピンの更新
- **WHEN** `deps.json` のtextlintのversionを上げてpushする
- **THEN** workflowは変更なしで新しい版を入れて検証する

### Requirement: strict モード
`make verify VERIFY_STRICT=1` は、道具が無くてskipしていたチェックを失敗にしなければならない（MUST）。
対象はopenspec、openspec schema、shellcheck、bats、claude plugin validate、textlint、designmd。
失敗の出力にはチェック名と `VERIFY_STRICT` を含める。`VERIFY_STRICT` が未設定または `0` のときは今までどおりskipして終了コード0。

#### Scenario: designmd が無い（strict）
- **WHEN** designmdがPATHに無い状態で `make verify-design VERIFY_STRICT=1` を実行する
- **THEN** 終了コードは非ゼロで、出力に `[design.md]` と `VERIFY_STRICT` が含まれる

#### Scenario: designmd が無い（既定）
- **WHEN** designmdがPATHに無い状態で `make verify-design` を実行する
- **THEN** 終了コードは0で、出力に `skipped` が含まれる

### Requirement: plugin validate を CI で走らせる
workflowはclaude CLIをnpmで入れなければならない（MUST）。`make verify` の `claude plugin validate --strict` はstrictの対象に含める。
CLIがログインを要求するなどCIで安定しないと分かったときは、この要件を外してstrictの免除対象にする。

#### Scenario: hooks.json の破損
- **WHEN** `plugins/uskn-harness/hooks/hooks.json` を壊してpushする
- **THEN** workflowは `claude plugin validate --strict` で失敗する
