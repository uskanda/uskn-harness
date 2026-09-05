# grilling-guard Specification

## Purpose
grilling の記録が無い change に成果物が書き込まれるのを、ツール呼び出しの手前で止める hook。スキルを迂回した直接の書き込みにも効く。

## Requirements

### Requirement: 記録の無い change への書き込みを拒否
Write / Edit / NotebookEdit の対象が `openspec/changes/<name>/` 配下の `proposal.md`、`design.md`、`tasks.md`、`specs/**` で、同じ change に `grilling.md` が無いとき、hook は `permissionDecision: deny` と理由を返さなければならない（MUST）。理由には grilling を先に行うよう書く。

#### Scenario: 記録なし
- **WHEN** `openspec/changes/add-x/proposal.md` への Write を、`grilling.md` が無い状態で行う
- **THEN** 拒否され、理由に `grilling.md` が挙がる

#### Scenario: 記録あり
- **WHEN** 同じ Write を `grilling.md` がある状態で行う
- **THEN** hook は何も出力せず終了コード 0

### Requirement: 対象外は素通し
`grilling.md` 自身、`openspec/changes/archive/` 配下、`openspec/specs/`、change 外のファイルへの書き込みには何もしてはならない（MUST NOT）。

#### Scenario: grilling.md の作成
- **WHEN** `openspec/changes/add-x/grilling.md` を Write する
- **THEN** 拒否されない

#### Scenario: archive
- **WHEN** `openspec/changes/archive/2026-01-01-x/tasks.md` を Edit する
- **THEN** 拒否されない

### Requirement: 失敗しても作業を止めない
入力が読めない、jq が無い、パスが相対で解決できないといった場合、hook は判断を返さず終了コード 0 で終わらなければならない（MUST）。

#### Scenario: 壊れた入力
- **WHEN** stdin が JSON でない
- **THEN** 出力は空で終了コードは 0
