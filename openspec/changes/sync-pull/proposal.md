## Why

ADR-0002 は「マシン間の更新は `git pull`（`sync` が行う）」と書くが、`sync` は pull しない。
他マシンではハーネスの更新に `git pull` と `uskn-harness sync` の 2 手が要り、片方を忘れると古いスキルと hook が残る。
`docs/setup-new-machine.md` はこのずれを手順で埋めているが、埋めるべきは実装のほう。

## What Changes

- `sync` の最初に checkout の fast-forward を行う。安全なときだけ実行する。条件は git checkout であること、branch に upstream があること、作業ツリーが clean であること、fast-forward できること
- 上のどれかを満たさないときはスキップし、理由を 1 行で報告する。sync 自体は続行する
- pull で HEAD が動いたら、新しい `bin/uskn-harness` を `exec` し直す。走行中のスクリプトが入れ替わる問題を避け、残りの sync も新しいロジックで走らせる。再入は環境変数 `USKN_HARNESS_REEXEC` で 1 回に限る
- `--tools` と `--remove` では pull しない。`--dry-run` は予定を出すだけ。新しい `--no-pull` で明示的に止められる
- ネットワークと認証で固まらないよう `timeout 30`、`GIT_TERMINAL_PROMPT=0`、SSH の BatchMode を付ける。失敗は warn にして続行する

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

- `harness-sync`: checkout の更新（fast-forward と再実行、スキップ条件、`--no-pull`）を要件に足す

## Impact

- 変更: `bin/uskn-harness`、`bin/tests/uskn-harness.bats`
- 変更: `docs/setup-new-machine.md` の更新手順（pull が sync に入るため 2 手から 1 手になる）
- ADR-0002 の記述は変えない。実装が記述に追いつく
- CI は `--tools` を使うので振る舞いが変わらない
