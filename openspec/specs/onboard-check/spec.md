# onboard-check Specification

## Purpose
プロダクトリポジトリの導入状態を読み取り専用で点検するコマンド。`onboard-harness` スキルの計算的センサー。

## Requirements

### Requirement: 点検項目
`uskn-harness onboard-check <dir>` は次を検査し、各項目を `ok` / `warn` で報告しなければならない（MUST）。

- `AGENTS.md` の有無
- `CLAUDE.md`、`.claude/CLAUDE.md`、`CLAUDE.local.md` が `AGENTS.md` の読み込みを妨げないか
- `openspec/config.yaml` の有無と `schema: uskn`
- 検証規約（`make verify`、`pnpm run verify`、`npm run verify`）
- UIを持つリポジトリでの `DESIGN.md` と `PRODUCT.md`
- `.claude/skills/` の項目と、ユーザー層のスキル名の重複

#### Scenario: 未導入のリポジトリ
- **WHEN** 何も置かれていないリポジトリを点検する
- **THEN** `CLAUDE.md` の項目を除くすべての項目が `warn` で、終了コードは0

#### Scenario: 導入済みのリポジトリ
- **WHEN** `AGENTS.md`、`openspec/`、`DESIGN.md`、`PRODUCT.md` とverify規約が揃っていて、`CLAUDE.md` と `CLAUDE.local.md` は無い
- **THEN** すべて `ok` で、終了コードは0

### Requirement: 書き込みをしない
`onboard-check` は対象ディレクトリに書き込んではならない（MUST NOT）。ネットワークにも接続しない。

#### Scenario: 読み取り専用
- **WHEN** 任意のリポジトリで実行する
- **THEN** 対象ディレクトリのファイル一覧と内容は実行前後で変わらない

### Requirement: UI の判定
UIを持つかどうかは、`package.json` の依存で判定しなければならない（MUST）。
見るのは `react`、`react-native`、`expo`、`vue`、`svelte`、`next` の6つ。
判定できないときはDESIGN.mdとPRODUCT.mdを点検の対象から外す。

#### Scenario: UI の無いリポジトリ
- **WHEN** `package.json` が無いリポジトリを点検する
- **THEN** DESIGN.mdとPRODUCT.mdは報告に現れない

### Requirement: CLAUDE.md の判定
`CLAUDE.md`、`.claude/CLAUDE.md`、`CLAUDE.local.md` のどれも無いとき、`onboard-check` は `ok` を報告しなければならない（MUST）。
`CLAUDE.md` か `.claude/CLAUDE.md` があるとき、`onboard-check` はファイルごとに `@AGENTS.md` を含むかを報告しなければならない（MUST）。
含めば `ok`、含まなければ `warn` とする。

#### Scenario: CLAUDE.md が無い
- **WHEN** `AGENTS.md` があり、`CLAUDE.md`、`.claude/CLAUDE.md`、`CLAUDE.local.md` のどれも無いリポジトリを点検する
- **THEN** `CLAUDE.md` の項目は `ok`

#### Scenario: @AGENTS.md を参照する CLAUDE.md
- **WHEN** `CLAUDE.md` が `@AGENTS.md` を含む
- **THEN** `CLAUDE.md` の項目は `ok`

#### Scenario: AGENTS.md を参照しない CLAUDE.md
- **WHEN** `CLAUDE.md` が `@AGENTS.md` を含まない
- **THEN** `warn` として報告され、`AGENTS.md` が読まれなくなることが案内される

#### Scenario: .claude/CLAUDE.md
- **WHEN** `CLAUDE.md` は無く、`.claude/CLAUDE.md` が `@AGENTS.md` を含まない
- **THEN** `warn` として報告される

### Requirement: CLAUDE.local.md の判定
`CLAUDE.md` と `.claude/CLAUDE.md` が無い間、`CLAUDE.local.md` があるとき、`onboard-check` は `warn` を報告しなければならない（MUST）。
その `warn` は、`AGENTS.md` が読まれなくなることと、直し方を示す。
直し方は、`CLAUDE.local.md` を消すか、Project instructionsを `claude-md-and-agents-md` にするかの2つ。

#### Scenario: AGENTS.md に頼るリポジトリの CLAUDE.local.md
- **WHEN** `AGENTS.md` と `CLAUDE.local.md` があり、`CLAUDE.md` と `.claude/CLAUDE.md` のどちらも無いリポジトリを点検する
- **THEN** `warn` として報告され、`CLAUDE.local.md` の削除と `claude-md-and-agents-md` の設定が案内される

#### Scenario: AGENTS.md を取り込む CLAUDE.md と CLAUDE.local.md
- **WHEN** `CLAUDE.md` が `@AGENTS.md` を含み、`CLAUDE.local.md` もある
- **THEN** `CLAUDE.md` の項目は `ok`
