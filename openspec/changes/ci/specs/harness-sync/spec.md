## ADDED Requirements

### Requirement: 道具だけの導入（--tools）
`uskn-harness sync --tools` は 3 つだけを用意しなければならない（MUST）。ランタイム（mise、node、jq）、`deps.json` でピンした npm global の CLI、OpenSpec schema の symlink。
参照点、実行ファイル、スキルとプラグインの symlink、サードパーティスキル、sessions repo、OpenSpec のユーザー層、ユーザー層 CLAUDE.md には触らない。
`--dry-run` と組み合わせられる。`--remove` と組み合わせたときは終了コード 2 で止まる。

#### Scenario: CI の runner
- **WHEN** 何も導入されていないマシンで `sync --tools` を実行する
- **THEN** mise の道具と npm global の導入が実行され、schema の symlink が作られる。`~/.claude/skills`、`~/.ai-sessions`、`~/.claude/CLAUDE.md` は作られない

#### Scenario: 2 回目
- **WHEN** 導入済みの環境で `sync --tools` を再実行する
- **THEN** 何も変更せず、各項目が `ok` として報告される

#### Scenario: --remove との併用
- **WHEN** `sync --tools --remove` を実行する
- **THEN** 何もせず終了コード 2 で止まる
