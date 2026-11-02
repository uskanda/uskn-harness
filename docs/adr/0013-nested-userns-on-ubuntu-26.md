# ADR-0013: Ubuntu 26.04では `bwrap-userns-restrict` を外し、doctorが入れ子のユーザー名前空間を確かめる

- 状態：採用（2026-11-02）。ADR-0009の決定6を補う
- 決定者：uskanda（change `doctor-probe-nested-userns`。grillingは省略した）
- 関連：ADR-0009、issue #17

## 文脈

Ubuntu 26.04では、`apparmor` パッケージが `/etc/apparmor.d/bwrap-userns-restrict` を配る。
このファイルは `profile bwrap /usr/bin/bwrap` を定義し、`bwrap` の起動する子を `unpriv_bwrap` に移す。
`unpriv_bwrap` は `audit deny capability` を持つ。
Claude Codeのsandboxは、`bwrap` の中でさらにユーザー名前空間を作り、uidの対応を書く。この操作が拒否され、sandboxの中のBashは全て失敗する。

新しい端末の手順は、24.04向けに、自作の `bwrap` のプロファイル（`flags=(unconfined)` と `userns`）を置く。
26.04では、パッケージの `bwrap-userns-restrict` が同じ名前のプロファイルを定義し、こちらが優先される。
手順の確認のコマンド（`bwrap` 単体）は、この端末でも終了コード0で終わる。
doctorは `bwrap` と `socat` があれば `ok` を返す。手順とdoctorのどちらを使っても、sandboxの使えない状態に気付けなかった。

## 決定

1. sandboxの外で動く `doctor` は、`bwrap` と `socat` があるとき、`bwrap` の中で入れ子のユーザー名前空間を作れるかを試す。作れなければ `warn` を出し、手順の節を案内する
2. sandboxの中で動く `doctor` は、試さずに `ok` とする。sandboxの中で動いていること自体が、入れ子を作れた証拠になる。sandboxの中かどうかは `SANDBOX_RUNTIME` で見る
3. Ubuntu 26.04の端末では、端末の持ち主が `bwrap-userns-restrict` を外す。`/etc/apparmor.d/disable/` を作ってリンクを置き、自作の `bwrap` のプロファイルを読ませ直す。手順は新しい端末の手順に書く
4. `sync` と `doctor` は、AppArmorの設定を変えない

決定1と決定2は、ADR-0009の決定6を補う。`bwrap` と `socat` のある端末にも、sandboxの使えないものがあるため。

## 検討した代替案

| 案 | 退けた理由 |
|---|---|
| `bwrap-userns-restrict` を残し、`local/unpriv_bwrap` で `capability` を許す | `unpriv_bwrap` は `audit deny capability` を持つ。AppArmorではdenyがallowより優先されるので、足しても許されない |
| `kernel.apparmor_restrict_unprivileged_userns` を0にする | 端末の全ての実行ファイルについて、守りが外れる。`bwrap` だけに留めるほうが、外す範囲が狭い |
| sandboxを無効にする | ルートの外への書き込みの制限（ADR-0009）が無くなる |
| `sync` がAppArmorの設定を直す | rootが要る。守りを外す判断を、端末の持ち主から取り上げることになる |
| `doctor` が `bwrap` 単体を試す | 26.04のsandboxが使えない端末でも、終了コード0で終わる |

## 結果

- 良い点：26.04の端末でsandboxが動く。sandboxが使えない端末で、doctorが `warn` を出す。手順の確認のコマンドが、sandboxと同じ操作を試す
- 引き受けるコスト：`bwrap-userns-restrict` は、権限の無いユーザー名前空間を足場にした権限昇格を難しくするためのものである。外すと、`bwrap` を通せば、この守りを越えて名前空間を作れる。自作の `bwrap` のプロファイルは `unconfined` なので、`bwrap` の子にAppArmorの制限は掛からない。`apparmor` パッケージの更新で `bwrap-userns-restrict` の中身が変わっても、`disable/` のリンクは残り、外れたままになる
- 後回し：Ubuntu以外のLinuxとWSL2での確認。どちらも、doctorの `warn` で気付ける
