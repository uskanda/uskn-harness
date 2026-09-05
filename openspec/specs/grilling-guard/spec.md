# grilling-guard Specification

## Purpose
grillingの記録が無いchangeに成果物が書き込まれるのを、ツール呼び出しの手前で止めるhook。スキルを迂回した直接の書き込みにも効く。

## Requirements

### Requirement: 記録の無い change への書き込みを拒否
Write / Edit / NotebookEditの対象が `openspec/changes/<name>/` 配下にあるとする。
対象は `proposal.md`、`design.md`、`tasks.md`、`specs/**` のいずれか。
同じchangeに `grilling.md` が無いとき、hookは `permissionDecision: deny` と理由を返さなければならない（MUST）。
理由にはgrillingを先に済ませるよう書く。

#### Scenario: 記録なし
- **WHEN** `openspec/changes/add-x/proposal.md` へのWriteを、`grilling.md` が無い状態で行う
- **THEN** 拒否され、理由に `grilling.md` が挙がる

#### Scenario: 記録あり
- **WHEN** 同じWriteを `grilling.md` がある状態で行う
- **THEN** hookは何も出力せず終了コード0

### Requirement: 対象外は素通し
次への書き込みには何もしてはならない（MUST NOT）。
`grilling.md` 自身、`openspec/changes/archive/` 配下、`openspec/specs/`、change外のファイル。

#### Scenario: grilling.md の作成
- **WHEN** `openspec/changes/add-x/grilling.md` をWriteする
- **THEN** 拒否されない

#### Scenario: archive
- **WHEN** `openspec/changes/archive/2026-01-01-x/tasks.md` をEditする
- **THEN** 拒否されない

### Requirement: 失敗しても作業を止めない
入力が読めない、jqが無い、パスが相対で解決できないといった場合、hookは判断を返さず終了コード0で終わらなければならない（MUST）。

#### Scenario: 壊れた入力
- **WHEN** stdinがJSONでない
- **THEN** 出力は空で終了コードは0
