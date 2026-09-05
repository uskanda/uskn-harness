## 1. 依存と設定

- [x] 1.1 `deps.json` のtextlintのbundleに2パッケージを足す。`textlint-rule-preset-jtf-style` と `textlint-rule-prh`。`uskn-harness doctor` がピンを読めることを確認する
- [x] 1.2 `skills/ja-writing/textlintrc.json` を書き換える。JTFプリセット、prh、`no-mix-dearu-desumasu` の常体設定。設定だけでtextlintが起動することを確認する
- [x] 1.3 `skills/ja-writing/prh.yml` を作る。実測で混在が見つかった語と、ぶれに効く語で10語程度。`textlint --config` で辞書が読まれることを確認する
- [x] 1.4このマシンに2パッケージを導入する。`uskn-harness sync` を実行し、`doctor` が0 problemになることを確認する

## 2. 既存文書の移行

- [x] 2.1検査対象の40文書に `textlint --fix` を掛ける。差分を読み、コードブロックと識別子が壊れていないことを確認する
- [x] 2.2全角コロンの直後に残る半角スペースを詰める。29か所を対象に、コードブロックの外だけを直す
- [x] 2.3残る指摘を手で直す。`make verify` のtextlintが0件になることを確認する

## 3. 指針の更新

- [x] 3.1 `skills/ja-writing/SKILL.md` を書き換える。暫定の断り書きを外し、成果物ごとの文体、JTFの表記規則、辞書、EARSへの参照を書く。500行以内であることを確認する
- [x] 3.2 `schemas/uskn` のspecs生成指示にEARSの6型と日本語のテンプレートを足す。`openspec instructions specs` の出力に現れることを確認する
- [x] 3.3 `commit` と `pr` スキルにtextlintの手順を足す。手順が一時ファイル経由であることを確認する

- [x] 3.4 textlint hookの日本語判定をかなの割合にする。batsを先に書き、英語のスキル文書が対象外になることと、日本語が主の文書が対象になることを確認する

## 4. 検証

- [x] 4.1 `make verify` が通ることを確認する
- [x] 4.2新しい設定で日本語のMarkdownを書き、PostToolUse hookが新しい規則で指摘することを確認する
- [x] 4.3 commitとpushの後、CIが緑になることを確認する
