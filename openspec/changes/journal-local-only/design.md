## Context

journalの処理は3か所にある。`journal-end.sh` はcommitとpushを行う。
`bin/uskn-harness` の `ensure_sessions_repo` は `deps.json` に書いたURLからcloneする。
`doctor` はgitリポジトリかどうかを検査する。
この端末の `~/.ai-sessions` は `origin` より4コミット先行し、未追跡のjournalが1件ある。他の端末にも独自のcloneがある。

## Goals / Non-Goals

**Goals:**
- hookとsyncがネットワークに出ない
- 既存の端末の `~/.ai-sessions` を作り直さずに使い続けられる

**Non-Goals:**
- 端末間でjournalを共有する別の手段
- 既存の `origin` を外すこと。`doctor` でremoteを検査すること

## Decisions

- **pushの削除だけで済ませる。** `journal-end.sh` の最終行（push、失敗時のpull --rebaseと再push）を消す。`timeout` の補助関数も要らなくなる。remoteを外す案は、手動pushの余地を残すという判断（grilling Q1）に反するので採らない
- **`git init` は `run_step` を通さずに直接実行する。** `run_step` はテストでネットワークの手順を実行せず記録だけにするため、ローカルで済む `git init` には合わない。dry-runでは計画だけを表示し、報告（`created` / `ok` / `conflict` / `fail`）は既存のclone処理と揃える。初期ブランチ名は指定せず、端末のgit設定に従う
- **`deps.json` の `repos` は項目ごと消す。** 他に `repos` を読む箇所が無ければ、キーごと消す。読む箇所があれば空のオブジェクトを残す
- **ADR-0001 §10は本文を書き換える。** 以前の変更と同じく、ADRを現状の正本として扱う。`docs/proposal-2026-09.md` のQ19とQ39は記録として残し、注記だけ足す

## Risks / Trade-offs

- 削除で、この端末に未取得のjournalが失われる。対策：削除の前に、この端末で `git fetch` とmergeを行い、GitHub上の全journalを集める
- 古いhookが動く端末ではpushが失敗し続ける。対策：失敗は元から無視される。プラグインの更新が届けば止まる
- 削除後の `origin` が存在しないURLを指す。対策：hookは使わないので実害は無い。手順書に「外してよい」と書く
- 端末を失うと、その端末のjournalも失われる。対策：受け入れる（grilling Q4）。必要な端末では手動pushを案内する

## Migration Plan

1. hook、sync、テスト、文書を変更し、`make verify` を通してmainに入れる
2. この端末の `~/.ai-sessions` で未コミットの分をcommitし、`git fetch` のあと `git pull --rebase` でGitHub上の分を取り込む。件数を確認する
3. ユーザーに確認を取り、`gh repo delete uskanda/ai-sessions` を実行する。`delete_repo` の権限が足りなければ `gh auth refresh -s delete_repo` を案内する

削除は取り消せない。手順2と3の間に、`git bundle` で `~/.ai-sessions` の退避をscratchpadに作っておく。
