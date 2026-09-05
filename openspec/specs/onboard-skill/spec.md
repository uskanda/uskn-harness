# onboard-skill Specification

## Purpose
プロダクト repo にハーネスを導入する手順。何を置き、何を置かないかを repo の性質から決め、既存の指示ファイルを製品固有の事実だけに圧縮する。

## Requirements

### Requirement: 置くものの判定
`onboard-harness` スキルは、対象 repo に置くものを次の規則で決めなければならない（MUST）。

- `AGENTS.md`、`CLAUDE.md`、`openspec/`、verify ターゲットはすべての repo に置く
- `DESIGN.md` と `PRODUCT.md` は UI を持つプロダクトにだけ置く
- 5 点セットは置けるものの上限であり、全部置く義務ではない

UI の有無は、画面を描くコードや UI フレームワークへの依存があるかで判定する。

#### Scenario: UI を持たない資料 repo
- **WHEN** 画面のコードも UI フレームワークへの依存も無い repo を導入する
- **THEN** DESIGN.md と PRODUCT.md は置かず、置かない理由を報告する

#### Scenario: Expo アプリ
- **WHEN** `app.json` と `expo` 依存を持つ repo を導入する
- **THEN** DESIGN.md と PRODUCT.md を含む 5 点を置く

### Requirement: 既存の指示ファイルの扱い
既に `AGENTS.md` か `CLAUDE.md` がある repo では、スキルは中身を消さずに扱わなければならない（MUST）。
`AGENTS.md` が無く `CLAUDE.md` が正本のときは、中身をそのまま `AGENTS.md` へ移し、`CLAUDE.md` は `@AGENTS.md` にする。
`AGENTS.md` がハーネスやスキルと重複する記述を持つときは、削る候補を提示し、実際に削るかはユーザーに確認する。

#### Scenario: CLAUDE.md だけがある repo
- **WHEN** `AGENTS.md` が無く、`CLAUDE.md` に製品固有の制約が書かれている
- **THEN** 中身を編集せずに `AGENTS.md` へ移し、`CLAUDE.md` は `@AGENTS.md` の 1 行にする

#### Scenario: 重複のある AGENTS.md
- **WHEN** 既存の `AGENTS.md` にコマンド一覧や一般的なコーディング指針が含まれる
- **THEN** 削る候補を行単位で示し、ユーザーの確認を得てから削る

### Requirement: 検証規約の用意
スキルは、対象 repo に検証規約が無いときに `make verify` を用意しなければならない（MUST）。
中身はその repo に既にある決定的なチェックから作る。無ければ、無いことを報告する。

#### Scenario: lint しか無い repo
- **WHEN** テストが無く lint と型チェックだけができる
- **THEN** その 2 つを `verify` ターゲットに入れる

### Requirement: 他 repo へは PR で渡す
スキルは対象 repo の作業ツリーを直接編集してはならない（MUST NOT）。
変更は scratchpad の新しいクローンから draft PR として出し、判断が要る作業は PR 本文の手順書に残す。

#### Scenario: 導入の実行
- **WHEN** ユーザーが monolith への導入を頼む
- **THEN** scratchpad にクローンし、`harness/onboard` ブランチで draft PR を作る
