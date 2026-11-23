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

#### Scenario: Expo リポジトリ
- **WHEN** `app.json` と `expo` 依存のあるリポジトリでUIを書く
- **THEN** Expo公式skillsが入っているか確認し、無ければ導入コマンドを示す

### Requirement: 新規UIの方向性
`ui-guidelines` スキルは、新規UIの最初の手順として `frontend-design` スキルで方向性を決めると書かなければならない（MUST）。
新規UIは、新しい画面と新しいアプリの最初の画面を指す。既存の画面の小さな修正は含めない。
対象はWebとExpo（React Native）の両方で、`DESIGN.md` の有無を問わない。
`DESIGN.md` があるときは、方向性をそのトークンとproseの範囲で決め、足りない値は実装の前に `DESIGN.md` へ足す。
`DESIGN.md` が無いときは、`frontend-design` の選択をテンプレートから作った `DESIGN.md` のトークンとproseに書き、ユーザーに確認してからUIを書く。

#### Scenario: DESIGN.md があるリポジトリの新しい画面
- **WHEN** `DESIGN.md` のあるリポジトリで新しい画面を作る
- **THEN** `frontend-design` で方向性を決め、`DESIGN.md` に無い値は先に `DESIGN.md` へ足して `designmd lint` を通してから実装する

#### Scenario: DESIGN.md が無いリポジトリの新しいアプリ
- **WHEN** `DESIGN.md` の無いExpoリポジトリで最初の画面を作る
- **THEN** `frontend-design` の選択を `DESIGN.md` に書き、ユーザーに色と書体を確認してからUIを書く

#### Scenario: 既存の画面の小さな修正
- **WHEN** 既存の画面の余白を少し直す
- **THEN** `frontend-design` は通さず、`DESIGN.md` のトークンとImpeccableのコマンドで直す

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
