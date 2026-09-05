## 1. プラグインの骨格

- [ ] 1.1 `plugins/uskn-harness/.claude-plugin/plugin.json` と `hooks/hooks.json`（SessionStart → `${CLAUDE_PLUGIN_ROOT}/hooks/scripts/session-start.sh`）を作り、`claude plugin validate --strict plugins/uskn-harness` が成功することを確認する
- [ ] 1.2 `Makefile` の `verify-skills` を深さ 3 に広げ、`verify-plugin`（`claude plugin validate --strict`、`claude` が無ければ skip）と `bats plugins/uskn-harness/hooks/tests` を `verify` に加え、`make verify` が通ることを確認する

## 2. session-start.sh（TDD）

- [ ] 2.1 `plugins/uskn-harness/hooks/tests/session-start.bats` を先に書く: 非 git ディレクトリで空出力・exit 0、github.com / セルフホスト gitlab / remote 無しの hosting 判定、`origin/HEAD` あり・なしの default 解決、`develop` と `qa` の有無、AGENTS.md の `## Branch model` 上書き（部分上書き、`qa: none`、見出し無し）、`--plain hosting` / `--plain branches` / `--json` の形式、jq の無い PATH。まず全件 RED になることを確認する
- [ ] 2.2 `session-start.sh` を実装し、2.1 のテストが GREEN、`shellcheck` が警告ゼロになることを確認する
- [ ] 2.3 このリポジトリと `~/repos/monolith`（読み取りのみ）を `cwd` にして実行し、`<repo-context>` の内容が実態（hosting、default、integration）と一致することを目視で確認する

## 3. テンプレート

- [ ] 3.1 `templates/repo/AGENTS.md` に `## Branch model` の fenced yaml 例（default / integration / qa / release_tag、`qa: none` の説明）を含む最小の AGENTS.md を書き、2.1 のテストのフィクスチャがこの形式を使っていることを確認する

## 4. スキルの移管と汎用化

- [ ] 4.1 `skills/git/commit` `push` `rebase` `pre-merge` `fix-ci` `nessun-dorma` を英語で書き直す（手順は旧スキルと 1 対 1、固定名と履歴を除去）。`make verify` の frontmatter 検査が通ることを確認する
- [ ] 4.2 `skills/git/pr` を design の決定 6 に従って書く（引数の分岐、auto-merge の安全弁、QA のソースブランチ保持、GitLab の API 検証ゲート）。`grep -n "develop\|staging\|Issue #" skills/git/pr/SKILL.md` が規則としての固定名に一致しないことを確認する
- [ ] 4.3 `skills/git/sync-base` `switch-base` `cleanup-merged` `release` を書く（`cleanup-merged` は git alias 非依存、`release` は GitHub / GitLab 両対応と `release_tag` 参照）。frontmatter 検査が通ることを確認する
- [ ] 4.4 エイリアス `mr` `mr-main` `mr-qa` `merge-develop` `switch-develop-branch` を `disable-model-invocation: true` の 1 行本文で作り、frontmatter 検査が通ることを確認する
- [ ] 4.5 監査: `grep -rn "Issue #\|staging\|#349" skills/git` が一致せず、`grep -rln "develop\|qa" skills/git` の一致がすべて「例」か「エイリアス名」の文脈であることを確認する

## 5. 統合確認と記録

- [ ] 5.1 sandbox の `CLAUDE_CONFIG_DIR` に `skills/uskn-harness -> plugins/uskn-harness` の symlink を張り、`claude plugin details uskn-harness@skills-dir` に SessionStart hook が 1 件現れることを確認する
- [ ] 5.2 `README.md` の状態を Phase 1 進行中に更新し、`deps.json` に変更が要らないことを確認する
- [ ] 5.3 `openspec validate migrate-git-skills --strict` が通り、`make verify` が通ることを確認してコミットする
