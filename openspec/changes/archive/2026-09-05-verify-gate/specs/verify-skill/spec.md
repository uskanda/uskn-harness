## Purpose

エージェントが自分で検証規約を見つけて実行し、失敗を直すための手順。Stop hook が block したときの復帰手順でもある。

## ADDED Requirements

### Requirement: 規約の探索と実行
`verify` スキルは hook と同じ順序（`make verify` → `pnpm run verify` / `npm run verify`）で検証コマンドを見つけて実行し、結果を pass / fail で報告しなければならない（MUST）。無いときは「このリポジトリに検証規約が無い」と明言し、検証したと言ってはならない（MUST NOT）。

#### Scenario: 規約なし
- **WHEN** 規約の無いリポジトリで `/verify` を実行する
- **THEN** 規約が無いことと、`make verify` を追加する案が報告される

### Requirement: 修正ループ
失敗したとき、スキルは原因を直して同じコマンドを再実行し、通るまで繰り返すか、コード起因でない失敗（外部サービス、ネットワーク）を理由付きで報告しなければならない（MUST）。コミットは行わない。

#### Scenario: lint 失敗
- **WHEN** `make verify` が lint で失敗する
- **THEN** 該当箇所を直し、再実行して pass を確認してから報告する
