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

### Requirement: Impeccable が書いた DESIGN.md とサイドカー
Impeccableのコマンドが `DESIGN.md` かサイドカーを書いたとき、`ui-guidelines` スキルは、その書き込みを戻すよう指示しなければならない（MUST）。
正本はリポジトリの `DESIGN.md` のまま変えない。
残したい決定は、Google DESIGN.md形式のトークンとproseとして `DESIGN.md` に書き、`designmd lint` を通す。
Impeccableのコマンドのあとに `DESIGN.md` と `.impeccable/` の変更を確かめる手順を含める。

#### Scenario: 新しい画面の手順が DESIGN.md を書いた
- **WHEN** Impeccableの新しい画面の手順が、`DESIGN.md` と `.impeccable/design.json` を書いた
- **THEN** 両方を元に戻し、残したい決定だけを `DESIGN.md` に書いて `designmd lint` を通す

### Requirement: 鮮度警告の止め方
`ui-guidelines` スキルは、Impeccableの鮮度警告をユーザー層の環境変数 `IMPECCABLE_NO_STALENESS_CHECK=1` で止めると書かなければならない（MUST）。
プロダクトリポジトリに `.impeccable/config.json` を足して止めることはしない。
環境変数が無い環境で出た警告は報告に記録するだけで、`/impeccable doctor` と `document` は実行しない。

#### Scenario: 鮮度警告が出た
- **WHEN** Impeccableが「DESIGN.mdが古い」「サイドカーが無い」と報告する
- **THEN** 警告を報告に記録するだけで、`DESIGN.md` とサイドカーは書かない
