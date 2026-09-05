# ui-guidelines-skill Specification

## Purpose
UIを作る・直すときの入口。DESIGN.mdとPRODUCT.mdを正本にし、Impeccable、Expo公式skills、frontend-designの使い分けを1か所に置くスキル。

## Requirements

### Requirement: 正本の扱い
`ui-guidelines` スキルは、視覚的な決定の正本がリポジトリルートの `DESIGN.md`（Google DESIGN.md形式）だと書かなければならない（MUST）。
プロダクトの前提の正本は `PRODUCT.md`。
どちらも無いときはテンプレートから作る手順を含める。
DESIGN.mdの変更は `design.md lint` でエラー 0を確認してから終える。

#### Scenario: DESIGN.md が無いリポジトリ
- **WHEN** UIの作業を頼まれ、リポジトリに `DESIGN.md` が無い
- **THEN** テンプレートからDESIGN.mdを作り、ユーザーに色と書体の決定を確認してからUIを書く

#### Scenario: トークンの変更
- **WHEN** DESIGN.mdの色トークンを変える
- **THEN** `design.md lint DESIGN.md` を実行し、エラーが無いことを確認する

### Requirement: Impeccable のコマンドの使い分け
スキルはImpeccableの評価・改善系コマンドを使うと明記しなければならない（MUST）。
対象はaudit、critique、polish、harden、adaptなど。
DESIGN.mdやPRODUCT.mdを独自形式で書き換える `init`、`document`、`extract`、`doctor` は使わない。

#### Scenario: 監査
- **WHEN** 既存画面の品質を確認したい
- **THEN** `/impeccable audit <target>` を使い、`init` は勧めない

### Requirement: プラットフォームごとの補い
スキルはReact Native / Expoでの補い方を含まなければならない（MUST）。
Expo公式skillsをプロジェクトに入れる手順と、native固有の指針をDESIGN.mdのproseで補うことを書く。
DESIGN.mdがまだ無いWebの新規UIでは、`frontend-design` スキルをフォールバックにする。

#### Scenario: Expo リポジトリ
- **WHEN** `app.json` と `expo` 依存のあるリポジトリでUIを書く
- **THEN** Expo公式skillsが入っているか確認し、無ければ導入コマンドを示す
