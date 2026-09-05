# journal-context Specification

## Purpose
前回までの判断をセッションの冒頭で思い出させ、コミットとセッションを session id で結びつける。SessionStart で注入する量は常時ロードのコストに直結するので最小限にする。

## Requirements

### Requirement: 直近 journal の注入
SessionStart hook は同じ `<project>` の journal を新しい順に最大 3 件選び、各件の title、`## Decisions`、`## Next`（各 10 行以内）を `<recent-sessions>` ブロックとして出力しなければならない（MUST）。journal が無ければ何も出さない。

#### Scenario: 3 件以上ある
- **WHEN** プロジェクトに 5 件の journal がある
- **THEN** 新しい 3 件だけが含まれる

### Requirement: repo-context の session 行
`session-start.sh` は hook モードで `- session: <sid8>` を `<repo-context>` に含め、コミットには `Session: <sid8>` トレーラを付けるよう記さなければならない（MUST）。

#### Scenario: hook モード
- **WHEN** SessionStart で session_id `abcdef1234…` が渡される
- **THEN** 出力に `session: abcdef12` がある
