# verify-skill Specification

## Purpose
エージェントが自分で検証規約を見つけて実行し、失敗を直すための手順。Stop hookがblockしたときの復帰手順でもある。

## Requirements

### Requirement: 規約の探索と実行
`verify` スキルはhookと同じ順序で検証コマンドを見つけて実行しなければならない（MUST）。
順序は `make verify` → `pnpm run verify` / `npm run verify`。結果はpass / failで報告する。
規約が無いときは「このリポジトリに検証規約が無い」と明言し、検証したと言ってはならない（MUST NOT）。

#### Scenario: 規約なし
- **WHEN** 規約の無いリポジトリで `/verify` を実行する
- **THEN** 規約が無いことと、`make verify` を追加する案が報告される

### Requirement: 修正ループ
失敗したとき、スキルは原因を直して同じコマンドを再実行し、通るまで繰り返すか、コード起因でない失敗（外部サービス、ネットワーク）を理由付きで報告しなければならない（MUST）。コミットは行わない。

#### Scenario: lint 失敗
- **WHEN** `make verify` がlintで失敗する
- **THEN** 該当箇所を直し、再実行してpassを確認してから報告する

### Requirement: 完了の根拠
作業が終わった、直った、通ったと報告するとき、エージェントは同じターンで実行した確認コマンドとその結果を先に示さなければならない（MUST）。
結果は終了コードか、失敗の数で示す。前のターンの実行結果や、狭いコマンドの結果を根拠にしてはならない（MUST NOT）。

#### Scenario: 完了の報告
- **WHEN** エージェントがchangeの実装を終えたと言おうとする
- **THEN** 報告は「`make verify` を実行し、終了コード0（bats 120件、失敗0）」のように、コマンドと結果を先に書く

#### Scenario: 狭い確認しかしていない
- **WHEN** 検証規約があるリポジトリで、エージェントが1つのテストだけを実行した
- **THEN** エージェントは検証規約を実行してから完了と言う。1つのテストの結果を根拠にしない

### Requirement: CI の設定から導く確認
検証規約が無く、CIの設定があるとき、`verify` スキルはCIが走らせる確認コマンドをその設定から導いて実行しなければならない（MUST）。
CIの設定は `.github/workflows/` の下のworkflowと `.gitlab-ci.yml` である。
各コマンドはCIと同じディレクトリで実行し、コマンドごとにpass / failを報告する。
報告では、検証規約が無いことと、確認をCIの設定から導いたことを明言する。

#### Scenario: CI の設定だけがある
- **WHEN** 検証規約が無く、`.github/workflows/<name>.yml` が `npm run lint` と `npm test` を走らせる
- **THEN** 2つのコマンドが実行され、それぞれの結果、検証規約が無いこと、`make verify` を追加する案が報告される

#### Scenario: CI の設定も無い
- **WHEN** 検証規約もCIの設定も無い
- **THEN** 両方が無いことと、`make verify` を追加する案が報告される。検証したとは言わない
