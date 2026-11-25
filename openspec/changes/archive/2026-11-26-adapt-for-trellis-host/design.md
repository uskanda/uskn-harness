# Design

## Context

動機はproposal.mdの「Why」にある。決定の出所は `grilling.md` で、ここでは実装の形だけを決める。

- syncは、設定断片 `templates/user/settings.json` に端末別設定を重ねた合成を、liveへマージする。7つの配列は集合として扱うので、後から重ねるファイルは要素を足せるが、消せない
- hookは、自分の置き場から5つ上のディレクトリをcheckoutとみなす（`lib/common.sh` の `harness_dir`）。`verify-gate.sh` と `textlint-check.sh` は、PATHの先頭に `~/.local/share/mise/shims` と `~/.local/bin` を足す
- `terms-check.sh` と `textlint-check.sh` は、入力の `cwd` のgitルートで、用語集とtextlintの設定を選ぶ
- textlint 15.8.0は、作業ディレクトリがリポジトリのルートのときだけ `.textlintignore` を読む。除外の行 `docs/legacy/**` はその下のファイルを除き、`docs/legacy/` は何も除かない
- 端末の土台は、`--settings` で最低線を固定し、エージェントを別のOSのユーザーで動かす。2026-11-25の実機の確認は3つある。最低線があっても、ユーザー層の `excludedCommands` はsandboxの外での実行を許した。ユーザー層の `WebFetch(domain:*)` は、sandboxの接続先を広げた。`CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` があると、`-p` の権限モードはdefaultに戻った
- hookはClaude Codeのsandboxの外で動く。閉じた環境のエージェントは、作業ツリーと `.git/config` を書ける

## Goals / Non-Goals

**Goals:**

- 管理者の環境の端末では、この変更の後のsyncが、今と同じliveの設定を書く
- 閉じた環境のOSのユーザーが書ける場所に、環境の種類とsandboxの緩和の出所を置かない
- 閉じた環境で、起動スクリプトを通した `claude -p` と対話のセッションで、hookとスキルが働く

**Non-Goals:**

- Linuxの閉じた環境。印があっても、hookはリポジトリのコードを動かさず、doctorは `fail` を出す
- hookを囲む規則を、Claude Codeのsandboxと同じ強さにすること。秘密の置き場の読み取りと、自分の端末の外への直接の接続だけを禁じる
- uskn-loopとswitchboardの閉じた環境での実行。uskn-loopは `claude -p --permission-mode auto` を使い、閉じた環境では権限モードがdefaultに戻る
- 端末の土台の側の仕事。共有の置き場の持ち主とモードの設定、起動スクリプト、ユーザー層の設定の持ち主の変更、checkoutの更新を指す
- 古い機能の整理と、リポジトリの分割

## Decisions

### D1. 環境の印は、checkoutの直下の `.uskn-environment` に置く

印は `key=value` の行から成るファイルで、bash 3.2の `read` だけで読める。jqの無い段階でも読むため。

| キー | 値 |
|---|---|
| `kind` | `confined`。今は他の値を使わない |
| `tools` | 共有の置き場の絶対パス |
| `secrets` | hookの規則で読み取りを禁じる、秘密の置き場の絶対パス。無くてもよい |

- 読む側は5つある。sync、doctor、`print-settings`、`sandbox-exclude` と `sandbox-allow-host`、hookとコマンド `uskn-environment` である。どれも、参照点が解決するcheckout（インストーラでは `HARNESS`、hookでは `harness_dir`）の印を読む
- 印が無ければ管理者の環境とする。印があって `kind` が `confined` 以外か、読めないときは、閉じた環境として扱い、doctorが `fail` を出す。判定に迷ったときは、守りの強い側を選ぶ
- 持ち主の確認はdoctorだけが行う。持ち主のuidが0でないか、実行したOSのユーザーが書けるときは `fail` とする。batsではrootの持ち物を作れないので、比べるuidを `USKN_MARKER_UID` で差し替える。syncとhookは持ち主を見ない。閉じた環境のOSのユーザーはcheckoutに書けないので、印を作り直せないため
- `.gitignore` に `.uskn-environment` を足す。端末ごとのファイルで、リポジトリに入れない
- 退けた案は2つある。1つ目は、引数か環境変数で渡す案である。閉じた環境のOSのユーザーが値を変えられるので、Q16とQ21で退けた。2つ目は `/etc` の下に置く案である。checkoutごとに環境の種類が決まり、テストでも置き場を差し替えやすいので、checkoutの側を選んだ

### D2. 設定断片を5つのファイルに分け、4段で重ねる

| ファイル | 中身 |
|---|---|
| `templates/user/settings.json` | 共通の設定断片。両方の環境の種類と両方のOSで同じキー |
| `templates/user/settings-admin.json` | 管理者の環境だけのキー。sandboxを緩めるキーと、`remoteControlAtStartup`、`defaultMode: auto`、chezmoiの許可 |
| `templates/user/settings-confined.json` | 閉じた環境だけのキー。`Edit` と `Write` の許可と、sandboxを緩めない値 |
| `templates/user/settings-linux.json` | Linuxだけで意味を持つ許可 |
| `templates/user/settings-darwin.json` | macOSだけで意味を持つキー。今は空のオブジェクト |

- 合成は、共通、環境の種類、OS、端末別設定の順に、liveへのマージと同じ規則で重ねる。集合の配列は和になるので、後の段では要素を消せない。そのため、共通の設定断片には、両方の環境で要るものだけを置く
- OSは `uname -s`（テストでは `USKN_HARNESS_OS`）の `Linux` と `Darwin` で選ぶ。WSL2は `Linux` になる。ほかのOSでは、OS別の設定断片を重ねない
- 適用記録と3方向の片付けは、今のまま合成を単位にする。分けたファイルの和が今の設定断片と同じなので、管理者の環境のLinuxの端末では、分けた後の初めてのsyncでliveは変わらない。macOSの端末では、Linux専用の許可だけがliveから消える
- `sandbox-exclude --remove` と `sandbox-allow-host --remove` が「設定断片の要素」とみなすのは、端末別設定を重ねる前の3段の合成の要素である
- 管理者の環境用の設定断片は、今の共通の設定断片から次を移して作る
  - `failIfUnavailable: false`、`allowUnsandboxedCommands: true`、`excludedCommands` の11個
  - `WebFetch(domain:*)`、`allowAllUnixSockets: true`
  - `allowWrite` の `~/.local/share/mise` と `~/.local/share/pnpm`
  - `remoteControlAtStartup`、`defaultMode: auto`
  - `Bash(chezmoi --version)` と `Bash(chezmoi source-path *)`
- 閉じた環境用の設定断片は、`failIfUnavailable: true` と `allowUnsandboxedCommands: false` を明示する。最低線が同じ値を固定していても、ユーザー層だけを読んだ人に意図が分かるため
- Linux用の設定断片へは、`Bash(apt-cache *)` と `Bash(lscpu)` を移す。`Bash(systemctl is-enabled *)` と `Bash(systemctl is-active *)` も移す。`Read(//sys/devices/system/cpu/**)` と `Read(//usr/lib/**)` も移す。`Read(//etc/**)` と `Read(//tmp/**)` は、macOSでも読むので共通に残す
- 退けた案は、合成の中で要素を消す記法（例：`"-WebFetch(domain:*)"`）である。マージの規則が複雑になり、syncとdoctorと `print-settings` の3つが同じ規則を持つ必要があるので退けた

### D3. 閉じた環境では、端末別設定からsandboxを緩めるキーを外してから重ねる

外すキーは次のとおり。

- `sandbox.excludedCommands` と `sandbox.allowUnsandboxedCommands`
- `sandbox.network.allowedDomains` と `sandbox.network.allowAllUnixSockets`
- `sandbox.failIfUnavailable` が `false` のとき、`sandbox.enabled` が `false` のとき
- `sandbox.filesystem.allowWrite` の要素
- `permissions.allow` のうち、`WebFetch` だけの要素と、`WebFetch(domain:` で始まり `*` を含む要素
- `permissions` の下の `defaultMode`

grillingのQ10、Q17、Q25は、`sandbox.enabled: false` と `defaultMode` を挙げていない。ただし、どちらも閉じた環境の守りを外す値なので、同じ規則で外す。

- syncは、外したキーのパスを `warn` の1行で報告し、終了コードは0のままにする。doctorも同じ行を `warn` で出す
- 外すのはjqの1つの関数で行い、sync、doctor、`print-settings` が同じ関数を使う

### D4. `uskn-harness print-settings` は、合成を標準出力に出すだけにする

- 出すのは、4段の合成（閉じた環境では外した後）である。liveとのマージや、effortの消去は含めない。端末の土台は、この出力を自分の持ち物のファイルとして置く
- ファイルシステムには書かない。端末別設定が読めないときは、理由を標準エラーに出し、終了コード1で終える
- 名前の候補には `sync --print-settings` もあった。導入をしないので、syncのオプションにはしない

### D5. 共有の置き場は `uskn-harness install-shared <dir>` で作る

置き場の中は次の形にする。

| パス | 中身 |
|---|---|
| `<dir>/bin/` | node、npm、npx、jq、ピンしたnpmのCLIの実行ファイルへのsymlink |
| `<dir>/mise/` | `MISE_DATA_DIR` として使う、miseの入れたnodeとjq |
| `<dir>/npm/` | `npm install -g --prefix` の置き場 |
| `<dir>/skills/<name>/` | `deps.json` の `skills` のうち `mode` が `reference` の項目 |
| `<dir>/installed.json` | 入れた版とrefの記録 |

- 管理者が実行する。環境の種類を見ず、ユーザー層には触らない。持ち主とモードは変えない。閉じた環境のOSのユーザーが書けないようにするのは、端末の土台の仕事である
- 冪等にする。`<dir>/installed.json` の版とrefが `deps.json` と同じ項目は入れ直さない。`--dry-run` を受け付ける。失敗の終了コードは、syncの規則に合わせる
- サードパーティスキルは、skills CLIを一時ディレクトリでプロジェクト単位に実行して入れる。できた `.claude/skills/<name>` は、`<dir>/skills/<name>` へ置き換えで写す。Impeccableは、今のzipの検証の手順を、置き先だけ変えて使う
- 退けた案は、閉じた環境のOSのユーザーが自分のホームに道具を入れる案である。hookがホームの下の道具を動かすと、エージェントが道具を差し替えられるので退けた（Q14、Q19）

### D6. 閉じた環境のsyncの範囲

| 手順 | 管理者の環境 | 閉じた環境 |
|---|---|---|
| 0. checkoutの更新 | 今のまま | `--no-pull` と同じく飛ばし、理由を報告する |
| 1. 参照点 | 今のまま | 今のまま |
| 2. ランタイムとnpmのCLI | 入れる | 入れない。`<dir>/installed.json` の版を `deps.json` と比べて報告する |
| 3. 実行ファイル | 今のまま | 今のまま |
| 4. 自作スキル | すべて | 管理者の環境だけのスキルを除く。既にあるそのsymlinkは消す |
| 5. プラグイン | すべて | `uskn-notify` を除く。既にあるそのsymlinkは消す |
| 5a. 通知のコマンド | 今のまま | 置かず、既にあるハーネスを指すsymlinkを消す |
| 6. サードパーティスキル | 入れる | `~/.claude/skills/<name>` を `<tools>/skills/<name>` へのsymlinkにする |
| 7. OpenSpecのコマンド | 今のまま | `<tools>/bin` をPATHの先頭に置いて生成する |
| 8. ユーザー層の設定 | 今のまま | 閉じた環境の合成を使う |
| 10. LaunchAgent | 今のまま | 飛ばす |

- 管理者の環境だけのスキルは、`SKILL.md` のfrontmatterの `metadata` に `uskn-environment: admin` を持つ。`cleanup` と `set-workspace-theme` に付ける。Agent Skillsの仕様は `metadata` を任意のキーの置き場として認めるので、ほかのエージェントでも読める
- 名前の一覧をコードに書く案は退けた。新しいスキルを足す人が一覧を知らないまま、閉じた環境へ入ってしまうため。プラグインはfrontmatterを持たないので、`uskn-notify` の名前はコードに書く
- 閉じた環境で `tools` が無いか、その置き場が無いときは、手順2と6を `fail` とし、他の手順は続ける

### D7. 閉じた環境のhookは、リポジトリの中のコマンドを `sandbox-exec` の中で動かす

- `lib/common.sh` に、環境の印を読む関数と、PATHを組み立てる関数と、規則の中で動かす関数 `confined_run` を足す
- PATHは、管理者の環境では今のまま、閉じた環境では `<tools>/bin` だけを先頭に足す。ホームの下は足さない
- 規則の置き場は `plugins/uskn-harness/hooks/scripts/lib/confined.sb` である。hookは `sandbox-exec -f <rules> -D SECRETS=<dir>` で渡す。規則は、`SECRETS` の下の読み書きと外への接続だけを禁じ、ほかは許す。外への接続のうち、`localhost` への接続だけは許す。`secrets` が印に無いときは、接続の禁止だけの規則を使う
- 規則の中で動かすのは3種類ある。verify gateの検証規約、textlintの実行、hookがリポジトリの中で実行するgitである。gitを含めるのは、エージェントが `.git/config` の `core.fsmonitor` やfilterの設定に、任意のコマンドを書けるため。`git status`、`git diff`、`git hash-object` はそれを実行する。grillingのQ18は検証規約とtextlintを挙げた。gitの件はこの設計で見つけたので、確認を求める
- `sandbox-exec` はmacOSだけにある。閉じた環境でmacOS以外のとき、または `sandbox-exec` が無いとき、`confined_run` はコマンドを動かさずに終了コード125を返す。verify gateは検証しなかったことを `systemMessage` で知らせる。textlint-checkは同じことを `additionalContext` で知らせる
- 退けた案は、hookがリポジトリのコードを一切動かさない案である。閉じた環境で検証が働かなくなり、完了の条件（Q22）を満たさないので退けた

### D8. 用語の検査とtextlintは、書いたファイルのgitルートで動く

- ルートは、書いたファイルの置き場のディレクトリから `git rev-parse --show-toplevel` で求め、symlinkを解決する。worktreeの中のファイルなら、そのworktreeがルートになる
- `textlint-check` は、ルートの `.textlintrc*` があればそれを使い、ルートを作業ディレクトリにしてtextlintを実行する。textlintがルートの `.textlintignore` を読むため。ルートが無いファイルには、ハーネスの設定を使い、ファイルの置き場を作業ディレクトリにする
- `terms-check` は、ファイルごとにルートを求め、ルートごとに用語集、既知の名前、追跡ファイルを読む。ルートが無いファイルは検査しない。CLIで複数のリポジトリのファイルを渡されたときは、ルートごとにまとめて検査する
- `terms-check` は、ルートの `.textlintignore` に一致するファイルを検査しない。行の読み方はtextlintに合わせる。空の行と `#` で始まる行を飛ばし、ほかの行をルートからの相対パスに対するglobとして扱う。`**` は0個以上のディレクトリに一致し、`/` で終わる行はファイルに一致しない
- `make verify` は、`terms-check` のCLIを通じて同じ除外に従う。このリポジトリは `.textlintignore` を持たないので、検査する文書は変わらない

### D9. bash-guardの知らせは、セッションの状態ファイルで1回に絞る

- 「sandboxの中で動く」の知らせを出したら、状態ディレクトリの `sessions/<session_id>/sandbox-note` を作る。このファイルがあれば、同じセッションでは知らせない。拒否と、`dangerouslyDisableSandbox` の知らせは、今のままにする
- `session_id` が無い入力では、今と同じく毎回知らせる
- 閉じた環境では、`git push`、`gh pr create`、`glab mr create` を拒否する。理由には、閉じた環境ではローカルのcommitまでを行い、pushとPRは外側が行うことを書く。Q20を、スキルの指示だけでなく計算的センサーでも守るため。この拒否はgrillingに無いので、確認を求める

### D10. pushするスキルは、`uskn-environment` を見てpushの手前で止まる

- プラグインのコマンド `uskn-environment` は、`admin` か `confined` を1行で出す
- `pr`、`push`、`spec-pr`、`archive-push` は、pushの前にこのコマンドを実行する。`confined` なら、そこまでの結果（commit、archive、ブランチ）と、pushとPRは外側が行うことを報告して止まる
- `/add-dir` を前提にした拒否で無人の実行が止まったときは、そのまま止める（Q28）。`docs/setup-new-machine.md` とADRに書く

### D11. 開発用のcheckoutの置き場は `~/.config/uskn-harness/dev-checkout` で変える

- 1行だけのファイルで、絶対パスか `~` で始まるパスを書く。bootstrapはjqの入る前に走るので、JSONにしない
- 端末別設定の `settings.json` には書かない。Claude Codeの設定へマージされるファイルに、ハーネスだけのキーを混ぜないため
- bootstrapは、このファイルのパス（無ければ `~/repos/uskn-harness`）に `.git` があれば、参照点をそこへのsymlinkにする
- 参照点がmanaged cloneのままで、開発用のcheckoutが別にあるとき、doctorは `warn` で手作業の置き換えの手順を示す（Q27）。syncは置き換えない

### D12. ADR-0015を足す

`docs/adr/0015-confined-environment.md` に、閉じた環境の例外を書く。対象は2つある。ADR-0009の決定1（`failIfUnavailable` と `allowUnsandboxedCommands` の値）と、ADR-0011の決定2（11個を外に出す）である。D1、D3、D7、D9の拒否の理由もここに残す。

## Risks / Trade-offs

- リスク：集合の和で重ねるので、後の段で要素を消せない。対策：共通の設定断片に置く要素を、両方の環境で要るものに限る。batsで、閉じた環境の合成に、外すべきキーが無いことを確かめる
- リスク：管理者の環境の合成が、分ける前と違ってしまう。対策：分ける前の設定断片をbatsの比較の基準として残し、管理者の環境のLinuxの合成が同じキーと要素を持つことを確かめる
- リスク：`sandbox-exec` は非推奨の扱いで、将来のmacOSで消えうる。対策：無いときは動かさずに知らせる（D7）。doctorも閉じた環境で `sandbox-exec` の有無を見る
- リスク：hookの規則は、作業ツリーの外への書き込みを禁じない。対策：grillingで範囲を絞った。秘密の置き場の読み書きと外への接続だけを禁じる。残りは端末の土台のOSのユーザーの権限で守る
- リスク：`localhost` への接続を許すので、同じ端末のサービスへは届く。対策：検証でテスト用のサーバーを使えるようにするため、許す。Unixソケットへの接続は許さない
- リスク：`Edit` と `Write` の許可だけで、閉じた環境の `-p` が書けるかは分からない。対策：実機で確かめる項目を `tasks.md` に置く（Q29）
- リスク：doctorの持ち主の確認を、`USKN_MARKER_UID` で差し替えられる。対策：差し替わるのはdoctorの報告だけで、syncとhookの判定は変わらない
- リスク：端末の土台が、ユーザー層の設定を閉じた環境のOSのユーザーの持ち物のまま置く。対策：この変更の対象外で、端末の土台の別の変更が扱う（Q30）。それまでは、`print-settings` の出力を土台の持ち物として置くことで避けられる

## Migration Plan

1. 管理者の環境の端末：変更を取り込んだ後に `uskn-harness sync` を実行する。liveは変わらず、各項目が `ok` になる
2. 開発用のcheckoutを `~/repos` の外へ置く端末：`~/.config/uskn-harness/dev-checkout` にパスを書く。参照点がmanaged cloneなら、doctorの案内のとおり手で置き換える
3. 閉じた環境を作る端末：管理者がcheckoutを置き、`.uskn-environment` をrootの持ち物で置く。続けて `uskn-harness install-shared <dir>` を実行し、端末の土台が閉じた環境のOSのユーザーとして `sync --no-pull` を実行する
4. 戻すとき：前の版のcheckoutで `sync` を実行する。適用記録と3方向の片付けが、前の合成へ戻す。閉じた環境では `.uskn-environment` を消してから戻す

## Open Questions

- `sandbox-exec` の規則で、`localhost` への接続だけを許す書き方が、実機のmacOSで意図どおりに働くか。`tasks.md` の実機の項目で確かめ、書き方だけを直す
