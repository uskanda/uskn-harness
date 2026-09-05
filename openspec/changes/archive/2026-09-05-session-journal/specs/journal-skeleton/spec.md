## Purpose

セッションの事実（いつ、どこで、何を頼まれ、何が変わったか）を機械的に journal へ書き、判断の記録だけをエージェントに求める。

## ADDED Requirements

### Requirement: journal の場所と名前
Stop hook はセッションの journal を `~/.ai-sessions/<project>/<YYYY-MM-DD>-<HHMM>-<sid8>.md` に作らなければならない（MUST）。`<project>` は origin の `owner/repo` を `owner__repo` にしたもの（remote が無ければリポジトリのディレクトリ名）、日時は開始時刻（ローカル）、`sid8` は session_id の先頭 8 文字。パスは状態ディレクトリの `sessions/<session_id>/journal` に記録する。`~/.ai-sessions` が無ければ何もしない。

#### Scenario: 初回の Stop
- **WHEN** `~/.ai-sessions` があるリポジトリで最初の Stop が発火する
- **THEN** `~/.ai-sessions/<owner>__<repo>/` に journal が作られ、パスが状態ディレクトリに記録される

### Requirement: 決定的な内容
journal の先頭には front matter（`session`、`project`、`repo`、`branch`、`started`、`updated`、`title`）、続いて `## Prompts`（ユーザープロンプトの時刻と先頭 200 字）、`## Changes`（開始時点との `git diff --stat` と untracked）、`## Commits`（開始時点以降のコミット）、`## Skills`（使ったスキル名）がなければならない（MUST）。ツールの出力とアシスタントの本文は含めてはならない（MUST NOT）。

#### Scenario: プロンプトの抽出
- **WHEN** トランスクリプトに 3 つのユーザーメッセージと多数のツール結果がある
- **THEN** `## Prompts` には 3 行だけが並び、各行は 200 字以内

### Requirement: エージェント欄の保全
`<!-- agent -->` 以降の `## Decisions`、`## Open`、`## Next` は hook の再生成で上書きしてはならない（MUST NOT）。初回は見出しだけを作る。

#### Scenario: 再生成
- **WHEN** エージェントが `## Decisions` に 3 行書いたあと Stop が再発火する
- **THEN** 決定的な部分だけが更新され、3 行はそのまま残る

### Requirement: 決定欄を書かせる 1 回限りの block
作業ツリーが開始時から変わっており、`## Decisions` が空で、このセッションでまだ促していないとき、hook は `decision: block` と「`journal` スキルで決定 / 未解決 / 次の一手を書く」旨の理由を返し、促した印を残さなければならない（MUST）。`stop_hook_active`、サブエージェント、変更なしのときは block しない。

#### Scenario: 初回
- **WHEN** ファイルを変更したセッションで、決定欄が空のまま最初の Stop が来る
- **THEN** block され、理由に journal のパスが含まれる

#### Scenario: 2 回目以降
- **WHEN** 同じセッションで決定欄が空のまま再び Stop が来る
- **THEN** block されない（印がある）

### Requirement: slug と title
`journal-update.sh --session <sid8> --slug <slug>` は journal を `<日付>-<HHMM>-<slug>.md` に改名し、front matter の `title` を更新し、状態ディレクトリのパスを更新しなければならない（MUST）。`--path` は現在の journal のパスだけを出力する。

#### Scenario: 改名
- **WHEN** `--slug add-login` を実行する
- **THEN** ファイル名が `-add-login.md` で終わり、`session:` は変わらない
