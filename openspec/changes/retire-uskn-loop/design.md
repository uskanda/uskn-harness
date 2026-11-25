# Design

## Context

動機はproposal.mdのWhyを見る。決定の出典はgrilling.mdにある。

- `uskn-loop` は `bin/uskn-loop` と `loop/` の約1,400行で、仕様PRを受けて実装役と監査役を交互に動かす。段階1（手元から手動で起動）だけが実装されている
- `loop/lib/sensors.sh` は、検証規約、`openspec validate`、tasks.md、未コミットの変更、テストの削除、skipの追加、検証の設定の変更を調べる。比べる先は `<base>...HEAD` で、コミット済みの変更だけを見る
- `sync` は `~/.local/bin/uskn-loop` をsymlinkで張り、`doctor` はその向き先を確かめる。設定断片の `sandbox.excludedCommands` は `uskn-loop *` を持つ
- `sync` は、ハーネスから消えたスキルを指す `~/.claude/skills` のsymlinkを消す（`prune_stale_skill_links`）。消えた実行ファイルのsymlinkを消す仕組みは無い
- 適用記録にあって設定断片に無い要素は、`sync` がliveから消す（`user-settings` の既存の要件）
- 外側のループの製品は、`claude -p` にユーザー層の設定を読ませない。ハーネスのhookとスキルは、その実行では働かない

## Goals / Non-Goals

**Goals:**

- ハーネスのファイルが外側のループの製品の名前とAPIを持たないまま、`uskn-loop` の役割を外へ出す
- 外側のループの無い端末でも、消したテストやskipを見つけられ、実装と別の文脈で完了を判定できる
- 既存の端末は、次の `sync` だけで新しい状態になる

**Non-Goals:**

- verify gateが差分の検査で終了を止めること（grilling.mdの後回し）
- ハーネスの中に外側のループの名前が無いことを、テストで確かめること（grilling.mdの第1ラウンドQ4）
- 外側のループの製品に監査と差分の検査を足すこと。その製品のリポジトリで扱う

## Decisions

### D1 境界はリポジトリの規約に置く

ハーネスは、対話のセッションで働く指針とセンサー、およびプロダクトリポジトリの規約を配る。
issueを起点に起動し、新しい文脈でラウンドを繰り返す外側のループは、ハーネスの外の製品に置く。
両者の接点は、リポジトリの規約（`AGENTS.md`、検証規約、`openspec/`）だけとする。
ハーネスのスキル、hook、テンプレート、インストーラは、外側のループの製品の名前とAPIを書かない。
外側のループの製品も、ハーネスのコマンドを呼ばない。差分の検査が要るなら自分で持つ。
無人の実行でも守らせたい決まりは、ユーザー層ではなくリポジトリの規約に置く。

この境界と、その理由はADR-0016に残す。確かめ方はADRに書くだけにする（Q4）。

- 退けた案：ハーネスが外側のループの入口（ラベルを付けたissueなど）を作る。外側のループの無い端末で役に立たず、ハーネスがその製品を知ることになる（Q2の「渡す形に」）
- 退けた案：ハーネスに `uskn-loop` を残し、外側のループの無い端末でも無人で回せるようにする。外側のループの製品は複数の端末を扱えるので、無人で回したい端末はそちらに足せばよい

### D2 `uskn-loop` と `spec-pr` を撤去する

消すものは次のとおり。

- `bin/uskn-loop`、`loop/`、`bin/tests/uskn-loop.bats`、`bin/tests/fixtures/loop-bin/`
- `skills/spec-pr/`、`bin/tests/spec-pr-skill.bats`

`sync` は `~/.local/bin/uskn-loop` を張らず、既存の `remove_link` で取り除く。
`remove_link` はハーネスの中を指すか、指す先の無いsymlinkだけを消すので、ユーザーが置いた同名のファイルは残る。
`doctor` は、ハーネスの中を指す `~/.local/bin/uskn-loop` が残っていれば `warn` を出し、`sync` を促す。
`~/.claude/skills/spec-pr` のsymlinkは、既存の `prune_stale_skill_links` が消す。

設定断片から `uskn-loop *` を外す。liveからは、適用記録との差として `sync` が消す。

`openspec/glossary.yml` のループの用語（仕様PR、実装役、完了基準、停止条件、ウォッチャー、進捗コメント）は残す。ADR-0007と `docs/loop-engineering-2026-09.md` が使っているためである。
監査役の定義は、ループの外でも通じる形に改める。

ADR-0007の状態の行に、ADR-0016で置き換えたことを書く。

### D3 差分の検査は `uskn-diff-check` の1つにする

本体は `plugins/uskn-harness/hooks/scripts/diff-check.sh` に置く。
短いコマンド `plugins/uskn-harness/bin/uskn-diff-check` から呼ぶ（ADR-0005の形）。

```
uskn-diff-check --base <ref> [--allow-from <file>]... [DIR]
```

- 比べる元は、`<ref>` とHEADのmerge-baseとする。比べる先は作業ツリーとし、`git diff <merge-base>` で調べる。コミット済みの変更と、まだコミットしていない追跡中のファイルの変更が入る
- テストファイルの判定、skipの印、検証の設定のファイルの判定は、`loop/lib/sensors.sh` の3つの関数をそのまま移す。`is_test_path`、`skip_pattern`、`is_verify_setting` である
- 出力は1行に1件で、`test-deleted <path>`、`skip-added <path>: <行>`、`verify-setting <path>` の3種類とする
- `--allow-from` のファイルに文字列として現れるパスは、`test-deleted` と `skip-added` から除く
- 終了コードは、`test-deleted` か `skip-added` があれば1、無ければ0、判定できなければ2とする
- gitだけを使う

`uskn-loop` は `<base>...HEAD` を見ていた。ループの実装役はコミットしてから終わったからである。
`verify` スキルはコミットの直前にも動くので、作業ツリーまでを見る。

- 退けた案：`<ref>...HEAD` だけを見る。コミット前の確認で、消したテストを見逃す
- 退けた案：未追跡のファイルも調べる。sandboxの仮ファイルと、生成物の扱いが要る。skipを付けた新しいテストは、コミットの前に追跡されるので見える

### D4 `verify` スキルが差分の検査を呼ぶ

`verify` スキルの「完了の根拠」の前に、差分の検査の節を足す。
比べる先は `origin/<統合ブランチ>` で、統合ブランチは `<repo-context>` の値から取る。
進行中の変更があれば、その `tasks.md` を `--allow-from` で渡す。
終了コードが1のとき、エージェントはテストを戻すか、ユーザーかtasksが求めたことを報告に書く。

verify gateには入れない。
Stop hookがエージェントに結果を渡す手段は終了を止めることだけで、理由を書いて例外を宣言する仕組みも無い。
求められた削除まで止めると、verify gateの「失敗中は止める」という契約が成り立たなくなる。

### D5 監査は `audit` スキルのforkで行う

`skills/audit/SKILL.md` を足す。frontmatterは次のとおり。

```yaml
context: fork
model: opus
effort: high
background: false
allowed-tools: Bash, Read, Grep, Glob
```

forkは、呼び出した会話の文脈を持たない。実装したエージェントの説明を読まずに判定でき、`uskn-loop` が別の `claude -p` で得ていた独立を、セッションの中で得られる。
モデルとeffortは、`loop-criteria` の監査役の起動条件（Opus、effort high）を引き継ぐ。`skill-fork-policy` の規則に合う。

手順は次のとおり。

1. 対象の変更を決める。引数が無ければ `uskn-archive-check --base origin/<統合ブランチ>` の出力を使う
2. `git status --porcelain` が空でなければ止め、コミットを求める
3. 計算的な確認として、検証規約、`openspec validate <name> --strict`、tasks.mdの未完了の行、`uskn-diff-check` を実行する
4. specsの各シナリオについて、確かめるテストを挙げて実行する
5. 差分を読み、明らかな不具合を探す。書き方の指摘は推奨にとどめる
6. 追跡中のファイルが変わっていれば、報告してHEADの内容に戻す
7. `audit-skill` の判定の形で報告する

監査役への指示は `loop/prompts/auditor.md` を、判定の形は `loop/verdict.schema.json` を移す。置き場は `skills/audit/references/` とする。

- 退けた案：インラインのスキルにする。実装の会話の文脈が判定に入る
- 退けた案：Claude Codeの組み込みのレビューに任せる。specsとの照合をしない
- 退けた案：道具を読み取りに限ったプラグインのagentにする。skills-dirプラグインがagentsを読み込むかを確かめていない（grilling.mdの後回し）

## Risks / Trade-offs

- `audit` のBashはファイルを書ける。対策として、未コミットの変更がある間は始めない。終わりに追跡中のファイルの変化を報告して戻す
- テストファイルの判定はパスの文字列による推定で、latestのような語を含む名前も当たる。対策として、判定は報告にとどめ、エージェントが理由を書いて先へ進める。判定は `uskn-loop` と同じものを使い、ふるまいを変えない
- `audit` はOpusとeffort highで動き、費用がかかる。対策として、自動では呼ばない。ユーザーかエージェントが、archiveかPRの前に呼ぶ
- 外側のループの製品の実行では、ハーネスの検査が働かない。対策として、D1のとおり、無人の実行で守らせたい決まりはリポジトリの規約に置く

## Migration Plan

1. このchangeをマージする
2. 各端末で `uskn-harness sync` を実行する。`~/.local/bin/uskn-loop`、`~/.claude/skills/spec-pr`、liveの `uskn-loop *` が消える
3. `uskn-harness doctor` が `warn` を出さないことを確かめる

戻すときは、このchangeのコミットをrevertして `sync` を実行する。
