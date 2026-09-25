## Purpose

ハーネス自身の `Makefile` が持つ `verify-fast` ターゲット。変更されたファイルに関わる検査だけを数秒で走らせ、verify gateがStopのたびに使う。
フルの `make verify` はCIとarchive-pushが走らせる。

## ADDED Requirements

### Requirement: 変更の範囲
`verify-fast` は、基準のcommitから変わったファイルと、追跡されていないファイルを対象にしなければならない（MUST）。
基準は、HEADと次の参照とのmerge-baseである。上流ブランチ、`origin/HEAD`、`origin/main`、`origin/master` のうち、最初に得られたものを使う。
どれも得られなければHEADを基準とする。`VERIFY_BASE` を渡せば、それを基準にする。
削除されたファイルは対象にしない。

#### Scenario: commit 済みの変更
- **WHEN** `origin/main` から分かれたブランチで文書を1つcommitし、作業ツリーに変更が無い状態で `make verify-fast` を実行する
- **THEN** commitした文書が検査される

#### Scenario: 追跡されていないファイル
- **WHEN** gitへ足していない新しい文書を置いて `make verify-fast` を実行する
- **THEN** その文書が検査される

### Requirement: 文書の検査
`verify-fast` は、対象のうち `make verify` がtextlintで読む文書へtextlintを実行しなければならない（MUST）。
同じく、`make verify` がtermsの検査で読む文書へ `terms-check` を実行しなければならない（MUST）。
用語集、`openspec/known-names.txt`、一般語リストのどれかが変わったときは、termsの検査を `make verify` と同じ全文書にかける。
textlintの設定（`skills/ja-writing/textlintrc.json`、`skills/ja-writing/prh.yml`）が変わったときは、textlintを全文書にかける。

#### Scenario: 文書を1つ変えた
- **WHEN** `docs/adr/` の文書を1つだけ変えて `make verify-fast` を実行する
- **THEN** textlintとtermsの検査はその1つの文書だけにかかる

#### Scenario: 用語集を変えた
- **WHEN** `openspec/glossary.yml` を変えて `make verify-fast` を実行する
- **THEN** termsの検査が全文書にかかる

### Requirement: スクリプトの検査
`verify-fast` は、対象のうち `make verify` がshellcheckで読むスクリプトへshellcheckを実行しなければならない（MUST）。
hookの共通部品（`plugins/uskn-harness/hooks/scripts/lib/`）が変わったときは、すべてのスクリプトにかける。

#### Scenario: hook を1つ変えた
- **WHEN** `plugins/uskn-harness/hooks/scripts/verify-gate.sh` だけを変えて `make verify-fast` を実行する
- **THEN** shellcheckはそのスクリプトだけにかかる

### Requirement: テストの選択
`verify-fast` は、スクリプトかテストが変わったときだけ、それに関わるbatsのファイルを実行しなければならない（MUST）。
関わるファイルは次のとおり。

- 変わったbatsのファイルそのもの
- hookのスクリプト `hooks/scripts/<name>.sh` には `hooks/tests/<name>.bats`
- hookの共通部品とテストのfixtureには、hookのテストすべて
- `hooks.json` には `hooks/tests/hooks-json.bats`、プラグインの `bin/` には `hooks/tests/plugin-bin.bats`
- `bin/uskn-harness` には `bin/tests/uskn-harness.bats`、`Makefile` には `bin/tests/makefile.bats`
- `skills/` の下のファイルには `bin/tests/skill-*.bats`、`skills/<name>/SKILL.md` にはあれば `bin/tests/<name>-skill.bats`

関わるテストが無ければ、batsは実行しない。

#### Scenario: 文書だけを変えた
- **WHEN** Markdownの文書だけを変えて `make verify-fast` を実行する
- **THEN** batsは実行されない

#### Scenario: hook を1つ変えた
- **WHEN** `plugins/uskn-harness/hooks/scripts/verify-gate.sh` だけを変えて `make verify-fast` を実行する
- **THEN** batsは `plugins/uskn-harness/hooks/tests/verify-gate.bats` だけを実行する

### Requirement: 結果と道具の欠如
`verify-fast` は、どれかの検査が失敗したとき非ゼロで終わらなければならない（MUST）。
検査の道具が無いときは `make verify` と同じく飛ばし、`VERIFY_STRICT=1` のときは失敗にする。
検査する対象が無いときは、その旨を出力して終了コード0で終わる。

#### Scenario: 変更なし
- **WHEN** 基準から何も変わっていない状態で `make verify-fast` を実行する
- **THEN** 検査は何も走らず、終了コードは0

#### Scenario: 指摘の残る文書
- **WHEN** 実在しない名前を含む文書を変えて `make verify-fast` を実行する
- **THEN** 終了コードは非ゼロ
