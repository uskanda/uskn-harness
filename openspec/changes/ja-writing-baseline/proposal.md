## Why

`ja-writing` の文体基準はPhase 3から「暫定」のまま残っている。
実測すると、検査対象の40文書にです・ます・である・だで終わる文は1つも無い。
すべて「〜する」のプレーン常体で書かれ、`no-mix-dearu-desumasu` の判定をすり抜けている。
基準が守られているのではなく、規則が発火していないだけ。

指針にセンサーが付いていない項目も2つある。
「日本語とASCIIの間に半角スペース」と「1文書1表記」は、スキルに書いてあるが誰も検査していない。
実測では地の文で「リポジトリ」42回と「リポジトリ」91回が混在している。
「指針にはセンサーを付ける」はハーネスの原則なので、この状態は原則に反する。

## What Changes

- 文体を確定する。仕様、ADR、設計、コミットは常体。pull request本文、チャット、UI文言は敬体。`no-mix-dearu-desumasu` の本文設定を「である」にする
- JTF日本語標準スタイルガイドのプリセットを追加する。表記の統一（漢字とかな、カタカナ、数字、単位、記号、スペース）が規則になる。**BREAKING**: 全角と半角の間にスペースを入れない文体に変わる。既存40文書の1970件を `textlint --fix` で直す
- 表記ゆれの辞書を追加する。prhと `skills/ja-writing/prh.yml`。10語程度から始める
- EARS記法の日本語テンプレートを `schemas/uskn` のspecs生成指示に置く。要求文の型を6つに固定する
- `commit` と `pr` スキルにtextlintの手順を組み込む。センサーの外にあった成果物を対象にする
- textlint hookの日本語判定を割合にする。英語のスキル文書が日本語の例を引用しても対象外になる
- `deps.json` のtextlintのbundleに2パッケージを足す

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

- `ja-writing-skill`: 文体基準の確定、プリセットと辞書の追加、スペース規則の反転
- `uskn-schema`: specsの生成指示にEARSの要求文テンプレートを足す
- `git-workflow-skills`: `commit` と `pr` が日本語の文章をtextlintで確認する
- `textlint-hook`: 日本語の判定をかなの有無から割合に変える。日本語の例を引用する英語文書は対象外になる

## Impact

- 変更：`skills/ja-writing/` の3ファイル（SKILL.md、textlintrc.json、新規prh.yml）。`deps.json`、`schemas/uskn/`、`skills/git/` のcommitとpr
- 変更：検査対象の40文書。機械的な置換が1970件、手直しが1件
- 記録は検査対象外なので直さない。対象は `docs/proposal-2026-09.md` と `openspec/changes/archive/`。新しい文体との差は残る
- `uskn-harness sync` が新しいパッケージを入れる。CIは `sync --tools` を通すので追加の作業は要らない
