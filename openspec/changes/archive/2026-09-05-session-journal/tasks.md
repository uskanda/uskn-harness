## 1. sessions repo と導入

- [x] 1.1 GitHub private `uskanda/ai-sessions` を README 付きで作り、`deps.json` に `repos.sessions` を追加する。`gh repo view uskanda/ai-sessions` が private を返す
- [x] 1.2 `sync` に `~/.ai-sessions` の clone、`doctor` に検査を加え、bats（スタブで clone コマンドを記録）が通る。このマシンで `sync` を実行して clone される

## 2. journal-update（TDD）

- [x] 2.1 `journal-update.bats` を書く: フィクスチャの transcript JSONL（ユーザー 3 件、ツール結果、Skill 呼び出し 2 件）から journal が作られる、front matter と 5 節、プロンプト 200 字、agent 欄の保全、block の 1 回限り（変更あり / 決定欄空 / 印なし）、`stop_hook_active` と `agent_type` と変更なしで block しない、`--path` と `--slug`、`~/.ai-sessions` 無しで無出力。RED を確認する
- [x] 2.2 `session-baseline.sh` に `baseline-head` の記録を足し、`journal-update.sh` を実装して GREEN、shellcheck 警告ゼロ

## 3. journal-end / journal-recent（TDD）

- [x] 3.1 `journal-end.bats`: bare origin を持つ `~/.ai-sessions` で commit と push が行われる、変更なしで commit しない、push 失敗でも exit 0。`journal-recent.bats`: 5 件から新しい 3 件、title / Decisions / Next の切り出し、journal 無しで無出力。RED を確認する
- [x] 3.2 実装して GREEN、shellcheck 警告ゼロ
- [x] 3.3 `session-start.sh` に `session: <sid8>` 行を追加し、既存の bats に検証を足して GREEN

## 4. スキルと配線

- [x] 4.1 `skills/journal/SKILL.md` と `skills/recall/SKILL.md` を書き、frontmatter 検査が通る
- [x] 4.2 `skills/git/commit/SKILL.md` に Session トレーラの規則を足す
- [x] 4.3 `hooks.json` に Stop（journal-update）、SessionEnd（journal-end、timeout 60）、SessionStart（journal-recent）を追加し、`claude plugin validate --strict` が通る。sandbox で `claude plugin details` に SessionEnd が現れる
- [x] 4.4 `templates/user/CLAUDE.md` に journal / recall の 2 行を足し、`sync` で反映。`openspec validate session-journal --strict` と `make verify` が通ることを確認してコミットする
