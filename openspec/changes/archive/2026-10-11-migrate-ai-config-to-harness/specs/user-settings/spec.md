## Purpose

ユーザー層の `~/.claude/settings.json` を、ハーネスの設定断片と端末別設定からsyncが作る規則。
端末で変えた値を共有の設定へ書き戻さず、ハーネスが入れて要らなくなったものだけをliveから消す。

## ADDED Requirements

### Requirement: 設定断片の置き場
ハーネスは設定断片を `templates/user/settings.json` に、JSONのオブジェクトとして置かなければならない（MUST）。
`make verify` のbatsは、このファイルがJSONとして読めることを確かめる。

#### Scenario: 読めない設定断片
- **WHEN** 設定断片の末尾のかっこを消して `make verify` を実行する
- **THEN** batsが失敗し、ファイルの名前が出る

### Requirement: 設定断片に入れないキー
設定断片は `hooks` と `modelSettings` を持ってはならない（MUST NOT）。
hookはプラグインが配り、モデルごとのeffortは端末に残さないため。
`make verify` のbatsがこの形を確かめる。

#### Scenario: hooks を足す
- **WHEN** 設定断片に `hooks` を足して `make verify` を実行する
- **THEN** batsが失敗し、キーの名前が出る

### Requirement: 端末別設定の重ね合わせ
端末別設定 `~/.config/uskn-harness/settings.json` があるとき、syncは設定断片の上に端末別設定を重ねた合成を求めなければならない（MUST）。
重ね方は、liveへのマージと同じ規則に従う。
端末別設定はハーネスのリポジトリに入らず、syncはこのファイルを作らず、変更しない。

#### Scenario: モデルを端末で変える
- **WHEN** 設定断片の `model` が `opus[1m]` で、端末別設定の `model` が `sonnet`
- **THEN** sync後のliveの `model` は `sonnet`

#### Scenario: 端末別設定が無い
- **WHEN** `~/.config/uskn-harness/settings.json` が無い
- **THEN** 合成は設定断片と同じで、ファイルは作られない

### Requirement: live へのマージ
syncは合成をliveの `~/.claude/settings.json` へマージしなければならない（MUST）。
オブジェクトはキーごとに再帰的にマージし、それ以外の値は合成の値で置き換える。
合成に無いキーは、liveの値をそのまま残す。
liveが無いときは、合成をそのまま書いて `created` と報告する。
書き換えたときは `updated`、変わらないときは `ok` と報告する。
置き場は `CLAUDE_CONFIG_DIR` があればその下、無ければ `~/.claude` の下。

#### Scenario: Claude Code が書いたキー
- **WHEN** liveが、設定断片に無いキー `feedbackSurveyState` を持つ
- **THEN** sync後もそのキーと値は残る

#### Scenario: ハーネスが持つキーを端末で変えた
- **WHEN** 設定断片の `theme` が `auto` で、liveの `theme` が `dark`
- **THEN** sync後のliveの `theme` は `auto` で、`updated` と報告される

#### Scenario: 2 回目
- **WHEN** syncの直後に、何も変えずにsyncを再実行する
- **THEN** liveは書き換えられず、`ok` と報告される

### Requirement: 集合として扱う配列
syncは `permissions` の下の4つの配列を集合として扱わなければならない（MUST）。
対象は `allow`、`deny`、`ask`、`additionalDirectories` の4つ。
マージでは、liveの要素を残したまま、合成にあってliveに無い要素を足す。
要素の順序は、liveの要素の後に足した要素が並ぶ。

#### Scenario: 端末で足した allow
- **WHEN** liveの `permissions.allow` に、設定断片に無い `Bash(make *)` がある
- **THEN** sync後も `Bash(make *)` は残り、設定断片の要素も含まれる

### Requirement: 3 方向の片付け
適用記録にあって合成に無いものを、syncはliveから消さなければならない（MUST）。
キーは値を問わずパスで消す。集合として扱う配列では、要素ごとに消す。
空になったオブジェクトは、親から消す。
適用記録に無いもの、つまりハーネスが入れていないものには触らない（MUST NOT）。

#### Scenario: 設定断片から allow を消した
- **WHEN** 適用記録の `permissions.allow` に `Bash(snap list *)` があり、新しい設定断片には無い
- **THEN** sync後のliveの `permissions.allow` に `Bash(snap list *)` は無い

#### Scenario: 端末で足した allow は残る
- **WHEN** liveの `permissions.allow` に `Bash(make *)` があり、適用記録と合成のどちらにも無い
- **THEN** sync後も `Bash(make *)` は残る

#### Scenario: 設定断片からキーを消した
- **WHEN** 適用記録に `tui` があり、新しい設定断片には無い
- **THEN** sync後のliveに `tui` は無い

### Requirement: 適用記録の更新
liveへの書き込みのあと、syncは合成を適用記録 `~/.local/state/uskn-harness/settings-applied.json` に書かなければならない（MUST）。
置き場は `USKN_STATE_DIR`、`XDG_STATE_HOME` の順に従い、hookの状態ディレクトリと同じ親の下に置く。
適用記録は `sessions/` の外にあり、古いセッションの状態の削除の対象にならない。

#### Scenario: 初めての sync の後
- **WHEN** 適用記録の無い端末でsyncを実行する
- **THEN** 適用記録ができ、中身は合成と同じ

### Requirement: 初回の適用記録
適用記録が無いとき、syncは `templates/user/settings-seed.json` を適用記録とみなさなければならない（MUST）。
このファイルは、dotfilesが最後に配った `dot_claude/settings.json.tmpl` の写しである。
dotfilesが入れて今のハーネスが持たないものを、初回のsyncが3方向の片付けで消すため。

#### Scenario: dotfiles から移る端末
- **WHEN** liveの `hooks` に、dotfilesの入れた `Notification` があり、適用記録は無い
- **THEN** sync後のliveに `hooks` は無い

#### Scenario: 端末別設定に移した allow
- **WHEN** liveの `permissions.allow` に `Bash(sudo pvs)` があり、端末別設定にも `Bash(sudo pvs)` がある
- **THEN** sync後も `Bash(sudo pvs)` は残る

#### Scenario: 端末別設定に移していない allow
- **WHEN** liveの `permissions.allow` に `Bash(sudo pvs)` があり、端末別設定には無い
- **THEN** sync後のliveに `Bash(sudo pvs)` は無い

### Requirement: effort を端末に残さない
syncはliveの `modelSettings` の各モデルから `effortLevel` を消さなければならない（MUST）。
`effortLevel` を消して空になったモデルの項目は消し、空になった `modelSettings` も消す。
`maxEffortLevel` など、`effortLevel` 以外のキーは残す。
Claude Codeの `/effort` がこの場所に書くため、消さないと次のセッションへ値が引き継がれる。

#### Scenario: /effort で変えた後
- **WHEN** liveが `{"modelSettings": {"claude-opus-5-5": {"effortLevel": "low"}}}` を持つ
- **THEN** sync後のliveに `modelSettings` は無く、top-levelの `effortLevel` は設定断片の値

#### Scenario: effort 以外の項目
- **WHEN** liveの `modelSettings` のあるモデルが `effortLevel` と `maxEffortLevel` を持つ
- **THEN** sync後、そのモデルの項目には `maxEffortLevel` だけが残る

### Requirement: 共有の設定へ書き戻さない
syncはliveの値を、設定断片、端末別設定、ハーネスのcheckoutのどれにも書いてはならない（MUST NOT）。

#### Scenario: 端末で値を変えてから sync
- **WHEN** 端末で `/model` と `/effort` を使ってから、syncを実行する
- **THEN** ハーネスのcheckoutは変更の無いままで、端末別設定の中身も変わらない

### Requirement: 読めない JSON
liveか端末別設定がJSONのオブジェクトとして読めないとき、syncはliveと適用記録を変更してはならない（MUST NOT）。
その項目は `conflict` と報告し、読めないファイルの名前を含める。終了コードは0のまま。

#### Scenario: 読めない端末別設定
- **WHEN** 端末別設定の中身がJSONとして読めない
- **THEN** liveと適用記録は変わらず、`conflict` に端末別設定の名前が含まれる

### Requirement: dry-run での設定
`--dry-run` のとき、syncはliveと適用記録を変更してはならない（MUST NOT）。
代わりに、足すキー、変えるキー、消すキーのパスを1行ずつ出力する。

#### Scenario: 片付けの予定
- **WHEN** 初回のsyncの前に `sync --dry-run` を実行する
- **THEN** `hooks` を消す予定が出力され、liveは変わらない

### Requirement: 道具だけの導入では設定に触れない
`sync --tools` のとき、syncはliveの設定と適用記録に触れてはならない（MUST NOT）。

#### Scenario: CI の runner
- **WHEN** `sync --tools` を実行する
- **THEN** `~/.claude/settings.json` と適用記録は作られない

### Requirement: 取り除くときの設定
`sync --remove` のとき、syncは適用記録にあるものをliveから消し、適用記録を消さなければならない（MUST）。
消し方は3方向の片付けと同じで、合成を空とみなす。適用記録に無いものには触らない。

#### Scenario: ハーネスを外す
- **WHEN** liveに設定断片の `model` と、端末で足した `Bash(make *)` がある状態で `sync --remove` を実行する
- **THEN** liveから `model` が消え、`Bash(make *)` は残り、適用記録は無くなる
