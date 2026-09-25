## 1. センサー

- [x] 1.1 `<bin/tests/skill-fork-policy.bats>` を書き、`skill-fork-policy` の5つの規則と対象の4スキルの期待値を確かめる。`bats bin/tests/skill-fork-policy.bats` が期待値のテストだけで失敗することを確かめる

## 2. commit

- [x] 2.1 `commit` のfrontmatterに `context: fork`、`model: sonnet`、`effort: low`、`background: false` を足す。1.1の `commit` のテストが通ることを確かめる
- [x] 2.2 `commit` の本文に引数の読み方（課題ID、指示の文、引数なし）を書き、specの `commit` の引数の要件と読み合わせる
- [x] 2.3 `commit` の分割の規則を、変更の目的ごとに1〜5個とする形に改め、specの分割の要件と読み合わせる
- [x] 2.4 `commit` のSession trailerの手順を、`${CLAUDE_SESSION_ID}` の先頭8文字に変える。置換されないときは `CLAUDE_CODE_SESSION_ID` を読むと書く
- [x] 2.5 `skills/archive-push/SKILL.md` の手順7を書き換え、指示の文を引数で `commit` へ渡す
- [x] 2.6 scratchpadのcloneで前回の2つの状態を再現して評価する。目的ごとの分割、差分と合うメッセージ、実行したセッションIDの先頭8文字のtrailerを確かめる。結果は2.1.270で3コミットと1コミット、$0.35と$0.28。trailerが例の値と同じだったので、6.4で確かめ直した

## 3. recall（2026-09-25に対象から外した）

journalの仕組みを廃止すると決めたので、`skills/recall/SKILL.md` をHEADに戻し、`recall-skill` の差分と `recall` のbatsのテストを消した。以下は外す前に行った作業の記録である。

- [x] 3.1 `recall` のfrontmatterに `context: fork`、`model: sonnet`、`effort: low`、`background: false` を足す。1.1の `recall` のテストが通ることを確かめる
- [x] 3.2 `recall` の本文に、`<repo-context>` が無いときにgit remoteのownerとリポジトリ名から対象のプロジェクトを決める手順を書く
- [x] 3.3 cloneで既知のsession idとキーワードを引いて評価し、journalにある決定だけを引用することを確かめる。崩れたら3.1を戻し、`recall-skill` の差分から実行の形の要件を外す（キーワード `archive-push スキル名` で正しいjournalの決定だけを引用。$0.09）

## 4. switch-base と sync-base

- [x] 4.1 `switch-base` のfrontmatterに `context: fork`、`model: haiku`、`background: false` を足す。`sync-base` にも同じ3行を足し、1.1のテストが通ることを確かめる（足したが、4.2と4.3で崩れたので戻した）
- [x] 4.2 cloneで、未コミットの変更がある場合とfast-forwardの場合を `switch-base` で評価する。崩れたら4.1の `switch-base` を戻し、specの差分を直す（haikuは2つとも崩れた。戻してspecの差分から外した）
- [x] 4.3 cloneで、未コミットの変更がある場合、fast-forward、マージ、コンフリクトの場合を `sync-base` で評価する。崩れたら4.1の `sync-base` を戻し、specの差分を直す（haikuは4つとも崩れた。戻してspecの差分から外した）

## 5. 仕上げ

- [x] 5.1 `openspec validate fork-skills-model-effort --strict` が通ることを確かめる
- [x] 5.2 `make verify` が通ることを確かめる

## 6. 点検の指摘への対応（2026-09-25）

- [x] 6.1 `archive-push` の手順7に、範囲が「archiveだけ」なら無関係なパスをコミットしないと伝える行と例を足す
- [x] 6.2 `commit` の規則6を、置換された後も矛盾しない書き方に直す。例のtrailerを `<sid8>` にし、例の値を写さないと書く
- [x] 6.3 `commit` の英語のメッセージの参照先を `en-writing` に直す
- [x] 6.4 2.1.282で `commit` を評価し直す。`--session-id` で渡したIDとtrailerが一致することを確かめる。結果は1コミットと3コミットで、trailerは一致した。要約行の見出し記号とスキル2つの合併は、スキルを直して解消した
- [x] 6.5 `skill-fork-policy.bats` で、`allowed-tools` をYAMLのリストで書いたときの `AskUserQuestion` も見つける
- [x] 6.6 `openspec validate fork-skills-model-effort --strict` と `make verify` が通ることを確かめる
