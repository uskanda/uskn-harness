## Context

動機は proposal.md の Why を参照。`cmd_sync` は参照点の用意から始まり、ランタイム、CLI、symlink と続く。
ネットワークを使う手順は `run_step` を通り、`--dry-run` では予定の出力、`USKN_HARNESS_STUB_NET=1` では記録だけになる。
hook スクリプトとスキルは checkout への symlink なので、checkout が動けば配布物も同時に動く。

## Goals / Non-Goals

- Goals: 他マシンで `uskn-harness sync` の 1 手が更新まで含む。開発機の作業を壊さない。CI の再現性を保つ
- Non-Goals: merge や rebase の自動化。`doctor` での遅れの報告。dotfiles 側の更新（`chezmoi update` のまま）

## Decisions

1. 更新は `cmd_sync` の中、`--remove` の分岐より後、参照点の用意より前に置く。`--tools` は早期 return で先に抜けるので、条件を書かなくても対象外になる
2. 安全性は 4 つの前提で担保する。git の作業ツリー、branch に upstream、作業ツリーが clean、`--ff-only`。どれも「壊さない」ための条件で、満たさないときはスキップして理由を出す。代替案は `git stash` を挟む自動化だが、ユーザーの作業を勝手に動かすため採らない
3. HEAD が動いたら `exec` し直す。bash はスクリプトを実行しながら読むため、走行中のファイルが入れ替わると挙動が定義されない。加えて、更新後の導入は新しいロジックで行うのが筋。ループ防止に `USKN_HARNESS_REEXEC=1` を渡し、渡された側は更新を試みない。`bin/uskn-harness` が実行可能でないとき（`USKN_HARNESS_DIR` がテストの一時 checkout を指す場合など）は `exec` せず続行する
4. 引数は `main` の先頭で `ORIG_ARGV` に控える。`exec` は同じ引数で行う
5. 非対話と時間の上限は `timeout 30`（あれば）、`GIT_TERMINAL_PROMPT=0`、`GIT_SSH_COMMAND="ssh -oBatchMode=yes"` で担保する。private repo の認証が切れていても待ちにならず、warn で続行する

## Risks / Trade-offs

- [開発機が clean かつ遅れているとき、意図せず HEAD が動く] → `--ff-only` なので失うものは無い。`--no-pull` で止められる
- [pull が Claude Code のセッション中に hook スクリプトを差し替える] → 手で pull する今と同じ状況。hook は起動のたびにスクリプトを読み直すため、次の呼び出しから新しい版になる
- [`exec` でループする] → 環境変数で 1 回に限る。更新が無ければそもそも `exec` しない
- [テストが実際の checkout を pull する] → テストは一時的な bare origin と clone を作り、`USKN_HARNESS_DIR` をそこへ向ける

## Migration Plan

無し。`sync` を実行した時点から有効になる。元に戻すときは `--no-pull` か revert。
