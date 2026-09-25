## 1. テストが版をdeps.jsonから読む

- [x] 1.1 `bin/tests/uskn-harness.bats` に `dep` を置き、テストが使う版を `deps.json` から読む形に直す。
  対象はnode、openspec、textlintとそのプリセット、agent-style、design.md。
  変更前の `deps.json` で `bats bin/tests/uskn-harness.bats` が通ることを確認する

## 2. ピンの形式

- [x] 2.1 `bin/tests/third-party.bats` を作り、ピンの形式のテストを書く。`ref` はタグか40桁のSHA、`clis` の `skills` の版は固定、workflowのClaude Codeの導入に版が無い。
  今の `deps.json` で失敗することを確認する
- [x] 2.2 `deps.json` を直す。12桁の `ref` を40桁にし、frontend-designに `ref` を足し、humanizerをv3.0.0、skills CLIを1.7.0にする。
  `skills` の各項目の `install` を `via` に置き換え、Impeccableに `ref`、`version`、`asset`、`sha256`、`cli`、`remove_agents` を持たせる。
  `_readme`、`updated`、確かめた項目の `checked` を直す。2.1のテストが通ることを確認する

## 3. skills CLIのスキルの導入とrefの照合

- [x] 3.1 `third-party.bats` にsyncのテストを足す。未導入なら `<source>#<ref>@<name>` で導入、lockの `ref` が同じなら `ok`、違うか無ければ入れ直して `updated`、lockに無ければ `conflict`。
  `XDG_STATE_HOME` があればその下のlockを読む。`--dry-run` は予定だけを出す。失敗を確認する
- [x] 3.2 `bin/uskn-harness` の `ensure_third_party` を、`via` とlockの `ref` で判定する形に書き換える。3.1と既存のテストが通ることを確認する

## 4. Impeccableの導入

- [x] 4.1 `third-party.bats` にImpeccableのテストを足し、失敗を確認する。
  stubでは、ピンから組み立てたzipのURL、sha256、CLIの版が記録される。`SKILL.md` の `version` が同じなら何もしない。`version` の無い `SKILL.md` は `conflict`
- [x] 4.2 `impeccable_install` の実際の手順のテストを足し、失敗を確認する。`USKN_HARNESS_STUB_NET=0` で、偽の `curl`、`mise`、`npx` を使う。
  sha256が合えば `IMPECCABLE_BUNDLE_PATH` を付けてCLIが実行され、合わなければCLIは実行されない
- [x] 4.3 `remove_agents` のテストを足し、失敗を確認する。挙げた4つが消え、他のagentは残る。`conflict` では消さない。2回目は何もしない
- [x] 4.4 `bin/uskn-harness` に `impeccable_install` とagentの削除を実装する。4.1から4.3と既存のテストが通ることを確認する

## 5. doctor

- [x] 5.1 `third-party.bats` にdoctorのテストを足し、失敗を確認する。
  対象は、lockの `ref` の差、lockに無い項目、Impeccableの版の差、残ったagent。
  `IMPECCABLE_NO_STALENESS_CHECK` の有無も試す。見る場所は `~/.claude/settings.json` の `env` と環境
- [x] 5.2 `cmd_doctor` のサードパーティスキルの検査を書き換える。5.1と、`doctor` が何も書かないテストが通ることを確認する

## 6. スキルとCI

- [x] 6.1 `skills/en-writing/SKILL.md` の最終パスに、humanizerに最終の文章だけを返させる1行を足す。`make verify-skills` が通ることを確認する
- [x] 6.2 `skills/ui-guidelines/SKILL.md` に、Impeccableが書いた `DESIGN.md` とサイドカーを戻す手順と、鮮度警告の止め方を書く。`make verify-skills` と `make verify-terms` が通ることを確認する
- [x] 6.3 `.github/workflows/verify.yml` のClaude Codeの導入に、版を固定しない理由のコメントを足す。2.1のworkflowのテストが通ることを確認する
- [x] 6.4 `bin/uskn-harness` の冒頭のコメント（手順6）を、ピンのrefとlockの照合に合わせて直す

## 7. 検証

- [x] 7.1 `make verify` が通ることを確認する。
  2026-09-25の計測で1分18秒。batsは190件がすべて通った
- [x] 7.2 `openspec validate deps-real-pinning --strict` が通ることを確認する
