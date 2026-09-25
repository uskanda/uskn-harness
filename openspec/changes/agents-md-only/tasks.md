## 1. onboard-check

- [x] 1.1 batsの `onboarded_repo` から `CLAUDE.md` を外す。置き場は `bin/tests/uskn-harness.bats`。次のテストを先に書いて失敗を確認する。`CLAUDE.md` 無しでok、`@AGENTS.md` を含めばok、含まなければwarn、`.claude/CLAUDE.md` も同じ
- [x] 1.2 `CLAUDE.local.md` のテストを先に書いて失敗を確認する。`CLAUDE.local.md` だけを置いたリポジトリでwarnになる。文言には削除と `claude-md-and-agents-md` の案内が出る。`CLAUDE.md` が `@AGENTS.md` を含めば、`CLAUDE.local.md` があってもok
- [x] 1.3 `onboard-check` の未導入のリポジトリのテストを直す。`CLAUDE.md` のwarnの期待を外し、`CLAUDE.md` の項目がokになることを期待に足す
- [x] 1.4 `cmd_onboard_check` の判定を `design.md` のとおりに直し、1.1から1.3のテストが通ることを確認する

## 2. doctor の最低版の検査

- [x] 2.1 `deps.json` の `runtimes` に `claude-code`（`min_version: 2.1.281`、`role`）を足し、`_readme` に `min_version` の説明を足す。`jq -e '.runtimes["claude-code"].min_version' deps.json` で確認する
- [x] 2.2 batsの `setup` に偽の `claude`（最低版以上を返す）を置き、PATHのCLIのテストを先に書いて失敗を確認する。古い版でwarnに両方の版が出る、最低版以上でok、版が読めない出力でwarn
- [x] 2.3 VS Code拡張のテストを先に書いて失敗を確認する。拡張は一時 `HOME` の `.vscode-server/extensions` と `.vscode/extensions` に作る。ディレクトリ名は `anthropic.claude-code-<version>-linux-x64` とする。期待は3つ。古い拡張ではwarnにディレクトリと両方の版が出る。同じディレクトリに2つの版があれば、新しいほうだけを比べる。古いCLIと新しい拡張が並ぶときのwarnは1つ
- [x] 2.4 CLIと拡張のどちらも無いときに項目が出ないテストを先に書き、失敗を確認する
- [x] 2.5 `cmd_doctor` に版の検査を足し、2.2から2.4のテストと既存の `doctor` のテストが通ることを確認する
- [x] 2.6 batsで2つを確かめる（2026-09-25の確認Q26）。最低版よりずっと新しい版（3.0.0）が `ok` になること。`sync` がClaude Codeを入れないこと

## 3. テンプレートとスキル

- [x] 3.1 `templates/repo/CLAUDE.md` を削除し、`templates/repo/AGENTS.md` に任意の `## Claude Code` 節の案内を足す。`templates/repo/` に `CLAUDE.md` が無いことを確かめるbatsのテストを足して通す
- [x] 3.2 `skills/onboard-harness/SKILL.md` を直す。description、置くものの表、置く手順、`CLAUDE.md` が正本のときの例を新しい規則に合わせる。確認は `grep -n "CLAUDE.md" skills/onboard-harness/SKILL.md`。残った行が新しい規則と矛盾しないこと
- [x] 3.3 `skills/onboard-harness/SKILL.md` の16行目付近で、置くファイルの列挙を "upper bound, not a checklist" と呼ぶ記述を直す。ADR-0001の1.3節、`AGENTS.md`、onboard-skillのspecと同じく「現時点の内訳で、上限ではない」（"today's contents, not a cap"）とする。確認は `grep -n "upper bound" skills/onboard-harness/SKILL.md` が何も出さないこと
- [x] 3.4 `bin/uskn-harness` の先頭コメントと使い方の表示から古い説明を除く。確認は `grep -n "CLAUDE.md" bin/uskn-harness`

## 4. 文書

- [x] 4.1 `docs/adr/0003-agents-md-only.md` を書く。中身は `design.md` のADR-0003の節のとおり。決定、v2.1.277とv2.1.281の根拠、読まれない条件、回避策、既存リポジトリを触らないことを書く。回避策には、ユーザー層の `instructionFiles` を `claude-md-and-agents-md` にする方法を入れ、ハーネスは設定しないと書く。textlintの指摘が無いことを確認する
- [x] 4.2 `docs/adr/0001-harness-architecture.md` の該当2か所にADR-0003への注記を足し、textlintの指摘が無いことを確認する
- [x] 4.3 `AGENTS.md`（このリポジトリ）を直す。hard constraintとLayoutから、プロダクトリポジトリの `CLAUDE.md` を外す。`README.md` の同じ言及も直す。`grep -n "CLAUDE.md" AGENTS.md README.md` で確認する
- [x] 4.4 `openspec/glossary.yml` へ、足した用語を先に入れる。`make verify` の用語検査が通ることを確認する

## 5. このリポジトリの CLAUDE.md

- [ ] 5.1 PATHの `claude` を2.1.281以上へ更新し、`claude --version` で確認する。セッションを1度開いて閉じる（ユーザーが行う）
- [ ] 5.2 `CLAUDE.md` を新しいセッションで退避し、`/memory` の一覧に `AGENTS.md` のパスが出ることを確認する。PATHのCLIとVS Code拡張の両方で見る。読まれなければ `CLAUDE.md` を戻して報告し、5.3を止める（ユーザーが行う。5.3はこのブランチで済ませたので、マージの前に確かめる）
- [x] 5.3 OpenSpecの1行を `CLAUDE.md` から `AGENTS.md` へ移し、`CLAUDE.md` を削除する。`uskn-harness onboard-check .` で `CLAUDE.md` の項目がokになることを確認する

## 6. 検証

- [x] 6.1 `make verify` が通ることを確認する
- [ ] 6.2 `uskn-harness doctor` を実機で走らせ、PATHのCLIとVS Code拡張の版の項目がどちらもokで出ることを確認する（ユーザーが行う）。5.1のあとで確かめる。2026-09-25の時点では、CLIの2.1.270がwarn、拡張の2.1.282がok
