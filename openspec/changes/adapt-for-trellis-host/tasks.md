# Tasks

各グループは、batsのテストを先に書いて失敗を確かめてから実装する（AGENTS.md）。
batsはLinuxとmacOSの `/bin/bash` 3.2で動く形にし、`bin/tests/bats-portability.bats` が通ることを確かめる。

## 1. 用語とADR

- [x] 1.1 `openspec/glossary.yml` に、9つの語を足す。端末の土台、最低線、環境の種類、管理者の環境、閉じた環境、環境の印、共有の置き場、OS別の設定断片、開発用のcheckoutである。設定断片の定義も直す。`make verify-terms` が通ることで確かめる
- [x] 1.2 `docs/adr/0015-confined-environment.md` を書く。ADR-0009の決定1とADR-0011の決定2への例外と、design.mdのD1、D3、D7、D9の理由を残す。ADR-0009とADR-0011の状態の行に、ADR-0015への参照を足す。`make verify-textlint` と `make verify-terms` が通ることで確かめる

## 2. 環境の印

- [x] 2.1 `plugins/uskn-harness/hooks/tests/common.bats` に、印を読む関数のテストを足す。印が無いと `admin`、`kind=confined` と `confined`、値の誤りと読めない印も `confined`、`tools` と `secrets` の値を読めることを確かめる。失敗を確かめる
- [x] 2.2 `plugins/uskn-harness/hooks/scripts/lib/common.sh` に、`harness_dir` の直下の `.uskn-environment` を読む関数を足す。bash 3.2の `read` だけで読む。2.1が通ることで確かめる
- [x] 2.3 `plugins/uskn-harness/hooks/tests/plugin-bin.bats` に、`uskn-environment` のテストを足す。`admin` と `confined` を1行で出すことを確かめる。続けて `plugins/uskn-harness/bin/` にコマンドを足し、テストが通ることで確かめる
- [x] 2.4 `bin/tests/uskn-harness.bats` に、インストーラが `HARNESS` の直下の印から環境の種類を決めるテストを足す。実装して通ることで確かめる
- [x] 2.5 `.gitignore` に `.uskn-environment` を足す。印を置いた作業ツリーで `git status --porcelain` に出ないことで確かめる

## 3. 設定断片の分割と合成

- [x] 3.1 `templates/user/settings.json` の分ける前の中身を、batsの比較の基準として `bin/tests/fixtures/` に写す。比較のテストに使えることで確かめる
- [x] 3.2 `bin/tests/user-settings.bats` に次のテストを足し、失敗を確かめる
  - 5つの設定断片がJSONのオブジェクトで、`hooks` と `modelSettings` を持たない
  - 管理者の環境のLinuxの合成が、3.1の基準と同じキーと要素を持つ
  - 閉じた環境の合成が、緩めるキーと `WebFetch(domain:*)` と `allowAllUnixSockets` を持たず、`Edit` と `Write` を持つ
  - 閉じた環境の合成の `allowWrite` が、miseとpnpmの置き場を持たない
  - macOSの合成が、Linuxだけの6つの許可を持たない
- [x] 3.3 `templates/user/settings.json` を共通の設定断片にし、design.mdのD2のとおり4つのファイルを足す。3.2の形のテストが通ることで確かめる
- [x] 3.4 `bin/uskn-harness` の `settings_plan` を、共通、環境の種類、OS、端末別設定の4段で重ねる形にする。OSは `host_os` で選ぶ。3.2の合成のテストが通ることで確かめる
- [x] 3.5 `bin/uskn-harness` に、閉じた環境で端末別設定から緩めるキーを外すjqの関数を足す。外したパスを `warn` で報告するテストを先に書き、通ることで確かめる
- [x] 3.6 `print-settings` を足す。合成を出すこと、liveと適用記録を変えないこと、読めない端末別設定で終了コード1になることを、先に書いたbatsで確かめる
- [x] 3.7 `overlay_array` の「設定断片の要素」を、3段の合成の要素に直す。`--list` の印と `--remove` の拒否のテストが通ることで確かめる
- [x] 3.8 `docs/setup-new-machine.md` の `## ユーザー層の設定` と `## Bash の sandbox` の節に、設定断片の分割と合成の順序を書く。`make verify-textlint` が通ることで確かめる

## 4. 共有の置き場

- [x] 4.1 `bin/tests/uskn-harness.bats` に、`install-shared` のテストを足し、失敗を確かめる。`USKN_HARNESS_STUB_NET=1` の記録で、mise、npm、skills CLI、Impeccableの手順が `<dir>` の下を指すことを確かめる。あわせて、記録の版による冪等性、`--dry-run`、引数なしの終了コード2、ユーザー層に書かないことを確かめる
- [x] 4.2 `bin/uskn-harness` に `install-shared <dir>` を足す。置き場の形と記録はdesign.mdのD5のとおり。4.1が通ることで確かめる
- [x] 4.3 `docs/setup-new-machine.md` に、管理者が共有の置き場を作る手順を書く。持ち主とモードは端末の土台が決めることも書く。`make verify-textlint` が通ることで確かめる

## 5. 閉じた環境のsync

- [x] 5.1 `bin/tests/uskn-harness.bats` と `bin/tests/third-party.bats` に、閉じた環境のsyncのテストを足し、失敗を確かめる。確かめるのは次の項目である
  - checkoutを更新しない
  - mise、npm、skills CLIを実行しない
  - 共有の置き場の記録の版を報告し、置き場が無いと `fail` で終了コード1になる
  - サードパーティスキルを共有の置き場へのsymlinkにする
  - `/opsx:*` の生成に共有の置き場のopenspecを使う
- [x] 5.2 `bin/tests/plugins.bats` と `bin/tests/notify-plugin.bats` に、閉じた環境のテストを足し、失敗を確かめる。`uskn-notify` のsymlink、通知のコマンド、LaunchAgentの手順を置かないことを確かめる。既にあるハーネスのsymlinkを消すことも確かめる
- [x] 5.3 `bin/tests/skill-invocation.bats` か新しいskillのbatsに、`cleanup` と `set-workspace-theme` の印のテストを足す。印は `metadata` の `uskn-environment: admin` である。閉じた環境のsyncがそのsymlinkを張らず、既にあれば消すテストも足す。失敗を確かめる
- [x] 5.4 `skills/cleanup/SKILL.md` と `skills/set-workspace-theme/SKILL.md` のfrontmatterに印を足す。`make verify-skills` と5.3が通ることで確かめる
- [x] 5.5 `bin/uskn-harness` の `cmd_sync` を、design.mdのD6の表のとおり環境の種類で分ける。5.1と5.2と5.3が通り、管理者の環境の既存のテストが変わらず通ることで確かめる
- [x] 5.6 `bin/tests/uskn-harness.bats` に、閉じた環境の `sandbox-exclude` と `sandbox-allow-host` のテストを先に書く。`--list` 以外で終了コード2を返し、端末別設定を作らないことを確かめる。実装して通ることで確かめる
- [x] 5.7 `skills/sandbox-exclude/SKILL.md` と `skills/sandbox-allow-host/SKILL.md` に、閉じた環境では理由を示して終える手順を足す。その手順の有無のテストを、`bin/tests/sandbox-exclude-skill.bats` と `bin/tests/sandbox-allow-host-skill.bats` に足す。テストが通ることで確かめる
- [x] 5.8 `bin/uskn-harness` の先頭の使い方の説明に、閉じた環境の手順と2つの新しいコマンドを足す。`uskn-harness --help` の出力で確かめる

## 6. doctor

- [x] 6.1 `bin/tests/uskn-harness.bats` に、doctorの次のテストを足し、失敗を確かめる
  - 環境の種類の行が出る
  - 印の持ち主と書き込みの検査が `fail` を出す。比べるuidは `USKN_MARKER_UID` で差し替える
  - 閉じた環境で、checkoutか共有の置き場に書けると `fail` になる
  - 共有の置き場の記録の版の違いが `warn` になる
  - 持ち込まない端末別設定のキーが `warn` になる
  - 閉じた環境のLinuxで `sandbox-exec` を使えないと `fail` になる
  - 閉じた環境で、通知のコマンドの行が出ない
- [x] 6.2 `bin/uskn-harness` の `cmd_doctor` に、6.1の検査を足す。6.1が通り、管理者の環境の既存のテストが変わらず通ることで確かめる
- [x] 6.3 `docs/setup-new-machine.md` の `## よくある warn` の節に、閉じた環境の `fail` と `warn` の直し方を足す。`make verify-textlint` が通ることで確かめる

## 7. 閉じた環境のhook

- [x] 7.1 `plugins/uskn-harness/hooks/tests/common.bats` に、PATHを組み立てる関数と `confined_run` のテストを足し、失敗を確かめる。PATHの先頭に置いた偽の `sandbox-exec` に引数を記録させ、`USKN_HARNESS_OS` でOSを差し替える。確かめるのは次の項目である
  - 閉じた環境のPATHが共有の置き場の `bin/` だけを足す
  - 規則のファイルと `SECRETS` の値を渡す
  - macOS以外と `sandbox-exec` が無いときに終了コード125を返す
- [x] 7.2 `plugins/uskn-harness/hooks/scripts/lib/confined.sb` を書き、`lib/common.sh` に7.1の関数を足す。7.1が通ることで確かめる
- [x] 7.3 `plugins/uskn-harness/hooks/tests/verify-gate.bats` に、閉じた環境の検証が規則の中で動くテストを足す。指紋のgitも規則の中で動くこと、規則を使えないときは `systemMessage` だけを返すことも確かめる。失敗を確かめてから `verify-gate.sh` と `tree_fingerprint` を直し、通ることで確かめる
- [x] 7.4 `plugins/uskn-harness/hooks/tests/textlint-check.bats` に、閉じた環境のテストを足し、失敗を確かめる。textlintが規則の中で動き、共有の置き場のtextlintを選ぶことを確かめる。規則を使えないときに `additionalContext` で知らせることも確かめる。続けて `textlint-check.sh` を直し、通ることで確かめる
- [x] 7.5 `docs/setup-new-machine.md` に、閉じた環境のhookの規則と、環境の印の `secrets` の書き方を足す。Linuxの閉じた環境が対象外であることも書く。`make verify-textlint` が通ることで確かめる

## 8. 用語の検査とtextlintのルート

- [x] 8.1 `plugins/uskn-harness/hooks/tests/terms-check.bats` に、次のテストを足し、失敗を確かめる
  - `cwd` と違うリポジトリの文書で、その文書のリポジトリの用語集を使う
  - リポジトリの外の文書を検査しない
  - `.textlintignore` の `docs/legacy/**` で外れ、`docs/legacy/` では外れない
  - CLIで2つのリポジトリの文書を渡すと、それぞれの用語集を使う
- [x] 8.2 `terms-check.sh` を、ファイルごとにgitルートを求める形にし、`.textlintignore` の照合を足す。8.1が通ることで確かめる
- [x] 8.3 `plugins/uskn-harness/hooks/tests/textlint-check.bats` に、次のテストを足し、失敗を確かめる
  - ファイルの側のgitルートの設定を選ぶ
  - textlintをそのルートで実行する
  - `.textlintignore` の除外が出力を空にする
  - リポジトリの外の文書にハーネスの設定を使う
- [x] 8.4 `textlint-check.sh` を直し、8.3が通ることで確かめる。textlintの代わりに、作業ディレクトリと引数を記録する偽のコマンドを使う
- [x] 8.5 `bin/tests/makefile.bats` に、`make verify-terms` が `.textlintignore` に一致する文書を検査しないテストを足す。8.2の後に通ることで確かめる

## 9. bash-guard

- [x] 9.1 `plugins/uskn-harness/hooks/tests/bash-guard.bats` に、知らせの回数のテストを足し、失敗を確かめる。「sandboxの中で動く」の知らせが、同じ `session_id` では1回だけ出ることを確かめる。`session_id` が無い入力では毎回出ること、拒否は回数を絞らないことも確かめる
- [x] 9.2 `bash-guard.sh` に、`sessions/<session_id>/sandbox-note` による1回の絞り込みを足す。9.1が通ることで確かめる
- [x] 9.3 `bash-guard.bats` に、閉じた環境で `git push`、`gh pr create`、`glab mr create` を拒否するテストを足し、失敗を確かめる。`git commit` を拒否しないこと、管理者の環境で拒否しないことも確かめる
- [x] 9.4 `bash-guard.sh` に、閉じた環境のpushとPRの作成の拒否を足す。9.3が通ることで確かめる

## 10. pushするスキル

- [x] 10.1 `bin/tests/skill-archive-on-integrate.bats` か新しいskillのbatsに、テストを足して失敗を確かめる。`push`、`pr`、`release`、`spec-pr`、`archive-push` の本文が、リモートへ書く前に `uskn-environment` を実行し、`confined` で止まる手順を持つことを確かめる
- [x] 10.2 pushする5つのスキルの本文に、10.1の手順と報告の形を足す。10.1と `make verify-skills` が通ることで確かめる。5つとは次のファイルである
  - `skills/git/push/SKILL.md`、`skills/git/pr/SKILL.md`、`skills/git/release/SKILL.md`
  - `skills/spec-pr/SKILL.md`、`skills/archive-push/SKILL.md`

## 11. 開発用のcheckoutの置き場

- [x] 11.1 `bin/tests/bootstrap.bats` に、開発用のcheckoutの置き場のテストを2つ足し、失敗を確かめる。1つ目は、`~/.config/uskn-harness/dev-checkout` の指すcheckoutへ参照点を張ること。2つ目は、ファイルが無いときに `~/repos/uskn-harness` を使うことである
- [x] 11.2 `templates/chezmoi/run_after_uskn-harness.sh.tmpl` が、そのファイルの1行目を読む形にする。11.1が通ることで確かめる
- [x] 11.3 `bin/tests/uskn-harness.bats` に、参照点の移行の案内のテストを足す。参照点がmanaged cloneで、開発用のcheckoutが別にあるとき、doctorが置き換えの手順を `warn` で出すことを確かめる。参照点が変わらないことも確かめる。実装して通ることで確かめる
- [x] 11.4 `docs/setup-new-machine.md` に、開発用のcheckoutの置き場の変え方と、managed cloneから手で移る手順を書く。`make verify-textlint` が通ることで確かめる

## 12. 文書

- [x] 12.1 `README.md` に、2つの環境の種類と、閉じた環境の対象外（Linux、uskn-loop、switchboard）を書く。`make verify-textlint` と `make verify-terms` が通ることで確かめる
- [x] 12.2 `docs/setup-new-machine.md` に、閉じた環境のセッションはローカルのcommitまでを行い、pushとPRは外側が行うことを書く。無人の実行が `/add-dir` を前提にした拒否で止まることも書く。`make verify-textlint` が通ることで確かめる

## 13. 統合の確認

- [x] 13.1 `make verify` が通ることで、全体の検査とbatsを確かめる
- [x] 13.2 `openspec validate adapt-for-trellis-host --strict` が通ることで確かめる
- [ ] 13.3 `uskn-harness sync` を管理者の環境の開発機で実行し、各項目が `ok` になることを確かめる。Linuxではliveの設定が変わらない。macOSでは、Linux専用の許可の6要素だけがliveから消える
- [ ] 13.4 `install-shared` と印の配置を管理者が行い、閉じた環境のOSのユーザーとして `sync --no-pull` と `doctor` を実行する。端末は、閉じた環境のOSのユーザーを持つmacOSの端末である。doctorの終了コードが0になることで確かめる。利用者が実機で行う
- [ ] 13.5 `claude -p` を起動スクリプトを通して実行し、ファイルの編集が確認を待たずに通ることを確かめる（Q29の `Edit` と `Write`）。利用者が実機で行う
- [ ] 13.6 verify gateとtextlint-checkが、閉じた環境の対話のセッションで規則の中で動くことを確かめる。規則が `secrets` の下の読み取りと外への接続を拒否し、`localhost` への接続を通すことも確かめる。利用者が実機で行う
- [ ] 13.7 `git push` が閉じた環境のセッションでbash-guardに拒否され、`/pr` がpushの手前で止まることを確かめる。利用者が実機で行う
- [ ] 13.8 `print-settings` の出力を端末の土台が置いた後、ユーザー層の設定に `excludedCommands` と `WebFetch(domain:*)` が無いことを確かめる。利用者が実機で行う
