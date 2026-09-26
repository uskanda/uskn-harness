## MODIFIED Requirements

### Requirement: 置くものの判定
`onboard-harness` スキルは、対象リポジトリに何を置くかを次の規則で決めなければならない（MUST）。

- `AGENTS.md` は必ず置く
- `CLAUDE.md` は置かない
- `openspec/` は必ず置く（`config.yaml` の `schema: uskn`）
- `DESIGN.md` と `PRODUCT.md` はUIを持つプロダクトにだけ置く
- 検証規約（`make verify` など）は必ず用意する
- 規約が求めるファイルだけを置く。上の列挙は現時点の内訳であって、置ける数の上限ではない

UIの有無は、画面を描くコードやUIフレームワークへの依存があるかで判定する。

#### Scenario: Expo アプリ
- **WHEN** `app.json` と `expo` 依存を持つリポジトリを導入する
- **THEN** DESIGN.mdとPRODUCT.mdを含め、規約が求めるファイルをすべて置く

#### Scenario: UI を持たない資料リポジトリ
- **WHEN** 画面のコードもUIフレームワークへの依存も無いリポジトリを導入する
- **THEN** DESIGN.mdとPRODUCT.mdは置かず、置かない理由を報告する

#### Scenario: 指示ファイルの無いリポジトリ
- **WHEN** `AGENTS.md` と `CLAUDE.md` のどちらも無いリポジトリを導入する
- **THEN** `AGENTS.md` だけを置き、`CLAUDE.md` は作らない

### Requirement: 既存の指示ファイルの扱い
既に `AGENTS.md` か `CLAUDE.md` があるリポジトリでは、スキルは中身を消さずに扱わなければならない（MUST）。
`AGENTS.md` が無く `CLAUDE.md` が正本のときは、中身をそのまま `AGENTS.md` へ移し、`CLAUDE.md` は削除する。
`AGENTS.md` があり、`CLAUDE.md` が `@AGENTS.md` を参照しているときは、`CLAUDE.md` に触らない。
`AGENTS.md` がハーネスやスキルと重複する記述を持つときは、削る候補を提示し、実際に削るかはユーザーに確認する。

#### Scenario: CLAUDE.md だけがあるリポジトリ
- **WHEN** `AGENTS.md` が無く、`CLAUDE.md` に製品固有の制約が書かれている
- **THEN** 中身を編集せずに `AGENTS.md` へ移し、`CLAUDE.md` は削除する

#### Scenario: @AGENTS.md を参照する CLAUDE.md があるリポジトリ
- **WHEN** `AGENTS.md` があり、`CLAUDE.md` が `@AGENTS.md` を含む
- **THEN** `CLAUDE.md` は元の内容のまま残る

#### Scenario: 重複のある AGENTS.md
- **WHEN** 既存の `AGENTS.md` にコマンド一覧や一般的なコーディング指針が含まれる
- **THEN** 削る候補を行単位で示し、ユーザーの確認を得てから削る
