## MODIFIED Requirements

### Requirement: humanizer との併用
スキルは、AIらしい文体を除く最終パスとして `humanizer` スキルを呼ぶ手順を含まなければならない（MUST）。
呼ぶときは、文章が別の作業の一部だと伝え、humanizerに最終の文章だけを返させる（humanizerのembedded mode）。

#### Scenario: 最終パス
- **WHEN** 監査の指摘を直し終えた
- **THEN** `humanizer` を呼び、その出力をもう一度監査と突き合わせる

#### Scenario: 返ってくるもの
- **WHEN** en-writingの最終パスで `humanizer` を呼ぶ
- **THEN** humanizerは下書きと残ったパターンの一覧を返さず、最終の文章だけを返す
