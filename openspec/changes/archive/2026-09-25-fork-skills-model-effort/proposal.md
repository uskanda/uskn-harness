## Why

`commit` と `push` の実測26回では、1回あたりの費用が中央値$0.91、最大$5.41だった。
費用の54%は継承した会話の文脈の読み直しで、25%は期限切れキャッシュの書き直しだった。thinkingは5%にとどまる。
インラインのスキルでeffortやモデルを変えても、この費用はほとんど減らない。
会話の文脈を持たないforkでスキルを動かし、そこで安いモデルを使えば減る。

## What Changes

- forkで動かせるスキルにだけ、frontmatterで `context: fork`、`background: false`、`model:`、`effort:` を付ける規則を定める
- インラインのスキルには `model:` と `effort:` を付けない
- `commit` をforkにし、`model: sonnet` と `effort: low` で動かす
- `commit` の引数を `[課題ID] [指示の文]` に広げる。引数が無いときは現行と同じ動きをする
- `commit` の分割の規則を、変更の目的ごとに1〜5個とする形に改める
- `commit` のSession trailerを `${CLAUDE_SESSION_ID}` の先頭8文字から作り、常に付ける
- `recall` は対象から外す。一度forkにして評価したが、journalの仕組みを廃止すると決めたので（2026-09-25）、この変更では触らない
- `switch-base` と `sync-base` はインラインのまま残す。haikuのforkで評価したところ、5つの状態すべてで手順を実行しなかった
- `archive-push` は `commit` への指示を引数で渡す
- 規則を確かめるbatsのテストを足す

## Capabilities

### New Capabilities

- `skill-fork-policy`: forkのスキルとインラインのスキルに置けるfrontmatterの規則と、それを確かめるセンサー

### Modified Capabilities

- `git-workflow-skills`: `commit` の実行の形、引数、分割の規則、Session trailer

## Impact

- 変えるスキル
  - `skills/git/commit/SKILL.md`
  - `skills/archive-push/SKILL.md`
- テスト：`<bin/tests/skill-fork-policy.bats>` を新しく作る
- 用語：`openspec/glossary.yml` に「fork」「インライン」を足した。`skills/ja-writing/common-words.txt` には「キャッシュ」「メッセージ」を足した
- ユーザーが直接 `/commit` を打ったときも本体のモデルは動かない。会話で話した理由はコミットメッセージに入らない
- forkを起動するたびに、subagentの最初の文脈を書き込む固定費がかかる。sonnetで約$0.15
