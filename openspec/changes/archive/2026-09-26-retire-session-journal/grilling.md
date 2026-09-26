# grilling 記録: retire-session-journal

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| journalの仕組み | 廃止する。journalとrecallのスキル、journal-recent・journal-update・journal-endのhook、sessionsリポジトリの管理を外す | ユーザーの指示（2026-09-25） |
| Co-Authored-By | `commit` が常に `Co-Authored-By: Claude <noreply@anthropic.com>` を付ける | 第1ラウンド Q3 |
| Session trailer | `commit` から外す。既存のコミットはそのまま | 第1ラウンド Q4 |
| `~/.ai-sessions` の既存データ | ハーネスは作成も検査もやめ、データには触れない。消すかはユーザーが決める。write-guardの許可からも外す | 第1ラウンド Q5 |
| 状態ディレクトリ | journal専用のファイル（transcript、journal、journal-prompted、project、started、baseline-head）は書かない。`sync` が30日より古いセッションのディレクトリを消す | 第1ラウンド Q6 |
| journalの代わり | 新しい仕組みは作らない。決定の記録はOpenSpecのアーカイブ（grilling.md、design.md）、ADR、コミットに、好みの記録はネイティブのauto memoryに任せる。`recall` は削除する。ADR-0004でADR-0001 §10を置き換える | 第1ラウンド Q7 |
| `<repo-context>` のsession行 | 出さない。`allow-repo` は `${CLAUDE_SESSION_ID}` の先頭8文字をsid8に使う | 監査の提案をユーザーが承認（2026-09-25） |

## 後回しにしたもの

- 既存のjournalの削除（ユーザーが決める）

## 状態

frontierは空。共有理解は2026-09-25に/okで確認済み。
