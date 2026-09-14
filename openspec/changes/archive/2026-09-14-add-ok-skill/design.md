## Context

自前のスキルは `skills/` に置けば、`uskn-harness sync` が `~/.claude/skills/<name>` へsymlinkで配る。
`make verify-skills` はfrontmatterの `name` とディレクトリ名の一致を確かめる。
`allow-repo` など、ユーザーだけが呼べるスキルはすでに `disable-model-invocation: true` を使っている。
スキルの本文を機械的に確かめるbatsのテストはまだ無い。

## Goals / Non-Goals

**Goals:**
- `ok` がユーザーの入力でしか動かないことを、テストで保つ
- 承諾の範囲、上書き、次の入力の扱いを本文の実例で示す

**Non-Goals:**
- エイリアス `go`（grillingで作らないと決めた）
- 直前の応答の構造（推奨の書式や次の入力の書き方）を他のスキル側で統一すること

## Decisions

- **`disable-model-invocation: true` で自己承諾を防ぐ。** 本文で「自分で呼ばない」と書くだけの案もあるが、守られた保証が無い。frontmatterならClaude Codeが呼び出しそのものを止める。前例の `allow-repo` と揃う
- **センサーは `bin/tests/ok-skill.bats` に置く。** `bin/tests` は `TEST_DIRS` に含まれ、`make verify` が走らせる。frontmatterに `disable-model-invocation: true` があることを確かめる。hookのテストの置き場 `plugins/uskn-harness/hooks/tests` はhookの本体に対応するので使わない
- **次の入力の実行は、名指しされた1つに限る。** ユーザーはコマンドを見たうえで `/ok` と打つので、その入力をしたとみなす。実行するコマンドが持つ確認は省かない。候補が複数あるときや、ユーザーだけが呼べるスキルのときは実行しない
- **本文は手順と実例で書く。** 実例は、grillingのラウンドへの `/ok q2はB`、成果物の提示と `/opsx:apply` の案内への `/ok`、対象が無い応答への `/ok` の3つを載せる

## Risks / Trade-offs

- 直前の応答が長く、提案と次の入力の見分けがつきにくい → 迷ったら質問する。本文で推測による実行を禁じる
- 上書きの自由文を誤って別の論点に当てる → 当てはまる論点が1つに決まらなければ質問する
- `templates/user/CLAUDE.md` の変更が各端末の `~/.claude/CLAUDE.md` にすぐには届かない → 配り方は既存の仕組みに従う
