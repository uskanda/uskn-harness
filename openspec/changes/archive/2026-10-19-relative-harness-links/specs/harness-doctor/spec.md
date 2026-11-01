## ADDED Requirements

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

## MODIFIED Requirements

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
