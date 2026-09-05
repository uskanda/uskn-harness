# recall-skill Specification

## Purpose
過去のセッションの判断をキーワードやsession idで素早く引き、同じ論点を再決定する前に前提を思い出すためのスキル。journalを読むだけで編集はしない。

## Requirements

### Requirement: 検索
`recall <keywords>` はripgrep（無ければgrep）でキーワードを検索しなければならない（MUST）。
対象は `~/.ai-sessions/<project>`、`--all` なら全プロジェクト。
一致したjournalのtitleと該当行を新しい順に示す。
`recall <sid8>` はfront matterの `session:` が一致するjournalを開く。

#### Scenario: セッション id
- **WHEN** コミットの `Session: 3f2a9c1d` から `recall 3f2a9c1d` を実行する
- **THEN** そのjournalが表示される
