## Why

エージェントは受け取った語彙を増幅する。人は曖昧な語で止まって聞き返すが、エージェントは自分の解釈で書き進める。
その結果、既存概念の別名、実在しない名前、一般に無い複合語が文書に入り込む。
本リポジトリの実測では、地の文のバッククォートの名前192個のうち24個は、コードとパスのどちらにも無かった。
`writing-for-agents` は「造語は事前知識を呼び出せない」と既に書いているが、指針だけでセンサーが無い。
「指針にはセンサーを付ける」はハーネスの原則なので、この状態は原則に反する。

## What Changes

- 名前の出所を3つに限る規約を置く。コードにある識別子、用語集にある語、参照した公式文書の語
- 用語集を `openspec/glossary.yml` に置く。どのリポジトリでも同じ相対パスと同じファイル名にする。ハーネス自身も持つ
- センサー `terms-check` を追加する。名前の実在と未知語を検査し、hookでは警告、`make verify` では失敗する
- スキル `audit-writing` を追加する。既存リポジトリの用語と文章を一括で監査し、用語集を対話で作ってから修正する
- `ja-writing`、`en-writing`、AGENTS.md、AGENTS.mdテンプレートに同じ規約を書く。`writing-for-agents` は外部スキルなので触らない
- 「置けるのは5点まで」という表現を「規約が求めるファイルだけを置く」に直す。列挙は現時点の内訳であって上限ではない

## Capabilities

### New Capabilities

- `terminology-guard`: 名前の出所の規約、用語集の書式と置き場、2つの検査
- `audit-writing-skill`: 既存リポジトリの用語と文章を一括で監査し修正するスキル

### Modified Capabilities

- `ja-writing-skill`: 名前と用語の規約への参照を足す
- `en-writing-skill`: 同じ規約を英語の文章にも適用する
- `onboard-skill`: 置けるファイルの説明を「規約が求めるものだけ」に直す
- `design-templates`: 同じ表現の修正

## Impact

- 新規： `terms-check.sh` とそのbats。`openspec/glossary.yml`、`skills/ja-writing/common-words.txt`、`skills/audit-writing/SKILL.md`
- 変更： `Makefile` と `hooks.json`。スキル2つ（`ja-writing`、`en-writing`）。`templates/repo/AGENTS.md`、`AGENTS.md`、ADR-0001
- プロダクトリポジトリへ配るのは規約の文だけ。用語集の中身と検査の設定は各リポジトリが持つ
