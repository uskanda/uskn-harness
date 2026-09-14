## MODIFIED Requirements

### Requirement: 保護ブランチの扱い
`<repo-context>` に保護ブランチの宣言があるとき、`push` は宣言だけで保護を判定しなければならない（MUST）。
このとき `push` は、指示ファイルの読み込み、ホストのAPI、ブランチ名からの推定を使ってはならない（MUST NOT）。
宣言が無いとき、`push` は「AGENTS.md / CLAUDE.mdの明記 → ホストのAPI → ブランチ名からの推定」の順で保護を判定する。
保護されたブランチに未コミットの変更があるときは、新規ブランチの作成をユーザーに確認しなければならない（MUST）。
`--force` 系のオプションを使ってはならない（MUST NOT）。

#### Scenario: 宣言が none
- **WHEN** `<repo-context>` に `protected: none (AGENTS.md)` があり、`main` に未コミットの変更がある
- **THEN** ファイルとAPIを見ずにcommitし、`main` へpushする

#### Scenario: 宣言のパターンに一致
- **WHEN** `<repo-context>` に `protected: main, release/* (AGENTS.md)` があり、`release/1.2` に未コミットの変更がある
- **THEN** APIを呼ばずに保護ブランチと判定し、新規ブランチの作成をユーザーに確認する

#### Scenario: 明記がある
- **WHEN** 保護ブランチの宣言が無く、AGENTS.mdに「masterは保護されていない」と明記されている
- **THEN** APIでは判定せず、そのまま現在のブランチへpushする
