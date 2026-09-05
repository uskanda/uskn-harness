# journal-context Specification

## Purpose
前回までの判断をセッションの冒頭で思い出させ、コミットとセッションをsession idで結びつける。SessionStartで注入する量は常時ロードのコストに直結するので最小限にする。

## Requirements

### Requirement: 直近 journal の注入
SessionStart hookは同じ `<project>` のjournalを新しい順に最大3件選ばなければならない（MUST）。
各件のtitle、`## Decisions`、`## Next` を `<recent-sessions>` ブロックとして出力する。
節はそれぞれ10行以内に収める。journalが無ければ何も出さない。

#### Scenario: 3 件以上ある
- **WHEN** プロジェクトに5件のjournalがある
- **THEN** 新しい3件だけが含まれる

### Requirement: repo-context の session 行
`session-start.sh` はhookモードで `- session: <sid8>` を `<repo-context>` に含めなければならない（MUST）。
同じ場所に、コミットへ `Session: <sid8>` トレーラを付けるよう記す。

#### Scenario: hook モード
- **WHEN** SessionStartでsession_id `abcdef1234…` が渡される
- **THEN** 出力に `session: abcdef12` がある
