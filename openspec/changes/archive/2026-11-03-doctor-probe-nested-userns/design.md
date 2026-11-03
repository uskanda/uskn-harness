# Design

## Context

動機はproposal.mdのWhyを見る。issue #17で、Ubuntu 26.04の端末を次のとおり確かめた。

- `bwrap` の中のプロセスのラベルは `bwrap//&unpriv_bwrap (enforce)` だった。`unpriv_bwrap` は `audit deny capability` を持つ
- `bwrap` 単体（`bwrap --ro-bind / / --dev /dev --proc /proc true`）は終了コード0で終わる
- 入れ子（`bwrap ... --unshare-user -- unshare --user --map-root-user true`）は、`uid_map` を書けずに失敗する
- `/etc/apparmor.d/disable/` を作り、`bwrap-userns-restrict` をそこへリンクして外すと、ラベルが `bwrap (unconfined)` になった。入れ子とClaude Codeのsandboxも動いた
- `apparmor_parser` 自身が `disable/` を読み飛ばすので、再起動の後も外れたままになる
- Claude Codeのsandboxの中では、環境変数 `SANDBOX_RUNTIME` が立つ

`check_sandbox_deps`（`bin/uskn-harness`）は、今は `have bwrap` と `have socat` だけを見る。

## Goals / Non-Goals

**Goals:**

- sandboxが使えない端末で、`doctor` が `warn` を出す
- `doctor` がsandboxの中で動いたときに、誤った `warn` を出さない
- 手順の確認のコマンドが、sandboxの使えない端末で失敗する

**Non-Goals:**

- `doctor` や `sync` がAppArmorの設定を直すこと。rootが要り、守りを外す判断は端末の持ち主のもの
- Claude Codeの版ごとのsandboxの作りに合わせて、検査を細かく変えること

## Decisions

### D1 試すコマンドは `bwrap` の中の `unshare --user --map-root-user`

結果は、次のコマンドの終了コードで決める。

```bash
bwrap --ro-bind / / --dev /dev --proc /proc --unshare-user -- unshare --user --map-root-user true
```

標準入力は `/dev/null` にし、出力は捨てる。
Claude Codeのsandboxは、`bwrap` の中でさらにユーザー名前空間を作り、uidの対応を書く。このコマンドは同じ操作をする。

- 退けた案：`bwrap` 単体を試す。26.04のsandboxが使えない端末で終了コード0を返すので、検査にならない
- 退けた案：`bwrap` の中で `bwrap` を起動する。同じことを確かめられるが、試すものが増える。`unshare` はutil-linuxの一部で、UbuntuとDebianでは必ず入っている

### D2 sandboxの中かどうかは `SANDBOX_RUNTIME` で見る

`SANDBOX_RUNTIME` が空でなければ、sandboxの中とみなす。Claude Codeのsandboxが立てる変数で、26.04の端末で確かめた。

- 退けた案：`/proc/self/attr/current` のラベルが `bwrap` で始まるかを見る。ラベルは端末のプロファイルの名前で決まるので、端末によって変わる
- 退けた案：`NoNewPrivs` を見る。sandbox以外でも立つ

### D3 テストは `SANDBOX_RUNTIME` を明示する

エージェントが `make verify` を走らせると、batsもsandboxの中で動き、`SANDBOX_RUNTIME` が立つ。
各テストは、この変数を空にするか値を入れるかを明示する。テストを走らせた場所で、結果が変わらないようにするため。
入れ子を作れない端末は、終了コード1を返す `bwrap` の偽物で表す。
sandboxの中のテストでは、起動されたら印を残す `bwrap` の偽物を置き、印が無いことを確かめる。

### D4 ADR-0009を書き換えず、ADR-0013で補う

ADR-0009の決定6（`bwrap` か `socat` が無ければ `warn`）を、ADR-0013が補う。ADR-0009の決定6には注記だけを足す。
ADR-0010からADR-0012が前のADRの決定を差し替え、補ったのと同じ形にする。
ADR-0013には、`bwrap-userns-restrict` を外すことを、引き受けるコストとして書く。外すと、権限の無いユーザー名前空間を使った攻撃への守りが、`bwrap` について弱まる。

## Risks / Trade-offs

- 危険：`unshare` の無い端末で、誤って `warn` が出る。対策：util-linuxはUbuntuとDebianで必ず入っている。案内は手順の節を指すので、原因を辿れる
- 危険：Claude Codeが `SANDBOX_RUNTIME` を立てなくなると、sandboxの中の `doctor` が `warn` を出す。対策：この誤りは `warn` の側に出る。sandboxが使えない端末を `ok` と報告する誤りは起きない
- 危険：`bwrap-userns-restrict` を外すと、守りが弱まる。対策：外すのは端末の持ち主で、手順とADR-0013に理由とコストを書く
