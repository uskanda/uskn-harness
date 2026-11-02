# Proposal

## Why

Ubuntu 26.04では、`apparmor` パッケージが `bwrap-userns-restrict` を配り、`bwrap` の中で入れ子のユーザー名前空間を作れなくなった。
Claude Codeのsandboxは `bwrap` の中で名前空間を入れ子に作るため、sandboxの中のBashが全て失敗する。
それでも `doctor` は、`bwrap` と `socat` がPATHにあれば `ok` を返す。新しい端末の手順にある直し方では、26.04の端末は直らない。確認のコマンドも、入れ子を試さないため、sandboxの使えない端末で終了コード0を返す（issue #17）。

## What Changes

- `doctor` のsandboxの検査は、`bwrap` と `socat` があるとき、`bwrap` の中で入れ子のユーザー名前空間を作れるかを試す。作れなければ `warn` を出す
- `doctor` がsandboxの中で動いているときは、試さずに `ok` とする。sandboxの中で動いていること自体が、入れ子を作れた証拠になるため
- 新しい端末の手順に、Ubuntu 26.04の直し方を足す。確認のコマンドを、入れ子を試す形に変える
- ADR-0013で、ADR-0009の決定6を補う。Ubuntuの守り（`bwrap-userns-restrict`）を外すことを、引き受けるコストとして書く

対象外は次のとおり。`sync` や `doctor` がAppArmorの設定を書き換えること、macOSとWSL2の検査、`bwrap` と `socat` のインストール。

## Capabilities

### New Capabilities

- なし

### Modified Capabilities

- `harness-doctor`: sandboxの依存の検査に、入れ子のユーザー名前空間を作れるかの確認を足す

## Impact

- `bin/uskn-harness` の `check_sandbox_deps` と、そのbats `bin/tests/uskn-harness.bats`
- `docs/setup-new-machine.md` のsandboxの節
- `docs/adr/0013-*.md`（新規）と、`docs/adr/0009-bash-sandbox.md` の決定6への注記
