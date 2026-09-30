# Tasks

## 1. 比喩の動詞の検出

- [x] 1.1 `deps.json` のtextlintの `bundle` に `@textlint-rule/textlint-rule-pattern` 2.0.2を足し、`checked` を更新する。`uskn-harness sync --tools` の後に `uskn-harness doctor` がtextlintを `ok` と報告することで確かめる
- [x] 1.2 `<detect.txt>` と `<pass.md>` を `<bin/tests/fixtures/ja-writing/>` に書く。中身はdesign 4節のとおり。`<bin/tests/ja-writing-rules.bats>` を書く。設定を変える前に実行し、`<detect.txt>` の検査が失敗することを確かめる
- [x] 1.3 `skills/ja-writing/textlintrc.json` に `@textlint-rule/pattern` を足す。design 2節の12のパターン、語ごとのメッセージ、`allowNodeTypes: ["BlockQuote"]` を設定する。1.2のbatsがすべて通ることで確かめる
- [x] 1.4 batsのtextlintかルールのパッケージが無い場合を試す。既定では `skip`、`VERIFY_STRICT=1` では失敗になることを、PATHから外した実行で確かめる
- [x] 1.5 README、ADR-0001・0002・0003、main spec 12件にある22件を、design 5節の方向で書き直す。`make verify-textlint` が通り、書き直しの差分に要件の意味の変更が無いことを読んで確かめる
- [x] 1.6 `docs/adr/0001-harness-architecture.md` の日本語のセンサーの行に、パターンのルールを書き足す。`make verify-textlint` と `make verify-terms` が通ることで確かめる

## 2. ja-writing スキル

- [x] 2.1 `skills/ja-writing/SKILL.md` の冒頭のセンサーの説明を、パターンのルールを含む形に直す。`## Fixing findings` の表に比喩の動詞の行を足す。`make verify-skills` と `make verify-terms` が通ることで確かめる
- [x] 2.2 `## Sentences` に3規則（主文を先に、比喩の動詞を使わない、印象を狙った形を使わない）を足す。分割の行に分けてよい条件を足す。規則ごとに資料の例か実例を1つ付けたことを読んで確かめる
- [x] 2.3 `## Register` の表から「体言止め可」を外し、体言止めを使える場所（表のセル、箇条書き、見出し、コミットの要約行）を1行で書く。`archive-push` の要約行の形がこの範囲に入ることを読んで確かめる
- [x] 2.4 `## Rereading` と `## When prose is called machine-written` の節を足す。前者には読み直しの問いと対象（ファイル、コミットメッセージ、PR本文）を書き、資料の例3を例文にする。後者には指摘を受けたときと指摘するときの手順を書く。`ja-writing-skill` のdeltaの各Scenarioに対応する記述があることを読んで確かめる
- [x] 2.5 `## Worked example` に2つ目の例（`拒否の側に倒す` → `判定できないときは拒否する`）を足す。直す前の文を `textlint` にかけると比喩の動詞の指摘が出て、直した後の文では出ないことを確かめる。スキルが500行以内であることを `make verify-skills` で確かめる

## 3. audit-writing スキル

- [x] 3.1 `skills/audit-writing/SKILL.md` の洗い出しに、`ja-writing` の3規則に当たる文を候補として挙げる手順を足す。textlintの出力に比喩の動詞が含まれることも書く。4段階の構成が変わっていないことを読んで確かめる
- [x] 3.2 `audit-writing` の用語集づくりの段階に、挙げた文の意味を10個ずつユーザーに問う手順を足す。推測で意味を補わないことも書く。修正の段階は、意味を確かめた文だけを書き直す形に直す。`audit-writing-skill` のdeltaの各Scenarioに対応する記述があることを読んで確かめる

## 4. 全体の確認

- [x] 4.1 `make verify VERIFY_STRICT=1` を実行し、すべて通ることを確かめる
- [x] 4.2 textlintとハーネスの設定で、資料の悪い例5つを書いた一時ファイルを検査する。例1・2・4・5が指摘され、例3は指摘されないことを確かめる（例3は読み直しの手順で扱う）
