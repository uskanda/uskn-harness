# design-templates Specification

## Purpose
プロダクトリポジトリに置く `DESIGN.md` と `PRODUCT.md` のテンプレート。Google形式のlintを通り、Impeccableが読める節構成を持つ。

## Requirements

### Requirement: DESIGN.md テンプレート
`templates/repo/DESIGN.md` はGoogle DESIGN.md形式で書かなければならない（MUST）。
形式はYAML front matterのトークンと、`##` 節のprose。
トークンは `primary` を含む色、書体、spacing、rounded、componentsを持つ。
節は仕様の順序に従う。`design.md lint` のエラーは0でなければならない（MUST）。

#### Scenario: lint
- **WHEN** `design.md lint templates/repo/DESIGN.md` を実行する
- **THEN** `summary.errors` は0

### Requirement: PRODUCT.md テンプレート
`templates/repo/PRODUCT.md` はImpeccableが読む節を持たなければならない（MUST）。
節はPlatform、Users、Product Purpose、Positioning、Operating Contextの5つ。
続けてCapabilities and Constraints、Brand Commitments、Product Principles、Accessibility & Inclusionを持つ。
各節には何を書くかの案内を含める。

#### Scenario: 新しいリポジトリ
- **WHEN** プロダクトリポジトリにPRODUCT.mdを置く
- **THEN** 節見出しを変えずに中身を埋めればImpeccableの `context` が読める

### Requirement: 置く範囲
`DESIGN.md` と `PRODUCT.md` はUIを持つプロダクトにだけ置かなければならない（MUST）。
規約が求めるファイルだけを置く。列挙は現時点の内訳であって、置ける数の上限ではない。

#### Scenario: UI を持たないリポジトリ
- **WHEN** 画面を持たない資料リポジトリにハーネスを導入する
- **THEN** DESIGN.mdとPRODUCT.mdは置かれない
