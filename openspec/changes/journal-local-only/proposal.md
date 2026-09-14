## Why

journalは今、SessionEndのたびにGitHubのprivateリポジトリ `uskanda/ai-sessions` へpushされている。
セッションの記録を外部サービスに置かず、各端末のローカルgitだけで扱いたい。

## What Changes

- **BREAKING** SessionEnd hookはjournalをcommitするだけにし、pushとpull --rebaseをやめる。`origin` があっても触らない
- **BREAKING** `sync` は `~/.ai-sessions` が無いとき、cloneせずに `git init` で空のリポジトリを作る
- `deps.json` からsessionsリポジトリの項目を消す
- journalは端末ごとに閉じた記録とする。他の端末のjournalは、直近のjournalの注入と `recall` のどちらでも見えない
- ADR-0001 §10、README、`docs/setup-new-machine.md`、`journal` スキル、`~/.ai-sessions/README.md` をこの前提に直す
- 移行：この端末でGitHub上の全journalをfetchしてmergeし、確認を取ってから `uskanda/ai-sessions` を削除する

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

- `journal-sync`: SessionEndの処理をcommitだけにし、sessionsリポジトリの配置をcloneから `git init` に変える
- `harness-sync`: sessionsリポジトリの用意をcloneから `git init` に変える

## Impact

- `plugins/uskn-harness/hooks/scripts/journal-end.sh` と `journal-end.bats`
- `bin/uskn-harness` の `ensure_sessions_repo` と `uskn-harness.bats`
- `deps.json`
- 文書：ADR-0001と `README.md`。`docs/setup-new-machine.md` と `skills/journal/SKILL.md` も直す
- 外部：GitHubの `uskanda/ai-sessions` を削除する。取り消せない
