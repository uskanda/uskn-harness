## Why

grillingの各ラウンドやOpenSpecの成果物に対して、推奨どおりでよいと返す場面が多い。
直前の応答が「実装は `/opsx:apply` で始めます」のように次の入力を示したときも、ユーザーはそのコマンドを打ち直している。
短い1コマンドで承諾し、推奨と違う点だけを書き添えられるようにしたい。

## What Changes

- 新しいスキル `ok` を追加する。直前の応答にある推奨や提案を承諾する
- 引数に `q2はB` のような上書きや自由文があれば、その点だけユーザーの記載に従う。どの論点を指すか分からないときは質問する
- 直前の応答が次の入力を名指ししていれば、ユーザーがそれを入力したとみなして実行する。候補が複数なら質問し、エージェントから呼べないスキルならユーザーに入力を促して止まる
- `ok` は `disable-model-invocation: true` を持ち、ユーザーが `/ok` と打ったときだけ動く
- batsのテストで、`ok` がエージェントから呼べないことを確かめる
- `README.md` と `templates/user/CLAUDE.md` に `ok` を1行ずつ足す

## Capabilities

### New Capabilities

- `ok-skill`: 直前の応答の提案を承諾し、示された次の入力へ進むスキル

### Modified Capabilities

なし。

## Impact

- 新規：`skills/ok/SKILL.md`。`uskn-harness sync` が他の自前スキルと同じく配る
- 新規：`bin/tests/ok-skill.bats`
- 文書：`README.md`、`templates/user/CLAUDE.md`
