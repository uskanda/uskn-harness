## Purpose

プロダクト repo の導入状態を読み取り専用で点検するコマンド。`onboard-harness` スキルの計算的センサー。

## ADDED Requirements

### Requirement: 点検項目
`uskn-harness onboard-check <dir>` は次を検査し、各項目を `ok` / `warn` で報告しなければならない（MUST）。

- `AGENTS.md` の有無
- `CLAUDE.md` の有無と、`AGENTS.md` を参照しているか
- `openspec/config.yaml` の有無と `schema: uskn`
- 検証規約（`make verify`、`pnpm run verify`、`npm run verify`）
- UI を持つ repo での `DESIGN.md` と `PRODUCT.md`
- `.claude/skills/` の項目と、ユーザー層のスキル名の重複

#### Scenario: 未導入の repo
- **WHEN** 何も置かれていない repo を点検する
- **THEN** すべての項目が `warn` で、終了コードは 0

#### Scenario: 導入済みの repo
- **WHEN** 5 点と verify 規約が揃っている
- **THEN** すべて `ok` で、終了コードは 0

### Requirement: 書き込みをしない
`onboard-check` は対象ディレクトリに書き込んではならない（MUST NOT）。ネットワークにも接続しない。

#### Scenario: 読み取り専用
- **WHEN** 任意の repo で実行する
- **THEN** 対象ディレクトリのファイル一覧と内容は実行前後で変わらない

### Requirement: UI の判定
UI を持つかどうかは、`package.json` の依存で判定しなければならない（MUST）。
見るのは `react`、`react-native`、`expo`、`vue`、`svelte`、`next` の 6 つ。
判定できないときは DESIGN.md と PRODUCT.md を点検の対象から外す。

#### Scenario: UI の無い repo
- **WHEN** `package.json` が無い repo を点検する
- **THEN** DESIGN.md と PRODUCT.md は報告に現れない
