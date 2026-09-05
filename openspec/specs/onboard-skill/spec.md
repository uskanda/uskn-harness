# onboard-skill Specification

## Purpose
プロダクトリポジトリにハーネスを導入する手順。何を置き、何を置かないかをリポジトリの性質から決め、既存の指示ファイルを製品固有の事実だけに圧縮する。

## Requirements

### Requirement: 置くものの判定
`onboard-harness` スキルは、対象リポジトリに置くものを次の規則で決めなければならない（MUST）。

- `AGENTS.md`、`CLAUDE.md`、`openspec/`、verifyターゲットはすべてのリポジトリに置く
- `DESIGN.md` と `PRODUCT.md` はUIを持つプロダクトにだけ置く
- 5点セットは置けるものの上限であり、全部置く義務ではない

UIの有無は、画面を描くコードやUIフレームワークへの依存があるかで判定する。

#### Scenario: UI を持たない資料リポジトリ
- **WHEN** 画面のコードもUIフレームワークへの依存も無いリポジトリを導入する
- **THEN** DESIGN.mdとPRODUCT.mdは置かず、置かない理由を報告する

#### Scenario: Expo アプリ
- **WHEN** `app.json` と `expo` 依存を持つリポジトリを導入する
- **THEN** DESIGN.mdとPRODUCT.mdを含む5点を置く

### Requirement: 既存の指示ファイルの扱い
既に `AGENTS.md` か `CLAUDE.md` があるリポジトリでは、スキルは中身を消さずに扱わなければならない（MUST）。
`AGENTS.md` が無く `CLAUDE.md` が正本のときは、中身をそのまま `AGENTS.md` へ移し、`CLAUDE.md` は `@AGENTS.md` にする。
`AGENTS.md` がハーネスやスキルと重複する記述を持つときは、削る候補を提示し、実際に削るかはユーザーに確認する。

#### Scenario: CLAUDE.md だけがあるリポジトリ
- **WHEN** `AGENTS.md` が無く、`CLAUDE.md` に製品固有の制約が書かれている
- **THEN** 中身を編集せずに `AGENTS.md` へ移し、`CLAUDE.md` は `@AGENTS.md` の1行にする

#### Scenario: 重複のある AGENTS.md
- **WHEN** 既存の `AGENTS.md` にコマンド一覧や一般的なコーディング指針が含まれる
- **THEN** 削る候補を行単位で示し、ユーザーの確認を得てから削る

### Requirement: 検証規約の用意
スキルは、対象リポジトリに検証規約が無いときに `make verify` を用意しなければならない（MUST）。
中身はそのリポジトリに既にある決定的なチェックから作る。無ければ、無いことを報告する。

#### Scenario: lint しか無いリポジトリ
- **WHEN** テストが無くlintと型チェックだけができる
- **THEN** その2つを `verify` ターゲットに入れる

### Requirement: 他リポジトリへは PR で渡す
スキルは対象リポジトリの作業ツリーを直接編集してはならない（MUST NOT）。
変更はscratchpadの新しいクローンからdraft PRとして出し、判断が要る作業はPR本文の手順書に残す。

#### Scenario: 導入の実行
- **WHEN** ユーザーがmonolithへの導入を頼む
- **THEN** scratchpadにクローンし、`harness/onboard` ブランチでdraft PRを作る
