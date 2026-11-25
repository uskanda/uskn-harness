# ADR-0015: 閉じた環境では、sandboxを緩める値を持ち込まない

- 状態：採用（2026-11-25）。ADR-0009の決定1とADR-0011の決定2に、閉じた環境の例外を設ける
- 決定者：uskanda（change `adapt-for-trellis-host` のgrilling。第1ラウンドのQ1から第6ラウンドのQ30）
- 関連：ADR-0009、ADR-0011、ADR-0012

## 文脈

端末の土台は、エージェントを別のOSのユーザーで動かし、`--settings` でsandboxの最低線を固定する。
2026-11-25に実機で確かめたところ、最低線があっても、ユーザー層の `sandbox.excludedCommands` はsandboxの外での実行を許した。
ユーザー層の `WebFetch(domain:*)` も、sandboxの接続先を広げた。

ADR-0009の決定1は、全端末で `failIfUnavailable` を `false`、`allowUnsandboxedCommands` を `true` にする。
ADR-0011の決定2は、11個の道具をsandboxの外で動かす。
この設定断片を閉じた環境のOSのユーザーへ入れると、最低線が崩れる。

hookはClaude Codeのsandboxの外で動く。閉じた環境のエージェントは、作業ツリーと `.git/config` を書ける。
hookが検証規約を走らせるか、textlintがリポジトリの設定を読むと、エージェントの書いたコマンドがsandboxの外で動く。
`git status` などのgitも、`.git/config` の `core.fsmonitor` やfilterの設定にあるコマンドを実行する。

## 決定

1. 環境の種類を、管理者の環境（`admin`）と閉じた環境（`confined`）の2つにする。判定には環境の印 `.uskn-environment` だけを使う。印は、checkoutの直下にあるrootの持ち物のファイルである。印が無ければ管理者の環境とする。印の値が誤りのときと読めないときは、閉じた環境として扱い、doctorが `fail` を出す
2. ADR-0009の決定1への例外。閉じた環境用の `settings-confined.json` は、`failIfUnavailable: true` と `allowUnsandboxedCommands: false` を持つ。管理者の環境の値は、`settings-admin.json` へ移して今のまま保つ
3. ADR-0011の決定2への例外。閉じた環境の合成は、`excludedCommands` の11個を持たない。`WebFetch(domain:*)`、`allowAllUnixSockets`、`allowWrite` のmiseとpnpmの置き場も持たない。sandboxの外で動かす道具と接続先は、端末の土台が決める
4. 閉じた環境のsyncは、端末別設定からsandboxを緩めるキーを外してから重ねる。外したキーのパスは、syncとdoctorが `warn` で報告する。`sandbox-exclude` と `sandbox-allow-host` は、`--list` 以外を終了コード2で拒否する
5. 閉じた環境のhookは、リポジトリのコードを `sandbox-exec` の規則 `plugins/uskn-harness/hooks/scripts/lib/confined.sb` の中で動かす。対象は、verify gateの検証規約、textlintの実行、hookが実行するgitの3種類である。規則は、印の `secrets` の下の読み書きと、`localhost` 以外への接続を禁じる。hookのPATHには、共有の置き場の `bin/` だけを足す。macOS以外の端末と、`sandbox-exec` の無い端末では、hookはコマンドを動かさずに知らせる
6. bash-guardは、「sandboxの中で動く」の知らせを1つのセッションで1回だけ出す。閉じた環境では、`git push`、`gh pr create`、`glab mr create` を拒否する。閉じた環境のセッションはローカルのcommitまでを行い、pushとPRは外側が行う

## 検討した代替案

| 案 | 退けた理由 |
|---|---|
| 環境の種類を引数か環境変数で渡す | 閉じた環境のOSのユーザーが値を変えられる（Q16、Q21） |
| 環境の印を `/etc` の下に置く | checkoutごとに環境の種類が決まるほうが、テストで置き場を差し替えやすい |
| 合成の中で要素を消す記法（例：`"-WebFetch(domain:*)"`） | マージの規則が複雑になる。sync、doctor、`print-settings` の3つが同じ規則を持つ必要がある |
| 閉じた環境のOSのユーザーが、自分のホームに道具を入れる | hookがホームの下の道具を動かすと、エージェントが道具を差し替えられる（Q14、Q19） |
| 閉じた環境のhookが、リポジトリのコードを一切動かさない | 閉じた環境で検証が働かず、完了の条件（Q22）を満たさない |
| pushとPRの作成を、スキルの指示だけで止める | Q20の決定を、計算的センサーでも守るため、bash-guardでも拒否する |

## 結果

- 良い点：管理者の環境の端末では、syncの後のliveの設定が変わらない。分けた設定断片の和が、分ける前の設定断片と同じになる
- 良い点：閉じた環境のユーザー層の設定は、最低線を緩めない。hookの動かすリポジトリのコードは、秘密の置き場を読めず、外へ接続できない
- 引き受けるコスト：hookの規則は、Claude Codeのsandboxより弱い。作業ツリーの外への書き込みは禁じず、OSのユーザーの権限に任せる。`localhost` への接続も許す
- 引き受けるコスト：Linuxの閉じた環境は対象外である。`sandbox-exec` はmacOSだけにあり、非推奨の扱いで将来のmacOSから消えうる
- 引き受けるコスト：uskn-loopとswitchboardは、閉じた環境で動かない。`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` があると、`-p` の権限モードがdefaultに戻るため
- 引き受けるコスト：無人の実行は、`/add-dir` を前提にした拒否で止まる（Q28）
- 後回し：ユーザー層の設定の持ち主は、端末の土台の別の変更が扱う（Q30）。それまでは、`print-settings` の出力を土台の持ち物として置く
- 後回し：`localhost` だけを許す規則の書き方が実機で意図どおりに働くかは、実機の確認で確かめる
