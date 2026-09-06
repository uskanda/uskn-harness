## 1. 用語集と一般語リスト

- [x] 1.1 `openspec/glossary.yml` を作る。ハーネスの用語20語程度を、正の表記、1文の定義、避ける別名、英語表記で書く。YAMLとして読めることを確認する
- [x] 1.2 `skills/ja-writing/common-words.txt` を作る。地の文のカタカナ語132語を種にする。1行1語であることを確認する

## 2. センサー（TDD）

- [x] 2.1 `terms-check.bats` を書く。検査する項目は4つ。名前の実在、除外規則、未知語、hookモードとCLIモードの違い。先に走らせて失敗を確認する
- [x] 2.2 `terms-check.sh` を実装し、2.1が通ることを確認する。shellcheckも通す
- [x] 2.3 `hooks.json` のPostToolUseに `terms-check.sh` を足す。`claude plugin validate --strict` が通ることを確認する
- [x] 2.4 Makefileに `verify-terms` を足し、`verify` に繋ぐ。既存の指摘を直し、`make verify` が通ることを確認する

## 3. 規約の文

- [x] 3.1スキル2つに名前の出所の規約を書く。対象は `ja-writing` と `en-writing`。各スキルが500行以内であることを確認する
- [x] 3.2 `templates/repo/AGENTS.md` に規約の4行を足す。プロダクトリポジトリが受け取る文であることを確認する
- [x] 3.3 AGENTS.mdとADR-0001の「上限」の表現を「規約が求めるファイルだけを置く」に直す。textlintが通ることを確認する

## 4. 監査スキル

- [x] 4.1 `skills/audit-writing/SKILL.md` を書く。4段階の手順、洗い出しのコマンド、対話の進め方、修正の範囲。500行以内であることを確認する
- [x] 4.2 `uskn-harness sync` がこのスキルをsymlinkすることを確認する

## 5. 検証

- [x] 5.1 `make verify` が通ることを確認する
- [x] 5.2実在しない名前をわざと書いて、hookが警告し `make verify` が失敗することを確認する
- [x] 5.3 commitとpushの後、CIが緑になることを確認する
