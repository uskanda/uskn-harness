## Why

監査で、hook、インストーラ、スキルのfrontmatterに不具合が見つかった。
エージェントが自分で許可ファイルに書けば境界の解除ができてしまう。`terms-check` と `sync` は失敗を終了コード0で隠す。テストの一部は失敗し得ない形で書かれている。
センサーが黙って通る状態では指針が守られない。既存の要件の範囲で直す。

## What Changes

- 許可ファイル（`sessions/<session_id>/allow`）を、write-guardとbash-guardの両方で書けなくする。書くのは `allow-repo.sh` だけにする
- `terms-check` が画像のような文字列として読めないファイルで落ちても、検査が通ってしまう不具合を直す。CLIでは失敗を非ゼロで返し、`VERIFY_STRICT=1` でpython3が無いときも失敗にする
- `terms-check` のhookはMarkdown（`.md`、`.markdown`）だけを検査する
- bash-guardのchezmoiの拒否を、セッションの許可ファイルがchezmoiのsource directoryを覆うときは解除する。`chezmoi -v apply` のように下位コマンドより前にオプションがある形も拒否する
- bash-guardのコマンド解析を、引用符、`pushd`、`git -c`、`--git-dir` に対応させる。gitの下位コマンドだけを書き込み操作として判定し、sedの式をパスとみなす誤検知を無くす
- `uskn-harness sync` は途中の手順が失敗したとき非ゼロで終わる。予約名 `uskn-harness` のスキルがあれば導入前に止まる
- 6つのgitスキルのfrontmatterをYAMLとして正しい形に直す。`make verify` がすべての `SKILL.md` のfrontmatterをYAMLとして解析する
- 失敗し得ないbatsの判定を直す。ガードのテストは `TMPDIR` の値が何であっても通る形にする
- GNUの `timeout` が無い環境（macOS）でも、verify gateとtextlintのhookは時間の上限を守る
- Claude Codeに無くなった `MultiEdit` をhookのmatcherと文書から外す
- verify gateのStop hookの出力から、schemaに無い `hookSpecificOutput` の重複を外す
- 用語集の「verify gate」の定義、プラグインの説明とREADME、`.gitignore`、`lib/common.sh` の古いコメントを実態に合わせる

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

- `write-guard`: 許可リストから許可ファイルを除き、許可ファイルへの書き込みを拒否する
- `bash-guard`: chezmoiの拒否の解除条件、下位コマンドより前のオプション、許可ファイルへの書き込みの拒否、gitの下位コマンドの判定、引用符付きのパスを定める
- `terminology-guard`: hookの対象をMarkdownに限り、CLIでの検査の失敗とpython3の欠如の扱いを定める
- `harness-sync`: 手順の失敗と予約名での終了コードを定める
- `textlint-hook`: 実行条件のツールから `MultiEdit` を外す
- `verify-gate`: Stop hookの出力のキーと、`timeout` が無い環境での時間の上限を定める
- `ci-verify`: スキルのfrontmatterのYAML解析をverifyに加え、strictモードの対象にpython3とPyYAMLを加える

## Impact

- hook：`plugins/uskn-harness/hooks/scripts/` の下。`bash-guard.sh`、`write-guard.sh`、`terms-check.sh`、`verify-gate.sh`。
  `textlint-check.sh`、`grilling-guard.sh`、`lib/common.sh` と `hooks.json` も変わる
- テスト：`plugins/uskn-harness/hooks/tests/` と `bin/tests/` のbats（journal系を除く）
- インストーラ：`bin/uskn-harness`
- スキル：`skills/git/` の `cleanup-merged`、`fix-ci`、`push`、`rebase`、`switch-base`、`sync-base` のfrontmatter
- 検証：`Makefile` の `verify-skills` と `verify-terms`、`.github/workflows/verify.yml`
- 文書：`openspec/glossary.yml`、`plugins/uskn-harness/README.md`、`.gitignore`。
  プラグインの `plugins/uskn-harness/.claude-plugin/plugin.json` も変わる
- journal系のhook、スキル、テストは別の変更が扱うので触らない
