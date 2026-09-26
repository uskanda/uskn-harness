## MODIFIED Requirements

### Requirement: 名前の実在検査
`terms-check` は地の文のバッククォートで囲まれた名前を集め、実在を検査しなければならない（MUST）。
実在とみなすのは、gitが追跡するパス、その要素、追跡ファイルの中身、用語集の語、許可リストの語。
プレースホルダー（山かっこを含む語）、代入の形、版の例は対象外にする。
見つからない名前は指摘する。
追跡ファイルのうち文字列として読めないもの（NULバイトを含むもの）は中身の照合から外す。UTF-8として読めない文字は置き換えて読む。

#### Scenario: 実在しないファイル名
- **WHEN** 地の文に、リポジトリのどこにも無いファイル名をバッククォートで書く
- **THEN** その名前が指摘される

#### Scenario: プレースホルダー
- **WHEN** 山かっこを含む仮の名前を書く
- **THEN** 指摘されない

#### Scenario: 画像を追跡するリポジトリ
- **WHEN** PNGの画像を追跡するリポジトリで、実在しない名前を含む文書を `make verify` から検査する
- **THEN** 検査は最後まで走り、その名前が指摘され、終了コードは非ゼロになる

### Requirement: 検査の厳しさ
`terms-check` はhookとして呼ばれたとき、書き込みを止めてはならない（MUST NOT）。指摘は `additionalContext` で返す。
`make verify` から呼ばれたときは、指摘があれば終了コードを非ゼロにしなければならない（MUST）。
`make verify` から呼ばれて検査そのものが異常終了したときも、終了コードを非ゼロにしなければならない（MUST）。
python3が無いとき、`terms-check` は検査を飛ばして終了コード0で終わる。ただし `VERIFY_STRICT=1` の `make verify` では非ゼロで終わる（MUST）。

#### Scenario: 書きかけの文書
- **WHEN** 指摘のある文書をWriteで書く
- **THEN** 書き込みは成功し、指摘が文脈として返る

#### Scenario: 完了前の検証
- **WHEN** 指摘が残ったまま `make verify` を実行する
- **THEN** 検証は失敗する

#### Scenario: python3 が無い CI
- **WHEN** python3がPATHに無い状態で `make verify-terms VERIFY_STRICT=1` を実行する
- **THEN** 終了コードは非ゼロで、出力に `VERIFY_STRICT` が含まれる

## ADDED Requirements

### Requirement: hook の対象は Markdown
`terms-check` はhookとして呼ばれたとき、書かれたファイルの拡張子が `.md` か `.markdown` の場合だけ検査しなければならない（MUST）。
それ以外のファイルでは何も出力せず、終了コード0で終わる。

#### Scenario: 日本語のコメントを持つコード
- **WHEN** 用語集に無いカタカナ語をコメントに含む `.ts` ファイルをWriteで書く
- **THEN** 出力は空
