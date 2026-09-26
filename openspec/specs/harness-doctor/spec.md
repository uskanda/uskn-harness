# harness-doctor Specification

## Purpose
ハーネスの導入状態を検査し、壊れている箇所と原因を人が読める形で示す。run_onceやCIからも使えるよう、問題があれば非ゼロで終わる。

## Requirements

### Requirement: 検査項目
`uskn-harness doctor` は次を検査し、各項目を `ok` / `warn` / `fail` で報告しなければならない（MUST）。

- 参照点の存在と向き先
- mise、node、jqの有無
- `deps.json` でピン止めしたnpmのCLIの版
- `~/.claude/skills` の各symlinkの存在と向き先
- chezmoi管理の同名スキルとの衝突
- プラグインsymlinkと `claude plugin validate` の結果
- サードパーティスキルの有無
- `~/.claude/CLAUDE.md` の管理印

#### Scenario: 健全な環境
- **WHEN** `sync` 直後に `doctor` を実行する
- **THEN** すべて `ok` で終了コード0

#### Scenario: 向き先が違う symlink
- **WHEN** `~/.claude/skills/commit` が別のパスを指すsymlink
- **THEN** その項目は `fail` で、終了コードは1

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
報告にはsymlinkの名前と `sync` の実行の案内を含める。

#### Scenario: 削除したスキルの symlink
- **WHEN** `~/.claude/skills/pre-merge` が、もう存在しない `skills/git/pre-merge` を指している
- **THEN** `warn` に `pre-merge` と `sync` の案内が含まれ、終了コードは0

### Requirement: サードパーティスキルの ref の確認
`doctor` は、`via` が `skills` のサードパーティスキルごとに、lockファイルの `ref` とピンの差を報告しなければならない（MUST）。
同じなら `ok`、違うかlockの項目が `ref` を持たなければ `warn` とし、両方の値と `sync` の案内を含める。
lockに項目が無いときも `warn` とする。

#### Scenario: ref の不一致
- **WHEN** lockのgrillingの項目が `ref` を持たない
- **THEN** grillingは `warn` で、ピンの `ref` と `sync` の案内が含まれ、終了コードは0

#### Scenario: ピンと同じ
- **WHEN** lockのgrillingの `ref` が `deps.json` と同じ
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
この設定はdotfilesが管理するので、`sync` は書かない。

#### Scenario: 設定が無い
- **WHEN** `~/.claude/settings.json` の `env` に `IMPECCABLE_NO_STALENESS_CHECK` が無い
- **THEN** `warn` に変数の名前が含まれ、終了コードは0

#### Scenario: 設定がある
- **WHEN** `~/.claude/settings.json` の `env` で `IMPECCABLE_NO_STALENESS_CHECK` が `"1"`
- **THEN** その項目は `ok`

### Requirement: Claude Code の最低版の確認
Claude Codeのインストールが見つかったとき、`doctor` はインストールごとに、版を `deps.json` の最低版と比べた結果を1行で報告しなければならない（MUST）。
行は最低版以上なら `ok`、古ければ `warn` とし、どのインストールかを名前で示す。
`warn` には両方の版と、`CLAUDE.md` の無いリポジトリで `AGENTS.md` が読まれないことを含める。
版が読み取れないときは `warn` とし、読み取った出力を添える。
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
- **THEN** CLIの行は `warn` で、出力がそのまま添えられる

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
