# ui-guidelines-skill Specification

## Purpose
UI を作る・直すときの入口。DESIGN.md と PRODUCT.md を正本にし、Impeccable、Expo 公式 skills、frontend-design の使い分けを 1 か所に置くスキル。

## Requirements

### Requirement: 正本の扱い
`ui-guidelines` スキルは、視覚的な決定の正本が repo ルートの `DESIGN.md`（Google DESIGN.md 形式）だと書かなければならない（MUST）。
プロダクトの前提の正本は `PRODUCT.md`。
どちらも無いときはテンプレートから作る手順を含める。
DESIGN.md の変更は `design.md lint` でエラー 0 を確認してから終える。

#### Scenario: DESIGN.md が無い repo
- **WHEN** UI の作業を頼まれ、repo に `DESIGN.md` が無い
- **THEN** テンプレートから DESIGN.md を作り、ユーザーに色と書体の決定を確認してから UI を書く

#### Scenario: トークンの変更
- **WHEN** DESIGN.md の色トークンを変える
- **THEN** `design.md lint DESIGN.md` を実行し、エラーが無いことを確認する

### Requirement: Impeccable のコマンドの使い分け
スキルは Impeccable の評価・改善系コマンドを使うと明記しなければならない（MUST）。
対象は audit、critique、polish、harden、adapt など。
DESIGN.md や PRODUCT.md を独自形式で書き換える `init`、`document`、`extract`、`doctor` は使わない。

#### Scenario: 監査
- **WHEN** 既存画面の品質を確認したい
- **THEN** `/impeccable audit <target>` を使い、`init` は勧めない

### Requirement: プラットフォームごとの補い
スキルは React Native / Expo での補い方を含まなければならない（MUST）。
Expo 公式 skills をプロジェクトに入れる手順と、native 固有の指針を DESIGN.md の prose で補うことを書く。
DESIGN.md がまだ無い Web の新規 UI では、`frontend-design` スキルをフォールバックにする。

#### Scenario: Expo repo
- **WHEN** `app.json` と `expo` 依存のある repo で UI を書く
- **THEN** Expo 公式 skills が入っているか確認し、無ければ導入コマンドを示す
