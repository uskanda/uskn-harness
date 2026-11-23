## MODIFIED Requirements

### Requirement: プラットフォームごとの補い
スキルはReact Native / Expoでの補い方を含まなければならない（MUST）。
Expo公式skillsをプロジェクトに入れる手順と、native固有の指針をDESIGN.mdのproseで補うことを書く。

#### Scenario: Expo リポジトリ
- **WHEN** `app.json` と `expo` 依存のあるリポジトリでUIを書く
- **THEN** Expo公式skillsが入っているか確認し、無ければ導入コマンドを示す

## ADDED Requirements

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
