## ADDED Requirements

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
