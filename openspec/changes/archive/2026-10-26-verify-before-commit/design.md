# Design

## Context

動機はproposal.mdのWhyを見ること。

- Claude Codeのcommitの指示は、セッションの開始時に `verify` か `simplify` という名前のスキルがあるとき、commitの直前にそれを実行させる。文書とテストだけの変更は除く。2.1.286以降の振る舞いである
- 組み込みの `/verify` とpluginのスキルは、この指示の対象にならない。ハーネスの `verify` は、`~/.claude/skills/verify` へのsymlinkで、ユーザー層のスキルとして読まれる
- ハーネスの `Makefile` には `verify-fast` があり、verify gateがStopのたびに走らせる。`templates/repo/Makefile` には無い

## Goals / Non-Goals

**Goals:**

- commitの直前の確認を、`verify-fast` のあるリポジトリでは数秒で終わらせる

**Non-Goals:**

- commitの直前に呼ばれたことを、スキルの外の仕組みで判定すること。スキルの本文に書き、エージェントが文脈から判断する

## Decisions

### D1: 名前を変えずに、commit の直前の呼び出しを生かす

commitの直前の呼び出しは、Claude Codeがユーザー層の `verify` のために用意した仕組みである。
スキルの本文に、commitの直前に呼ばれたときの節を足す。

捨てた案は次のとおり。

| 捨てた案 | 理由 |
|---|---|
| 今のまま、commitのたびにフルの `make verify` を走らせる | ハーネスでは1回に数分かかり、turnの終わりのverify gateと検証が重なる |
| スキルの名前を変え、組み込みの `/verify` を使えるように戻す | 組み込みの `/verify` はアプリを動かして確かめるスキルで、組み込みの `run` スキルと役割が重なる。commitの直前の確認も無くなる |
| `disable-model-invocation: true` を付ける | verify gateに止められたときに、エージェントがこのスキルで直せなくなる |
| `includeGitInstructions: false` | commitとPRについてのClaude Codeの指示が、すべて消える |

ADRは書かない。スキルの振る舞いを1つ足すだけで、ハーネスの構成は変わらないため。

### D2: 完了の根拠は変えない

commitの直前の `verify-fast` は、commitを止めるかどうかの確認だけに使う。
完了の根拠の要件（同じターンの検証規約の実行）は、そのまま残す。

### D3: センサー

`bin/tests/verify-skill.bats` を足し、スキルの本文がcommitの直前の節を持ち、`verify-fast` を名指しすることを確かめる。
Makefileは、`skills/verify/SKILL.md` の変更でこのbatsを選ぶ。

## Risks / Trade-offs

- commitの直前の呼び出しだとエージェントが気付かず、フルの検証を走らせる → 時間がかかるだけで、検証は弱くならない
- 2.1.286より古いClaude Codeでは、commitの直前の呼び出しが無い → 今と同じく、turnの終わりのverify gateだけが走る
