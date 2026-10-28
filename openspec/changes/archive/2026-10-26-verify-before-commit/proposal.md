# Proposal

## Why

ハーネスのスキル `verify` は、ユーザー層にあるため、Claude Codeの組み込みの `/verify` を置き換えている。
Claude Code（2.1.286以降）は、ユーザー層の `verify` を、commitの直前に実行させる。
そのため今は、commitのたびにフルの `make verify` が走り、turnの終わりのverify gateと合わせて検証が2回走る（issue #9）。

## What Changes

- `verify` スキルは、commitの直前に呼ばれたとき、Makefileに `verify-fast` があればそれを走らせる。無ければ検証規約を走らせる
- commitの直前の実行の結果は、完了の根拠にしない。完了の根拠の要件は変えない
- READMEのverifyの説明に、Claude Codeがcommitの直前にこのスキルを呼ぶことを書く

対象外は次のとおり。スキルの名前の変更、組み込みの `/verify` を使えるように戻すこと、verify gateの振る舞い。

## Capabilities

### New Capabilities

- なし

### Modified Capabilities

- `verify-skill`: commitの直前に呼ばれたときの振る舞いを足す

## Impact

- `skills/verify/SKILL.md` と、そのbats `bin/tests/verify-skill.bats`
- `README.md`
