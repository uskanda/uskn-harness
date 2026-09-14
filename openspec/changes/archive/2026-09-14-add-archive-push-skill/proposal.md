## Why

変更を終えるたびに、`/opsx:archive` でspecを同期してarchiveし、`make verify` を走らせ、`/commit` と `/push` を順に打っている。
archiveの途中の確認は毎回同じ答えで、コミットの要約行も「`<name>`をarchiveし、main specsに反映」の定型になっている。
この一連を1コマンドにまとめ、判断が要る場面だけユーザーに尋ねたい。

## What Changes

- 新しいスキル `archive-push` を追加する。1回の実行で1つの変更を扱う
- 始める前に、無関係な未コミットの変更があれば、archive分だけをコミットするか全部をコミットするかを尋ねる
- `tasks.md` の未完了の項目を分ける。コードや文書、specの変更を伴う項目があれば止まる。コマンドで確かめられる項目はその場で実行する。ユーザーの確認などエージェントが実行できない項目は完了とみなし、注記を付けてチェックする。分け方に迷えば項目ごとに尋ねる
- `make verify` をarchiveの前後で走らせ、失敗したら止まる
- archiveは `openspec-archive-change` スキルを呼び、specの同期は確認を求めずに行う
- `commit` スキルで1つのコミットにまとめ、`push` スキルでpushする
- `archive-push` は `disable-model-invocation: true` を持ち、ユーザーが `/archive-push` と打ったときだけ動く
- batsのテストでfrontmatterを確かめる
- `AGENTS.md`、`templates/user/CLAUDE.md`、`README.md` に `archive-push` を1行ずつ足す

## Capabilities

### New Capabilities

- `archive-push-skill`: 変更のarchiveからspecの同期、検証、コミット、pushまでを1回で行うスキル

### Modified Capabilities

なし。

## Impact

- 新規：`skills/archive-push/SKILL.md`。`uskn-harness sync` が他の自前スキルと同じく配る
- 新規：`bin/tests/archive-push-skill.bats`
- 文書：`AGENTS.md`、`templates/user/CLAUDE.md`、`README.md`
- 依存：`openspec-archive-change`、`commit`、`push` の各スキル。どれも手順を写さず呼び出す
