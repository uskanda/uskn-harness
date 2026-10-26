# grilling 記録: narrow-sandbox-scope

ADR-0009のsandboxは、実際の作業で制約が強すぎた。sandboxに残すのを、効果を前もって判断できない実行だけに絞り、よく知られた道具をsandboxの外で動かす（ユーザーが案Aを選んだ）。
grillingの前に、この数日の作業でsandboxが邪魔をした場面を6つ挙げた。

- `.git/config` に書けない
- `excludedCommands` が先頭にしか当たらない
- キャッシュに書けない
- この端末自身のIPに解決されるホストへ接続できない
- 作業ディレクトリに空のファイルが被さる
- 入れ子の `claude -p` が外側のsandboxに閉じ込められる


調べて分かったことは次のとおり。

- `allowWrite` で許した範囲の中で、`denyWrite` によって一部だけを書き込み禁止にできる。`~/.local/state` を許し、`~/.local/state/uskn-harness` を禁止できた
- `excludedCommands` の `claude *` で、入れ子の `claude -p` は外側のsandboxの外で動く
- sandboxが被せる空のファイルは、`/dev/null` を写したもので、通常のファイルではない
- terms-checkは、未追跡のファイルと `os.path.exists` で名前の実在を判定するので、空のファイルを実在と見なしていた
- bash-guardは、コマンドを単純なコマンドに分けて判定している
- syncは、`permissions` の下の4つを除き、設定断片の配列でliveの配列を置き換える

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| sandboxの外に出す道具 | `git`、`gh`、`glab`、`docker`、`mise`、`claude`、`uskn-harness`、`uskn-loop`、`chezmoi`、`ssh`、`scp`。gitの下位コマンドは `git *` にまとめる。`npm`、`pnpm`、`npx`、`make`、`python`、`node`、`curl` はsandboxに残す | 第1ラウンド Q1 |
| 一覧の持ち方 | コードに埋め込まず、`sandbox.excludedCommands` のデータとして持つ。上の11個は設定断片の既定値にする。簡単に足せるよう、ユーザー層にスキルを1つ用意する | 第1ラウンド Q1へのユーザーの追加の指示 |
| sandboxの中で書ける範囲 | `~/.cache`、`~/.npm`、`~/.local/share/mise`、`~/.local/share/pnpm`、`~/.local/state`。`denyWrite` で `~/.local/state/uskn-harness` を禁止する | 第1ラウンド Q2 |
| 途中に出てくる外の道具 | bash-guardが `additionalContext` で知らせる。拒否はしない | 第1ラウンド Q3 |
| terms-checkとsandboxの空のファイル | 名前の実在は、通常のファイルとディレクトリだけで数える | 第1ラウンド Q4 |
| スキルで足したコマンドの範囲 | その端末だけ。スキルは `uskn-harness sandbox-exclude <pattern>` を呼び、端末別設定に足して、設定だけをsyncし直す。全端末で使うときは、設定断片に移すPRを作る | 第2ラウンド Q5 |
| syncでのsandboxの配列 | `sandbox.excludedCommands` と `sandbox.filesystem.allowWrite` を集合として扱う | 第2ラウンド Q6 |
| センサーが読む一覧 | bash-guardは、liveの `~/.claude/settings.json` の `sandbox.excludedCommands` を読む | 第2ラウンド Q7 |
| スキルを起動できる人 | ユーザーだけ（`disable-model-invocation: true`） | 第2ラウンド Q8 |
| 名前、仕様、ADR | changeは `narrow-sandbox-scope`、スキルは `sandbox-exclude`。下位コマンドは `--list` と `--remove <pattern>` も持ち、設定断片の既定値は `--remove` で外せない。仕様は `user-settings`、`bash-guard`、`terminology-guard`、`harness-sync` を変え、`sandbox-exclude-skill` を足す。ADR-0011でADR-0009の決定3と4を差し替える | 最終確認 |
| archiveの順 | このchangeのarchiveの前に、`adopt-bash-sandbox`、`add-dir-records-allow` の順にarchiveする | 最終確認 |

## 後回しにしたもの

- `gh` と `glab` による別のリポジトリの操作を、bash-guardで拒否すること。今はauto modeのclassifierが判断する

## 状態

frontierは空。共有理解は2026-10-26に確認済み。
