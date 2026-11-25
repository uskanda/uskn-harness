# harness-doctor Specification

## Purpose
ハーネスの導入状態を検査し、欠けた物や版の違いといった問題と、その原因を人が読める形で示す。bootstrapのスクリプトやCIからも使えるよう、問題があれば非ゼロで終わる。

## Requirements

### Requirement: 検査項目
`uskn-harness doctor` は次を検査し、各項目を `ok` / `warn` / `fail` で報告しなければならない（MUST）。

- 環境の種類と環境の印
- 参照点の存在と向き先
- mise、node、jqの有無（閉じた環境では共有の置き場の記録）
- `deps.json` でピン止めしたnpmのCLIの版（閉じた環境では共有の置き場の記録）
- `~/.local/bin` の実行ファイルのsymlink（`uskn-harness` と `uskn-loop`）の存在と向き先
- `~/.claude/skills` の各symlinkの存在と向き先
- chezmoi管理の同名スキルとの衝突
- 各プラグインのsymlinkと `claude plugin validate` の結果
- サードパーティスキルの有無
- `~/.claude/CLAUDE.md` の管理印
- ユーザー層のsettings.jsonと、syncが書く値とのずれ
- `~/.local/bin` の通知のコマンドのsymlink（管理者の環境だけ）

#### Scenario: 健全な環境
- **WHEN** `sync` 直後に `doctor` を実行する
- **THEN** すべて `ok` で終了コード0

#### Scenario: 向き先が違う symlink
- **WHEN** `~/.claude/skills/commit` が別のパスを指すsymlink
- **THEN** その項目は `fail` で、終了コードは1

#### Scenario: ループのコマンドが無い
- **WHEN** `sync` のあとで `~/.local/bin/uskn-loop` を消してから `doctor` を実行する
- **THEN** その項目は `warn` で、`uskn-harness sync` の実行を促す

#### Scenario: 環境の種類の行
- **WHEN** 印の無いcheckoutで `doctor` を実行する
- **THEN** 報告に、環境の種類が `admin` であることを示す `ok` の行がある

### Requirement: 終了コード
`fail` が1つでもあれば終了コード1、`warn` のみなら0で終わらなければならない（MUST）。

#### Scenario: 衝突だけがある
- **WHEN** chezmoi管理の同名スキルによる `conflict` だけが検出される
- **THEN** その項目は `warn` で、終了コードは0

### Requirement: 書き込みをしない
`doctor` はファイルシステムを変更してはならない（MUST NOT）。

#### Scenario: 読み取り専用
- **WHEN** `doctor` を実行する
- **THEN** `~/.claude` と `~/.local` の内容は実行前後で同一

### Requirement: schema の検査
`doctor` は `~/.local/share/openspec/schemas/uskn` の存在と向き先を他のsymlinkと同じ規則で検査しなければならない（MUST）。

#### Scenario: 欠落
- **WHEN** symlinkが無い
- **THEN** `warn` として報告され、`sync` の実行が案内される

### Requirement: npm global CLI の版の確認
`doctor` は `deps.json` の `clis` の各項目について、入っている版がピンと一致すれば `ok`、無いか異なれば `warn` を報告しなければならない（MUST）。

#### Scenario: 版の不一致
- **WHEN** textlint 15.0.0が入っていて `deps.json` は15.8.0を指す
- **THEN** `warn` に両方の版が含まれる

### Requirement: OpenSpec のユーザー層コマンドの検査
`doctor` は `~/.claude/commands/opsx/` を検査しなければならない（MUST）。
印（`.uskn-harness-managed`）があり、6つのコマンド（`apply` `archive` `explore` `propose` `sync` `update`）がそろっていれば `ok`。
ディレクトリが無いとき、印が無いとき、コマンドが欠けているときは `warn` とし、欠けたコマンドの名前と `sync` の実行を案内する。
`~/.claude/skills/openspec-*` は検査しない。

#### Scenario: sync 済み
- **WHEN** `sync` が6つのコマンドを置いた状態で `doctor` を実行する
- **THEN** `openspec commands opsx` は `ok`

#### Scenario: コマンドの欠落
- **WHEN** `~/.claude/commands/opsx/archive.md` が無い
- **THEN** `warn` に `archive` と `sync` の案内が含まれ、終了コードは0

### Requirement: 実体の無い symlink の検査
`doctor` は、`~/.claude/skills` の下でハーネスの `skills/` を指し、指す先が存在しないsymlinkを `warn` と報告しなければならない（MUST）。
指す先がハーネスの下かどうかは、`sync` の実体の無いsymlinkの削除と同じ規則で判定する。
報告にはsymlinkの名前と `sync` の実行の案内を含める。

#### Scenario: 削除したスキルの symlink
- **WHEN** `~/.claude/skills/pre-merge` が、もう存在しない `skills/git/pre-merge` を指している
- **THEN** `warn` に `pre-merge` と `sync` の案内が含まれ、終了コードは0

#### Scenario: 相対パスで削除したスキルを指す
- **WHEN** `~/.claude/skills/gone` が `../../.local/share/uskn-harness/skills/gone` を指し、その先が無い
- **THEN** `warn` に `gone` と `sync` の案内が含まれ、終了コードは0

### Requirement: サードパーティスキルの ref の確認
管理者の環境の間、`doctor` は、`via` が `skills` のサードパーティスキルごとに、lockファイルの `ref` とピンの差を報告しなければならない（MUST）。
同じなら `ok`、違うかlockの項目が `ref` を持たなければ `warn` とし、両方の値と `sync` の案内を含める。
lockに項目が無いときも `warn` とする。
閉じた環境での確認は、要件「共有の置き場の確認」が決める。

#### Scenario: ref の不一致
- **WHEN** 管理者の環境で、lockのgrillingの項目が `ref` を持たない
- **THEN** grillingは `warn` で、ピンの `ref` と `sync` の案内が含まれ、終了コードは0

#### Scenario: ピンと同じ
- **WHEN** 管理者の環境で、lockのgrillingの `ref` が `deps.json` と同じ
- **THEN** grillingは `ok`

### Requirement: Impeccable の版の確認
Impeccableの `SKILL.md` の `version` がピンと違うとき、`doctor` は `warn` を報告しなければならない（MUST）。
`warn` には両方の版を含める。

#### Scenario: 版が古い
- **WHEN** 導入済みの `SKILL.md` が `version: 4.2.0` で、`deps.json` は4.3.1を指す
- **THEN** impeccableは `warn` で、4.2.0と4.3.1の両方が含まれる

### Requirement: Impeccable の agent の確認
`remove_agents` に挙げたagentのファイルが残っているとき、`doctor` は `warn` を報告しなければならない（MUST）。

#### Scenario: agent が残っている
- **WHEN** `~/.claude/agents/impeccable-documenter.md` がある
- **THEN** そのファイル名と `sync` の案内を含む `warn` が出る

### Requirement: 鮮度警告の設定の確認
環境変数 `IMPECCABLE_NO_STALENESS_CHECK=1` がどこにも設定されていないとき、`doctor` は `warn` を報告しなければならない（MUST）。
確かめる場所は、`~/.claude/settings.json` の `env` と、`doctor` 自身の環境の2つ。
この設定は設定断片が持ち、`sync` がliveへ書く。

#### Scenario: 設定が無い
- **WHEN** `~/.claude/settings.json` の `env` に `IMPECCABLE_NO_STALENESS_CHECK` が無い
- **THEN** `warn` に変数の名前と `sync` の案内が含まれ、終了コードは0

#### Scenario: 設定がある
- **WHEN** `~/.claude/settings.json` の `env` で `IMPECCABLE_NO_STALENESS_CHECK` が `"1"`
- **THEN** その項目は `ok`

### Requirement: Claude Code の最低版の確認
Claude Codeのインストールが見つかったとき、`doctor` はインストールごとに、版を `deps.json` の最低版と比べた結果を1行で報告しなければならない（MUST）。
行は最低版以上なら `ok`、古ければ `warn` とし、どのインストールかを名前で示す。
`warn` には両方の版と、`CLAUDE.md` の無いリポジトリで `AGENTS.md` が読まれないことを含める。
版が読み取れないときは `warn` とし、読み取った出力を行に含める。
最低版は下限であり、上限は設けない。最低版より新しい版は、どれだけ新しくても `ok` とする。

#### Scenario: 古い CLI
- **WHEN** PATHの `claude` が2.1.270で、`deps.json` の最低版は2.1.281
- **THEN** `warn` にPATHの `claude` であることと両方の版が含まれ、`CLAUDE.md` の無いリポジトリで `AGENTS.md` が読まれないことが案内される

#### Scenario: 最低版以上の CLI
- **WHEN** PATHの `claude` が2.1.282で、`deps.json` の最低版は2.1.281
- **THEN** その行は `ok`

#### Scenario: 最低版よりずっと新しい CLI
- **WHEN** PATHの `claude` が3.0.0で、`deps.json` の最低版は2.1.281
- **THEN** その行は `ok`

#### Scenario: 古い VS Code 拡張
- **WHEN** `~/.vscode-server/extensions/anthropic.claude-code-2.1.279-linux-x64` があり、`deps.json` の最低版は2.1.281
- **THEN** `warn` にそのディレクトリと両方の版が含まれる

#### Scenario: CLI は古く VS Code 拡張は新しい
- **WHEN** PATHの `claude` が2.1.270で、`~/.vscode-server/extensions/anthropic.claude-code-2.1.282-linux-x64` がある
- **THEN** CLIの行は `warn`、拡張の行は `ok` で、`warn` は1つだけ

#### Scenario: 版が読めない
- **WHEN** `claude --version` の出力に版が含まれない
- **THEN** CLIの行は `warn` で、出力がそのまま行に含まれる

### Requirement: 検査する Claude Code のインストール
`doctor` は、PATHの `claude` とVS Code拡張の両方をClaude Codeのインストールとして扱わなければならない（MUST）。
拡張を探す場所は `~/.vscode/extensions` と `~/.vscode-server/extensions` の2つ。
拡張のディレクトリ名は `anthropic.claude-code-<version>-*` の形。
同じ `extensions` ディレクトリに複数の版があるときは、最も新しい版だけを1つのインストールとして扱う。

#### Scenario: 更新前の版のディレクトリが残っている
- **WHEN** `~/.vscode-server/extensions` に2.1.279と2.1.282の拡張があり、`deps.json` の最低版は2.1.281
- **THEN** 2.1.282だけが比べられ、その行は `ok`

#### Scenario: ~/.vscode の拡張
- **WHEN** `~/.vscode/extensions/anthropic.claude-code-2.1.279-darwin-arm64` があり、`deps.json` の最低版は2.1.281
- **THEN** `warn` にそのディレクトリが含まれる

### Requirement: Claude Code が無いマシン
Claude Codeのインストールが1つも見つからないとき、`doctor` はこの項目を報告してはならない（MUST NOT）。

#### Scenario: claude コマンドも拡張も無い
- **WHEN** `claude` がPATHに無く、VS Code拡張のディレクトリも無い
- **THEN** この項目は報告に現れず、終了コードに影響しない

### Requirement: symlink の中身の検査
ハーネス内を指すsymlinkの中身が `sync` の張る形と違うとき、`doctor` はその項目を `warn` と報告しなければならない（MUST）。
`sync` の張る形は、参照点を経由する相対パスか、参照点がこのcheckoutを指さないときの絶対パス。
報告には `sync` の実行の案内を含める。

#### Scenario: 移行前の絶対パス
- **WHEN** 参照点がcheckoutを指し、`~/.claude/skills/commit` がcheckoutの絶対パスを指す
- **THEN** `commit` の項目は `warn` で `sync` の案内を含み、終了コードは0

### Requirement: ハーネス外の指す先の無い symlink の検査
`doctor` は、`~/.claude/skills` の直下で指す先の無いsymlinkを、ハーネスの内外を問わず `warn` と報告しなければならない（MUST）。
他の検査が報告したsymlinkは、重ねて報告しない（MUST NOT）。

#### Scenario: chezmoi が残した symlink
- **WHEN** `~/.claude/skills/mine` が存在しないハーネス外のパスを指す
- **THEN** `mine` を含む `warn` が1つだけ出て、終了コードは0

### Requirement: 絶対パスの symlink の検査
`doctor` は、`~/.claude/skills` の直下で中身が絶対パスのsymlinkを `warn` と報告しなければならない（MUST）。
報告には、別のHOMEやコンテナへ写すと指す先が無くなることを含める。

#### Scenario: ハーネス外の絶対パス
- **WHEN** `~/.claude/skills/mine` が、存在するハーネス外のディレクトリを絶対パスで指す
- **THEN** `mine` を含む `warn` が出て、終了コードは0

#### Scenario: sync 直後
- **WHEN** 参照点がcheckoutを指す環境で、`sync` 直後に `doctor` を実行する
- **THEN** 絶対パスの `warn` は出ない

### Requirement: ユーザー層の設定の検査
`doctor` は、syncが今の状態から書くはずの値を求め、liveの `~/.claude/settings.json` と比べなければならない（MUST）。
求め方は、合成のマージ、3方向の片付け、effortの消去をsyncと同じ規則で行う。
一致すれば `ok`、違えば `warn` と報告し、`warn` には違うキーのパスと `sync` の案内を含める。
liveか端末別設定がJSONとして読めないときは `warn` とし、ファイルの名前を含める。

#### Scenario: /effort の後
- **WHEN** 端末で `/effort` を使い、liveの `modelSettings` に `effortLevel` が書かれている
- **THEN** `warn` に `modelSettings` のパスと `sync` の案内が含まれ、終了コードは0

#### Scenario: sync の直後
- **WHEN** `sync` の直後に `doctor` を実行する
- **THEN** その項目は `ok`

### Requirement: 通知のコマンドの検査
管理者の環境の間、`doctor` は、`plugins/uskn-notify/bin/` の各コマンドについて、`~/.local/bin/<name>` の状態を報告しなければならない（MUST）。
そのコマンドを指すsymlinkなら `ok`、実ファイルなら `warn`（`conflict`）、無ければ `warn` とする。
閉じた環境では、この項目を報告しない。

#### Scenario: dotfiles のコピーが残っている
- **WHEN** 管理者の環境で、`~/.local/bin/claude-notify-hook` が実ファイル
- **THEN** `warn` にファイルのパスが含まれ、終了コードは0

#### Scenario: 閉じた環境
- **WHEN** 閉じた環境で、`~/.local/bin/claude-notify` が無い状態で `doctor` を実行する
- **THEN** 通知のコマンドの行は報告に現れない

### Requirement: sandbox の依存の検査
liveの `sandbox.enabled` が `true` のLinuxの端末で、`doctor` はsandboxの依存を1行で報告しなければならない（MUST）。
WSL2もLinuxの端末として扱う。
`bwrap` と `socat` のどちらかがPATHに無ければ `warn` とする。
`warn` には、無いコマンドの名前と、`bubblewrap` と `socat` を入れる案内と、無いあいだBashが制限なしで動くことを含める。
両方があるときの結果は、要件「入れ子のユーザー名前空間の確認」と要件「sandboxの中で動くdoctor」が決める。
`doctor` はどちらもインストールしない。

#### Scenario: bwrap の無い端末
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` が無く、`socat` はある
- **THEN** `warn` に `bwrap` と案内が含まれ、終了コードは0

#### Scenario: 両方ある端末
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` と `socat` がある
- **THEN** その行は、コマンドが無いことの `warn` ではない。`ok` か `warn` かは、入れ子の確認とsandboxの中かどうかで決まる

### Requirement: sandbox の依存を検査しない端末
macOSの端末と、liveの `sandbox.enabled` が `true` でない端末で、`doctor` はsandboxの依存を報告してはならない（MUST NOT）。
macOSのsandboxは、OSに付属する仕組みで動くため。

#### Scenario: macOS
- **WHEN** liveの `sandbox.enabled` が `true` のmacOSの端末で `doctor` を実行する
- **THEN** sandboxの依存の行は報告に現れない

#### Scenario: sandbox を切った端末
- **WHEN** 端末別設定で `sandbox.enabled` を `false` にし、sync後に `doctor` を実行する
- **THEN** sandboxの依存の行は報告に現れない

### Requirement: 入れ子のユーザー名前空間の確認
`doctor` がsandboxの外で動いている間、`bwrap` と `socat` の両方があれば、`doctor` は `bwrap` の中で入れ子のユーザー名前空間を作れるかを試さなければならない（MUST）。
対象の端末は、sandboxの依存を検査する端末（liveの `sandbox.enabled` が `true` のLinuxの端末）である。
作れれば `ok`、作れなければ `warn` とする。
`warn` には、sandboxの中のBashが全て失敗することと、新しい端末の手順の直し方を見る案内を含める。
`doctor` はAppArmorの設定を書き換えない。

#### Scenario: 入れ子を作れる端末
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` と `socat` があり、`bwrap` の中で入れ子のユーザー名前空間を作れる
- **THEN** その行は `ok`

#### Scenario: 入れ子を作れない端末
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` と `socat` があり、`bwrap` の中で入れ子のユーザー名前空間を作れない
- **THEN** その行は `warn` で、sandboxの中のBashが失敗することと、新しい端末の手順への案内が含まれ、終了コードは0

### Requirement: sandboxの中で動くdoctor
`doctor` がClaude Codeのsandboxの中で動いている間、`doctor` は入れ子のユーザー名前空間を試してはならない（MUST NOT）。
対象の端末は、sandboxの依存を検査する端末で、`bwrap` と `socat` の両方があるときに限る。
その行は `ok` とし、sandboxの中で動いているので試していないことを含める。
sandboxの中で動いていること自体が、その端末で入れ子を作れた証拠になる。sandboxの中から試すと、端末の設定に関係なく、sandboxの制限で失敗する。

#### Scenario: sandbox の中で動く doctor
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` と `socat` があり、`doctor` がClaude Codeのsandboxの中で動く
- **THEN** その行は `ok` で、試していないことが含まれ、`bwrap` は起動されない

### Requirement: 環境の印の検査
checkoutに環境の印があるとき、`doctor` は印を検査しなければならない（MUST）。
次のどれかに当たれば `fail` とし、当たった理由を含める。

- `kind` が `confined` でないか、印を読めない
- 印の持ち主のuidが0でない
- `doctor` を実行したOSのユーザーが、印に書ける

batsでは、比べるuidを環境変数 `USKN_MARKER_UID` で差し替える。syncとhookの判定は、この値で変わらない。

#### Scenario: 持ち主が root でない
- **WHEN** 実行したOSのユーザーが持ち主の印で `doctor` を実行する
- **THEN** 印の行は `fail` で、持ち主が理由に含まれ、終了コードは1

### Requirement: 閉じた環境の書き込みの検査
閉じた環境の間、`doctor` は、実行したOSのユーザーがcheckoutと共有の置き場に書けるかを報告しなければならない（MUST）。
どちらかに書けるときは `fail` とし、書けるパスを含める。
閉じた環境の守りは、エージェントがhookと道具を書き換えられないことに依るため。

#### Scenario: 書ける共有の置き場
- **WHEN** 閉じた環境で、共有の置き場が実行したOSのユーザーの持ち物
- **THEN** その行は `fail` で、共有の置き場のパスが含まれる

### Requirement: 共有の置き場の確認
閉じた環境の間、`doctor` は、共有の置き場の `installed.json` の版とrefを、`deps.json` のピンと項目ごとに比べなければならない（MUST）。
同じなら `ok`、違うか記録に無ければ `warn` とし、両方の値と、管理者が `install-shared` を実行する案内を含める。
`~/.claude/skills/<name>` が共有の置き場の `skills/<name>` を指さないときも `warn` とする。

#### Scenario: 古い textlint
- **WHEN** 閉じた環境で、記録のtextlintの版が `deps.json` より古い
- **THEN** textlintの行は `warn` で、両方の版と `install-shared` の案内が含まれ、終了コードは0

### Requirement: 持ち込まない端末別設定のキーの警告
閉じた環境の間、端末別設定がsandboxを緩めるキーを持つとき、`doctor` は `warn` を報告しなければならない（MUST）。
キーの範囲は、user-settingsの要件「閉じた環境で持ち込まない端末別設定のキー」と同じ。
`warn` には外すキーのパスと、そのキーをsyncが持ち込まないことを含める。

#### Scenario: 端末別設定の接続先
- **WHEN** 閉じた環境で、端末別設定の `sandbox.network.allowedDomains` にホストがある
- **THEN** `warn` に `sandbox.network.allowedDomains` が含まれ、終了コードは0

### Requirement: 閉じた環境で使えない sandbox-exec
閉じた環境の間、`sandbox-exec` を使えないとき、`doctor` は `fail` を報告しなければならない（MUST）。
使えないとは、OSがmacOSでないとき、またはPATHに `sandbox-exec` が無いときを言う。
`fail` には、hookがリポジトリのコードを動かさないことと、Linuxの閉じた環境が対象外であることを含める。

#### Scenario: Linux の閉じた環境
- **WHEN** 閉じた環境のLinuxで `doctor` を実行する
- **THEN** その行は `fail` で、終了コードは1

### Requirement: 参照点の移行の案内
管理者の環境の間、参照点がmanaged cloneで、開発用のcheckoutが別の場所にあるとき、`doctor` は `warn` を報告しなければならない（MUST）。
開発用のcheckoutの場所は、`~/.config/uskn-harness/dev-checkout` の1行、無ければ `~/repos/uskn-harness` である。
`warn` には、managed cloneを手で退け、開発用のcheckoutへのsymlinkに置き換える手順を含める。
`doctor` と `sync` は、参照点を置き換えてはならない（MUST NOT）。

#### Scenario: managed clone が残った開発機
- **WHEN** 参照点が実ディレクトリのcloneで、`~/.config/uskn-harness/dev-checkout` の指す場所にgitのcheckoutがある
- **THEN** `warn` に置き換えの手順が含まれ、参照点は変わらず、終了コードは0
