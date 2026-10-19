## ADDED Requirements

### Requirement: 参照点を経由する相対パスの symlink
参照点がこのcheckoutに解決される間、`sync` は、ハーネス内を指すsymlinkの中身を、symlinkの置き場から参照点を経由する相対パスにしなければならない（MUST）。
対象は実行ファイル、自作スキル、プラグイン、OpenSpec schemaのsymlink。参照点そのもののsymlinkは対象にしない。
相対パスは、symlinkの置き場の物理パスから組み立てる。

#### Scenario: 自作スキル
- **WHEN** 参照点 `~/.local/share/uskn-harness` がcheckoutを指す環境で `sync` を実行する
- **THEN** `readlink ~/.claude/skills/commit` は `../../.local/share/uskn-harness/skills/git/commit` を返す

#### Scenario: 実行ファイル
- **WHEN** 同じ環境で `sync` を実行する
- **THEN** `readlink ~/.local/bin/uskn-harness` は `../share/uskn-harness/bin/uskn-harness` を返す

#### Scenario: OpenSpec schema
- **WHEN** 同じ環境で `sync` を実行する
- **THEN** `readlink ~/.local/share/openspec/schemas/uskn` は `../../uskn-harness/schemas/uskn` を返す

#### Scenario: HOME を写した先
- **WHEN** `sync` 後の `~/.claude` と、ハーネスを置いた `~/.local/share/uskn-harness` を、別のHOMEの同じ位置へ写す
- **THEN** 写した先の `~/.claude/skills/commit/SKILL.md` が読める

#### Scenario: 参照点が別の場所を指す
- **WHEN** 参照点が別のcheckoutを指す環境で `sync` を実行する
- **THEN** 参照点は `conflict` と報告され、自作スキルのsymlinkはこのcheckoutの絶対パスを指す

#### Scenario: 道具だけの導入
- **WHEN** 参照点の無い環境で `sync --tools` を実行する
- **THEN** OpenSpec schemaのsymlinkはcheckoutの絶対パスを指す

### Requirement: 中身の違う symlink の張り直し
ハーネス内を指すsymlinkの中身が前の要件の形と違うとき、`sync` は、指す先が同じでもsymlinkを張り直し、`updated` と報告しなければならない（MUST）。

#### Scenario: 絶対パスの既存 symlink
- **WHEN** `~/.claude/skills/commit` がcheckoutの絶対パス `skills/git/commit` を指し、参照点がcheckoutを指す
- **THEN** `sync` はsymlinkを相対パスに張り直して `updated` と報告し、続けて実行した `sync` は `ok` と報告する

## MODIFIED Requirements

### Requirement: 実体の無い symlink の削除
`sync` は、`~/.claude/skills` の下のsymlinkのうち、ハーネスの `skills/` の下を指し、指す先が存在しないものを削除しなければならない（MUST）。
指す先がハーネスの下かどうかは、中身が絶対パスの場合と相対パスの場合の両方で判定する。相対パスはsymlinkの置き場から文字列として解決し、参照点を経由するものもハーネスの下とみなす。
ハーネスの外を指すsymlink、指す先が存在するsymlink、実ディレクトリには触らない（MUST NOT）。
名前がハーネスの現存するスキルと同じsymlinkは削除せず、張り直す。
`--dry-run` のときは予定を出力するだけで、削除しない。`sync --remove` も同じ規則でこのsymlinkを削除する。

#### Scenario: ハーネスから削除したスキル
- **WHEN** `~/.claude/skills/nessun-dorma` が、もう存在しない `skills/git/nessun-dorma` を指している
- **THEN** `sync` はsymlinkを削除し、`removed` と報告する

#### Scenario: 相対パスで削除したスキルを指す
- **WHEN** `~/.claude/skills/gone` が `../../.local/share/uskn-harness/skills/gone` を指し、その先が無い
- **THEN** `sync` はsymlinkを削除し、`removed` と報告する

#### Scenario: ハーネスの外を指す実体の無い symlink
- **WHEN** `~/.claude/skills/mine` が、存在しないハーネス外のパスを指している
- **THEN** symlinkはそのまま残る

#### Scenario: 移動したスキル
- **WHEN** `~/.claude/skills/pr` が、存在しない `skills/old-location/pr` を指している
- **THEN** symlinkは削除されず、`skills/git/pr` へ張り直されて `updated` と報告される
