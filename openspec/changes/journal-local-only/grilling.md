# grilling 記録: journal-local-only

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 「原則」の例外の扱い | hookとsyncはpushしない。`origin` には触らず、手動pushはユーザーの自由 | 第1ラウンド Q1 |
| 新しい端末での `~/.ai-sessions` の作り方 | 無ければ `git init` で作る。`deps.json` からsessionsリポジトリの項目を消す | 第1ラウンド Q2 |
| GitHubの `uskanda/ai-sessions` の扱い | 削除する | 第1ラウンド Q3 |
| 端末をまたぐ `recall` | 諦める。journalは端末ごとに閉じた記録とする | 第1ラウンド Q4 |
| 削除前の過去分の回収 | この端末でfetchとmergeを行い、GitHub上の全journalを集めてから削除する | 第2ラウンド Q5 |
| 削除の実行者と時期 | 実装の最後に、確認を取ってからエージェントが `gh repo delete` を実行する | 第2ラウンド Q6 |
| 削除後に残る `origin` | 何もしない。`doctor` もremoteを検査しない。古い端末では外してよいと手順書に書く | 第2ラウンド Q7 |
| 他の端末との順序 | 実装をmainに入れた直後に削除してよい。他の端末で未pushのjournalはその端末に残り、古いhookのpush失敗は無視される | 会話中に確認 |

## 後回しにしたもの

- なし

## 状態

frontierは空。共有理解は2026-09-14に確認済み。
