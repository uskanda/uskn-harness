## MODIFIED Requirements

### Requirement: 記録の無い change への書き込みを拒否
Write / Edit / NotebookEditの対象が `openspec/changes/<name>/` 配下にあるとする。
対象は `proposal.md`、`design.md`、`tasks.md`、`specs/**` のいずれか。
同じchangeに `grilling.md` が無いとき、hookは `permissionDecision: deny` と理由を返さなければならない（MUST）。
理由にはgrillingを先に済ませるよう書く。
理由には、ユーザーの指示があればno-grillingスキルで省略できることも書かなければならない（MUST）。

#### Scenario: 記録なし
- **WHEN** `openspec/changes/add-x/proposal.md` へのWriteを、`grilling.md` が無い状態で行う
- **THEN** 拒否され、理由に `grilling.md` と `no-grilling` が挙がる

#### Scenario: 記録あり
- **WHEN** 同じWriteを `grilling.md` がある状態で行う
- **THEN** hookは何も出力せず終了コード0
