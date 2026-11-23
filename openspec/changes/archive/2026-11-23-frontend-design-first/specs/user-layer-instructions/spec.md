## MODIFIED Requirements

### Requirement: UI 節
ユーザー層の `CLAUDE.md` は、UIを作る・直すときは `ui-guidelines` に従い、`DESIGN.md` と `PRODUCT.md` を正本にすることを含まなければならない（MUST）。
同じ行は、新規UIでは原則として `frontend-design` で方向性を決めてから着手することを含む。

#### Scenario: UI 作業の開始
- **WHEN** ユーザーが画面の作成や修正を頼む
- **THEN** エージェントは `ui-guidelines` を読んでから着手する

#### Scenario: 新しい画面の作成
- **WHEN** ユーザーが新しい画面の作成を頼む
- **THEN** エージェントは実装の前に `frontend-design` で方向性を決める
