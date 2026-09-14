## Why

このハーネスでは、変更はすべてgrillingのインタビューを経てから成果物を作る。
typoや文言の修正のような簡単な改修でも同じ手間がかかり、決めることが無いのに質問のラウンドを回すことになる。
ユーザーの明示的な指示があれば、grillingを省略して記録だけを残せるようにしたい。

## What Changes

- 新しいスキル `no-grilling` を追加する。grillingを省略した旨を `grilling.md` に記録し、続けてproposal、specs、design、tasksを作り、`/opsx:apply` を案内して止まる
- 省略はユーザーの指示があるときだけ行う。エージェントが提案するときは `AskUserQuestion` で確認を取る。ユーザーが自分で `/no-grilling` を実行したときは、それを指示とみなす
- 省略記録はテンプレートの見出しと表を残し、状態の行を「grillingは省略した。ユーザーの指示を<YYYY-MM-DD>に確認済み」とする
- `grilling-guard` の拒否理由に、no-grillingで省略する道を加える。判定そのものは変えない
- `AGENTS.md`、`templates/user/CLAUDE.md`、`README.md` にno-grillingを1行ずつ足す

## Capabilities

### New Capabilities

- `no-grilling-skill`: ユーザーの指示でgrillingを省略し、省略を記録してから成果物を作るスキル

### Modified Capabilities

- `grilling-guard`: 拒否理由に、no-grillingで省略する道を示す

## Impact

- 新規：`skills/no-grilling/SKILL.md`。`uskn-harness sync` が他の自前スキルと同じく配る
- `plugins/uskn-harness/hooks/scripts/grilling-guard.sh` と `grilling-guard.bats`
- 文書：`AGENTS.md`、`templates/user/CLAUDE.md`、`README.md`
