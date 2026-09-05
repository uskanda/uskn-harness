# journal-context Specification

## Purpose
前回までの判断をセッションの冒頭で思い出させ、コミットとセッションを session id で結びつける。SessionStart で注入する量は常時ロードのコストに直結するので最小限にする。

## Requirements

### Requirement: 直近 journal の注入
SessionStart hook は同じ `<project>` の journal を新しい順に最大 3 件選ばなければならない（MUST）。
各件の title、`## Decisions`、`## Next` を `<recent-sessions>` ブロックとして出力する。
節はそれぞれ 10 行以内に収める。journal が無ければ何も出さない。

#### Scenario: 3 件以上ある
- **WHEN** プロジェクトに 5 件の journal がある
- **THEN** 新しい 3 件だけが含まれる

### Requirement: repo-context の session 行
`session-start.sh` は hook モードで `- session: <sid8>` を `<repo-context>` に含めなければならない（MUST）。
同じ場所に、コミットへ `Session: <sid8>` トレーラを付けるよう記す。

#### Scenario: hook モード
- **WHEN** SessionStart で session_id `abcdef1234…` が渡される
- **THEN** 出力に `session: abcdef12` がある
