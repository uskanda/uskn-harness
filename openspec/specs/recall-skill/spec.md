# recall-skill Specification

## Purpose
過去のセッションの判断をキーワードや session id で素早く引き、同じ論点を再決定する前に前提を思い出すためのスキル。journal を読むだけで編集はしない。

## Requirements

### Requirement: 検索
`recall <keywords>` は ripgrep（無ければ grep）でキーワードを検索しなければならない（MUST）。
対象は `~/.ai-sessions/<project>`、`--all` なら全プロジェクト。
一致した journal の title と該当行を新しい順に示す。
`recall <sid8>` は front matter の `session:` が一致する journal を開く。

#### Scenario: セッション id
- **WHEN** コミットの `Session: 3f2a9c1d` から `recall 3f2a9c1d` を実行する
- **THEN** その journal が表示される
