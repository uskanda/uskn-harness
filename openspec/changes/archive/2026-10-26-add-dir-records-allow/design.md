# Design

## Context

動機はproposal.mdのWhyを見ること。

- `allow-repo.sh --session <sid8> <path>` は、`<sid8>` で始まる最新のセッションの状態ディレクトリを探し、パスの実体を `allow` に追記する。状態ディレクトリはSessionStartのsession-baselineが作る
- `DirectoryAdded` の入力は、共通の欄（`session_id`、`cwd` など）と、`directory`（絶対パス）と `source` である。Claude Codeはhookの終わりを待たない。hookは追加を止められず、`systemMessage` は次のターンのClaudeに渡る（`slash_command` のとき）
- sandboxの中のBashは状態ディレクトリに書けない。hookはsandboxの外で動く
- write-guardの拒否の理由は、エージェントに `/allow-repo` を案内している。`/allow-repo` は `disable-model-invocation` で、エージェントは自分で打てない

## Goals / Non-Goals

**Goals:**

- ユーザーが打つのを `/add-dir <path>` の1つにする
- 許可ファイルに書けるのが、ハーネスのhookだけである状態を保つ

**Non-Goals:**

- `/permissions` のWorkspaceのタブで足したディレクトリの記録（`DirectoryAdded` が呼ばれない）
- 追加を取り消したときの許可の取り消し（取り消しのイベントが無い）。許可はセッションが終わると無くなる

## Decisions

### D1: hook は allow-repo.sh を呼ぶ

新しいスクリプト `<directory-added.sh>` は、入力から `session_id` と `directory` を読む。
続けて `allow-repo.sh --session <session_id> <directory>` を実行する。
記録の処理を `allow-repo.sh` の1か所に保つため。成功したら `systemMessage` を出力する。

捨てた案は、`directory-added.sh` に記録の処理を書き写すことである。同じ処理が2か所に分かれる。

### D2: allow-repo スキルを削除する

`skills/allow-repo/` と `bin/tests/allow-repo-skill.bats` を削除する。syncは、ハーネスから消えたスキルのsymlinkを片付ける。

捨てた案は次のとおり。

| 捨てた案 | 理由 |
|---|---|
| `/allow-repo` を残す | 許可の入口が2つになり、どちらを打つかをユーザーが迷う |
| `/allow-repo` が `/add-dir` を実行する | スキルから組み込みのコマンドを実行する手段が文書に無い |

### D3: 拒否の理由

write-guardとbash-guardの拒否の理由は、「ユーザーがこのセッションで明示的に許したなら、ユーザーが `/add-dir <path>` を実行する」と書く。
エージェントは `/add-dir` を打てないので、打つのはユーザーである。

### D4: ADR-0010

`docs/adr/0010-add-dir-records-allow.md` に、D1、D2、捨てた案を書く。ADR-0009の決定7を差し替える旨を書く。

## Risks / Trade-offs

- Claude Codeはhookの終わりを待たないので、`/add-dir` の直後の書き込みが、記録の前に拒否されることがある → hookは数十ミリ秒で終わる。拒否されたら、もう一度書き込めば通る
- デスクトップアプリの画面でディレクトリを足したときに `DirectoryAdded` が呼ばれるかは、文書に無い → 呼ばれなければ、ユーザーが `/add-dir` を打つ。tasksで確かめる

## Migration Plan

1. `adopt-bash-sandbox` をmainへマージしてarchiveした後に、このchangeをマージしてarchiveする
2. 各端末で `uskn-harness sync` を実行する。`/allow-repo` のsymlinkが消える
