## MODIFIED Requirements

### Requirement: テストの選択
`verify-fast` は、スクリプトかテストが変わったときだけ、それに関わるbatsのファイルを実行しなければならない（MUST）。
関わるファイルは次のとおり。

- 変わったbatsのファイルそのもの
- hookのスクリプト `hooks/scripts/<name>.sh` には `hooks/tests/<name>.bats`
- hookの共通部品とテストのfixtureには、hookのテストすべて
- `hooks.json` には `hooks/tests/hooks-json.bats`、プラグインの `bin/` には `hooks/tests/plugin-bin.bats`
- `bin/uskn-harness` には `bin/tests/uskn-harness.bats`、`Makefile` には `bin/tests/makefile.bats`
- `bin/uskn-loop` と `loop/` の下のファイルには `bin/tests/uskn-loop.bats`
- `skills/` の下のファイルには `bin/tests/skill-*.bats`、`skills/<name>/SKILL.md` にはあれば `bin/tests/<name>-skill.bats`

関わるテストが無ければ、batsは実行しない。

#### Scenario: 文書だけを変えた
- **WHEN** Markdownの文書だけを変えて `make verify-fast` を実行する
- **THEN** batsは実行されない

#### Scenario: hook を1つ変えた
- **WHEN** `plugins/uskn-harness/hooks/scripts/verify-gate.sh` だけを変えて `make verify-fast` を実行する
- **THEN** batsは `plugins/uskn-harness/hooks/tests/verify-gate.bats` だけを実行する

#### Scenario: ループの指示を変えた
- **WHEN** `loop/prompts/auditor.md` だけを変えて `make verify-fast` を実行する
- **THEN** batsは `bin/tests/uskn-loop.bats` だけを実行する
