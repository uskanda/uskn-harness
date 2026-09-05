# grilling 記録: sync-pull

`sync` が checkout を pull しない件（セッション d69404e3 の Open）。ADR-0002 の「マシン間の更新は git pull（sync が行う）」と実装がずれている。
ユーザーが「pull を足して問題ない認識だが懸念はあるか」と問い、エージェントが懸念 5 件と対処案を提示、ユーザーが承認した（2026-09-05）。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| pull を足すか | 足す。ADR-0002 の記述に実装を合わせる | 会話中に確認 |
| 走行中スクリプトの入れ替わり | pull を sync の最初に置き、HEAD が動いたら新しい `bin/uskn-harness` を `exec` し直す。残りの sync も新しいロジックで走らせる。再入は環境変数 `USKN_HARNESS_REEXEC` で 1 回に限る | 第 1 ラウンド 懸念 1 |
| 開発機の作業ツリー | clean かつ upstream あり、fast-forward のときだけ pull する。dirty、detached、upstream 無し、非 fast-forward はスキップして理由を出す。merge と rebase はしない | 第 1 ラウンド 懸念 2 |
| CI と削除時 | `--tools` と `--remove` では pull しない。CI は検証対象の commit から離れてはならない | 第 1 ラウンド 懸念 3 |
| オフラインと認証待ち | `timeout 30` と `GIT_TERMINAL_PROMPT=0`、SSH は BatchMode。失敗は warn にして sync を続行する | 第 1 ラウンド 懸念 4 |
| 明示の回避 | `--dry-run` は予定を出すだけ。`--no-pull` を足す | 第 1 ラウンド 懸念 5 |

## 後回しにしたもの

- `doctor` に「checkout が origin より遅れている」の報告を足すか。今回は sync だけを変える
- 参照点が別の checkout を指す conflict 時の扱い。現状どおり警告のみ

## 状態

frontier は空。共有理解は 2026-09-05 に確認済み。
