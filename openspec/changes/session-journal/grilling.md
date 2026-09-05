# grilling 記録: session-journal

本 change の決定は Phase 2 の grilling（`docs/proposal-2026-09.md` §14 第6ラウンド）と、ハーネス全体の
grilling（同 §10）で確定済み。該当箇所の抜粋。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 履歴の粒度 | 要約 Markdown を git 管理、全文はローカルのみ、コミットにセッションのトレーラ | 第1ラウンド Q9 |
| 生成方式 | bash + jq の決定的スケルトン + 変更があったセッションだけエージェントが決定 / 未解決 / 次の一手を追記 | 第2ラウンド Q18 |
| 置き場 | 専用 private repo `uskanda/ai-sessions` → `~/.ai-sessions`、commit と push は SessionEnd で自動 | 第2ラウンド Q19、第6ラウンド Q39 |
| 命名 | `<owner>__<repo>/<YYYY-MM-DD>-<HHMM>-<slug>.md`、slug はエージェント、無ければ session id 先頭 8 桁 | 第6ラウンド Q40 |
| スケルトンの内容 | メタ、プロンプト各先頭 200 字、変更ファイル、コミット、使ったスキル。ツール出力とアシスタント本文は含めない | 第6ラウンド Q41 |
| タイミング | Stop ごとに増分更新、SessionEnd は commit / push のみ。決定欄はセッション中 1 回だけ block して書かせる | 第6ラウンド Q42 |
| SessionStart 注入 | 直近 3 件のタイトル、決定、次の一手 | 第6ラウンド Q46 |
| トレーラ | `<repo-context>` に session 情報を載せ、`commit` スキルが付ける | 第6ラウンド Q47 |
| 検索 | ripgrep + `recall`。episodic-memory は必要になったら | 第2ラウンド前提 |

## 後回しにしたもの

- 全文トランスクリプトの push（第2ラウンド Q19 の C）

## 状態

frontier は空。共有理解は 2026-09-05 に確認済み。
