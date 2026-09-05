# journal-skeleton Specification

## Purpose
セッションの事実を機械的にjournalへ書く。
事実とは、いつ・どこで・何を頼まれ・何が変わったかを指す。判断の記録だけをエージェントに求める。

## Requirements

### Requirement: journal の場所と名前
Stop hookはセッションのjournalを作らなければならない（MUST）。
置き場は `~/.ai-sessions/<project>/<YYYY-MM-DD>-<HHMM>-<sid8>.md`。
`<project>` はoriginの `owner/repo` を `owner__repo` にしたもの。remoteが無ければリポジトリのディレクトリ名を使う。
日時はローカル時刻の開始時刻、`sid8` はsession_idの先頭8文字。
パスは状態ディレクトリの `sessions/<session_id>/journal` に記録する。`~/.ai-sessions` が無ければ何もしない。

#### Scenario: 初回の Stop
- **WHEN** `~/.ai-sessions` があるリポジトリで最初のStopが発火する
- **THEN** `~/.ai-sessions/<owner>__<repo>/` にjournalが作られ、パスが状態ディレクトリに記録される

### Requirement: 決定的な内容
journalの先頭にはfront matterがなければならない（MUST）。
項目は `session`、`project`、`repo`、`branch`、`started`、`updated`、`title`。
続いて次の節を置く。

- `## Prompts`: ユーザープロンプトの時刻と先頭200字
- `## Changes`: 開始時点との `git diff --stat` とuntracked
- `## Commits`: 開始時点以降のコミット
- `## Skills`: 使ったスキル名

ツールの出力とアシスタントの本文は含めてはならない（MUST NOT）。

#### Scenario: プロンプトの抽出
- **WHEN** トランスクリプトに3つのユーザーメッセージと多数のツール結果がある
- **THEN** `## Prompts` には3行だけが並び、各行は200字以内

### Requirement: エージェント欄の保全
`<!-- agent -->` 以降の `## Decisions`、`## Open`、`## Next` はhookの再生成で上書きしてはならない（MUST NOT）。初回は見出しだけを作る。

#### Scenario: 再生成
- **WHEN** エージェントが `## Decisions` に3行書いたあとStopが再発火する
- **THEN** 決定的な部分だけが更新され、3行はそのまま残る

### Requirement: 決定欄を書かせる 1 回限りの block
作業ツリーが開始時から変わっており、`## Decisions` が空で、このセッションでまだ促していないとする。
このときhookは `decision: block` と、「`journal` スキルで決定 / 未解決 / 次の一手を書く」旨の理由を返さなければならない（MUST）。
あわせて促した印を残す。`stop_hook_active`、サブエージェント、変更なしのときはblockしない。

#### Scenario: 初回
- **WHEN** ファイルを変更したセッションで、決定欄が空のまま最初のStopが来る
- **THEN** blockされ、理由にjournalのパスが含まれる

#### Scenario: 2 回目以降
- **WHEN** 同じセッションで決定欄が空のまま再びStopが来る
- **THEN** blockされない（印がある）

### Requirement: slug と title
`journal-update.sh --session <sid8> --slug <slug>` はjournalを改名しなければならない（MUST）。
新しい名前は `<日付>-<HHMM>-<slug>.md`。
あわせてfront matterの `title` と、状態ディレクトリに記録したパスを更新する。
`--path` は現在のjournalのパスだけを出力する。

#### Scenario: 改名
- **WHEN** `--slug add-login` を実行する
- **THEN** ファイル名が `-add-login.md` で終わり、`session:` は変わらない
