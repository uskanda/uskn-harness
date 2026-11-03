# Tasks

## 1. doctorの検査

- [x] 1.1 `bin/tests/uskn-harness.bats` のsandboxの依存のテストに、`SANDBOX_RUNTIME` を明示する形を足す（design.mdのD3）。既存の3つのテストも、`SANDBOX_RUNTIME=` を付けて走らせる。足したテストが失敗することを `bats bin/tests/uskn-harness.bats -f sandbox` で確かめる。足すテストは次の3つである
  - 入れ子を作れない端末：終了コード1を返す `bwrap` の偽物で `warn` になり、sandboxの中のBashが失敗することと、新しい端末の手順への案内が含まれる
  - 入れ子を作れる端末：終了コード0を返す `bwrap` の偽物で `ok` になる
  - sandboxの中で動くdoctor：`SANDBOX_RUNTIME=1` で `ok` になり、試していないことが含まれ、`bwrap` の偽物が起動されない
- [x] 1.2 `bin/uskn-harness` の `check_sandbox_deps` に、design.mdのD1とD2のとおりに入れ子の確認を足す。1.1のテストと既存のテストが全て通ることを `bats bin/tests/uskn-harness.bats -f sandbox` で確かめる
- [x] 1.3 26.04の実機で確かめる。sandboxの外の `uskn-harness doctor` が `ok` を返し、sandboxの中では試していないことを含む `ok` を返す

## 2. 手順とADR

- [x] 2.1 `docs/setup-new-machine.md` のsandboxの節を直す。Ubuntu 26.04では、`apparmor` パッケージの `bwrap-userns-restrict` が自作の `bwrap` のプロファイルより優先されることを書く。直し方（`disable/` を作り、`bwrap-userns-restrict` をリンクして外し、自作のプロファイルを読ませ直す）を足す。確認のコマンドを、入れ子を試す形に変え、doctorが同じ確認をすることを書く。textlintとterms-checkが通ることを確かめる
- [x] 2.2 `docs/adr/0013-*.md` を、design.mdのD4のとおりに書く。ADR-0009の決定6に、ADR-0013が補ったことの注記を足す。textlintとterms-checkが通ることを確かめる

## 3. 統合の確認

- [x] 3.1 `make verify VERIFY_STRICT=1` が終了コード0で終わることを確かめる
