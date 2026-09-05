## Why

ハーネス全体の grilling（第 1 ラウンド Q12）で「validate を CI で回す」と決めたが、`.github/workflows` が無い。
`make verify` はローカルと Stop hook でしか走っていない。
Stop hook は応答の正常終了時にだけ走るので、利用上限や中断で切れたセッションの変更は検証されないまま main に残りうる。
CI は場所を問わず同じ検証を走らせる 2 つ目のセンサーになる。

## What Changes

- `.github/workflows/verify.yml` を追加する。main への push、pull_request、workflow_dispatch で `make verify VERIFY_STRICT=1` を走らせる
- `uskn-harness sync --tools` を追加する。mise の道具、deps.json でピンした npm global、openspec schema の symlink だけを用意する。skills や sessions repo、ユーザー層には触らない
- Makefile に strict モードを足す。`VERIFY_STRICT=1` のとき、道具が無くて skip していたチェックは失敗になる。既定は今までどおり skip
- CI では claude CLI を npm で入れ、`claude plugin validate --strict` も走らせる
- README の「開発」に CI の 1 行を足す。AGENTS.md の「How work happens here」に CI が strict で同じターゲットを走らせる旨を足す

## Capabilities

### New Capabilities

- `ci-verify`: GitHub Actions で検証規約を strict に走らせる workflow と、Makefile の strict モード

### Modified Capabilities

- `harness-sync`: `--tools` オプションで、ランタイムと CLI と schema symlink だけを導入できる

## Impact

- 新規: `.github/workflows/verify.yml`、`bin/tests` に strict モードの bats
- 変更: `bin/uskn-harness`（オプション追加）と `bin/tests/uskn-harness.bats`、`Makefile`、`README.md`、`AGENTS.md`
- 外部: GitHub Actions の実行。private repo の Actions は有効で、追加の secret は要らない
- ローカルと Stop hook の `make verify` の振る舞いは変わらない
