## MODIFIED Requirements

### Requirement: 置くものの判定
`onboard-harness` スキルは、対象リポジトリに何を置くかを次の規則で決めなければならない（MUST）。

- `AGENTS.md` と `CLAUDE.md` は必ず置く
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
