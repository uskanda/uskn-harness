## ADDED Requirements

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
