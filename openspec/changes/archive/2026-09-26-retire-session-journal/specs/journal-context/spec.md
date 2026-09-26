## REMOVED Requirements

### Requirement: 直近 journal の注入
**Reason**: セッションjournalの仕組みを廃止する。決定の記録はOpenSpecのアーカイブ、ADR、コミットに残る。
**Migration**: 前回までの判断は `openspec/changes/archive/` の `grilling.md` と `design.md`、`docs/adr/`、`git log` で確かめる。SessionStartは直近の要約を注入しない。

### Requirement: repo-context の session 行
**Reason**: session idはjournalとコミットを結ぶためのものだった。journalとSessionトレーラを廃止するので、`<repo-context>` に載せる理由が無い。
**Migration**: セッションIDが要るスキルは `${CLAUDE_SESSION_ID}` を使い、置換されないときは環境変数 `CLAUDE_CODE_SESSION_ID` を読む。
