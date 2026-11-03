## ADDED Requirements

### Requirement: 仮ファイルの説明
ユーザー層の `CLAUDE.md` は、仮ファイルの説明を1行含まなければならない（MUST）。
説明には、sandboxのコマンドの実行中、`git status` などに `.bashrc` や `.claude/agents` のような0バイトの未追跡のファイルが出ることを書く。
あわせて、それらはsandboxが置いて後で消すもので、変更ではないことと、commitや削除をしないことを書く。
この行を足しても、要件「内容」の行数と大きさの上限を守る。

#### Scenario: 0バイトの .bashrc
- **WHEN** sandboxのコマンドが動いている間に、エージェントが `git status` を実行し、未追跡の0バイトの `.bashrc` が出る
- **THEN** エージェントは、それを自分の変更として報告せず、`git add` や削除をしない
