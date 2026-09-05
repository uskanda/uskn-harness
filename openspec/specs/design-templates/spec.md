# design-templates Specification

## Purpose
プロダクト repo に置く `DESIGN.md` と `PRODUCT.md` のテンプレート。Google 形式の lint を通り、Impeccable が読める節構成を持つ。

## Requirements

### Requirement: DESIGN.md テンプレート
`templates/repo/DESIGN.md` は Google DESIGN.md 形式で書かなければならない（MUST）。
形式は YAML front matter のトークンと、`##` 節の prose。
トークンは `primary` を含む色、書体、spacing、rounded、components を持つ。
節は仕様の順序に従う。`design.md lint` のエラーは 0 でなければならない（MUST）。

#### Scenario: lint
- **WHEN** `design.md lint templates/repo/DESIGN.md` を実行する
- **THEN** `summary.errors` は 0

### Requirement: PRODUCT.md テンプレート
`templates/repo/PRODUCT.md` は Impeccable が読む節を持たなければならない（MUST）。
節は Platform、Users、Product Purpose、Positioning、Operating Context の 5 つ。
続けて Capabilities and Constraints、Brand Commitments、Product Principles、Accessibility & Inclusion を持つ。
各節には何を書くかの案内を含める。

#### Scenario: 新しい repo
- **WHEN** プロダクト repo に PRODUCT.md を置く
- **THEN** 節見出しを変えずに中身を埋めれば Impeccable の `context` が読める

### Requirement: 置く範囲
`DESIGN.md` と `PRODUCT.md` は UI を持つプロダクトにだけ置かなければならない（MUST）。
プロダクト repo に置ける 5 点は上限であり、全部置く義務ではない。

#### Scenario: UI を持たない repo
- **WHEN** 画面を持たない資料 repo にハーネスを導入する
- **THEN** DESIGN.md と PRODUCT.md は置かれない
