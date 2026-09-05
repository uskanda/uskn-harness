## Purpose

ハーネスの正本を 1 コマンドで各マシンに導入・更新する手順。何度実行しても同じ状態に収束し、ユーザーが手で置いたものを壊さない。

## ADDED Requirements

### Requirement: 冪等性
`uskn-harness sync` を連続して 2 回実行したとき、2 回目は変更を行わず、変更が無かったことを報告しなければならない（MUST）。

#### Scenario: 2 回目の実行
- **WHEN** 導入済みの環境で `sync` を再実行する
- **THEN** 新しい symlink やファイルは作られず、各項目が `ok` として報告される

### Requirement: 参照点の用意
`sync` は `~/.local/share/uskn-harness` を用意しなければならない（MUST）。`USKN_HARNESS_DIR` が指す既存の checkout、または `~/repos/uskn-harness` が存在すればそこへの symlink を張り、どちらも無ければ GitHub からそこへ clone する。既に別の場所を指す symlink や実ディレクトリがある場合は上書きせず警告する。

#### Scenario: 開発機
- **WHEN** `~/repos/uskn-harness` が git checkout で、参照点が未作成
- **THEN** `~/.local/share/uskn-harness` はその checkout への symlink になる

#### Scenario: 新しいマシン
- **WHEN** checkout が無く、参照点も無い
- **THEN** `uskanda/uskn-harness` が `~/.local/share/uskn-harness` に clone される

### Requirement: ランタイムと CLI
`sync` は mise が無ければ `~/.local/bin/mise` に導入し、グローバル既定として `node@24` と `jq` を設定し、`deps.json` の `clis.openspec.version` と一致する openspec を導入しなければならない（MUST）。既に一致していれば何もしない。

#### Scenario: openspec が古い
- **WHEN** 導入済みの openspec が `deps.json` の version と異なる
- **THEN** 指定 version が導入され、`openspec --version` がその値を返す

### Requirement: 自作スキルの symlink
`sync` は `skills/**/SKILL.md` を持つ各ディレクトリについて `~/.claude/skills/<name>` への symlink を張らなければならない（MUST）。`<name>` はディレクトリ名。既に同名の実ディレクトリ（symlink でないもの）があるときは上書きせず、`conflict` として警告し、他の項目の処理を続ける。既にハーネス内を指す symlink なら `ok`。

#### Scenario: chezmoi 管理の同名スキルがある
- **WHEN** `~/.claude/skills/commit` が実ディレクトリとして存在する
- **THEN** `commit` は `conflict` と報告され、symlink は作られず、終了コードは 0

#### Scenario: 名前の一意性
- **WHEN** `skills/` 配下の 2 つのディレクトリが同じ名前を持つ
- **THEN** `sync` は導入前にエラーで停止する

### Requirement: プラグインの symlink
`sync` は `~/.claude/skills/uskn-harness` を `plugins/uskn-harness` への symlink にしなければならない（MUST）。

#### Scenario: 初回
- **WHEN** `~/.claude/skills/uskn-harness` が無い
- **THEN** symlink が作られ、`claude plugin list` に `uskn-harness@skills-dir` が現れる

### Requirement: サードパーティスキル
`sync` は `deps.json` の `skills` のうち `mode` が `reference` で `install` を持つものを、`~/.claude/skills/<name>` が無いときだけ `install` のコマンドで導入しなければならない（MUST）。既にあるものは触らない。

#### Scenario: grilling が未導入
- **WHEN** `~/.claude/skills/grilling` が無い
- **THEN** `npx skills add mattpocock/skills --skill=grilling -g -a claude-code` 相当が実行され、導入後に `SKILL.md` が存在する

### Requirement: OpenSpec のユーザー層スキル
`sync` は openspec が Claude Code 向けに生成するスキルとコマンドを、一時ディレクトリで生成してから `~/.claude/skills/openspec-*` と `~/.claude/commands/opsx/` にコピーしなければならない（MUST）。コピー先にハーネス管理の印（`generatedBy` を含む frontmatter）が無い同名ファイルがあれば上書きせず警告する。

#### Scenario: バージョン更新
- **WHEN** openspec の version が上がった状態で `sync` を実行する
- **THEN** ユーザー層のスキルの `generatedBy` が新しい version になる

### Requirement: ユーザー層の指示
`sync` は `templates/user/CLAUDE.md` を `~/.claude/CLAUDE.md` に配置しなければならない（MUST）。配置先が存在し、先頭に「managed by uskn-harness」の印が無い場合は上書きせず警告する。

#### Scenario: ユーザーが手で書いたファイルがある
- **WHEN** `~/.claude/CLAUDE.md` が印の無いファイルとして存在する
- **THEN** ファイルはそのまま残り、`conflict` として報告される

### Requirement: 実行ファイルの公開
`sync` は `~/.local/bin/uskn-harness` を `bin/uskn-harness` への symlink にしなければならない（MUST）。

#### Scenario: PATH から呼べる
- **WHEN** `sync` 後に新しいシェルを開く
- **THEN** `uskn-harness doctor` が実行できる

### Requirement: dry-run と報告
`--dry-run` を付けたとき、`sync` はファイルシステムを変更せず、行う予定の操作を 1 行ずつ出力しなければならない（MUST）。通常実行では各項目を `ok` / `created` / `updated` / `conflict` / `skipped` のいずれかで報告する。

#### Scenario: dry-run
- **WHEN** 未導入の環境で `sync --dry-run` を実行する
- **THEN** 出力に予定操作が並び、`~/.claude/skills` に変化が無い
