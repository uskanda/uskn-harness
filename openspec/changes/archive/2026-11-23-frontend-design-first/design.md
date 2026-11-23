# Design

## Context

`ui-guidelines` の「Working on a surface」は4つの手順を持つ。
`frontend-design` は手順4にあり、`DESIGN.md` の無いWebの新規UIに限って使う（proposal.mdのWhyを参照）。
`frontend-design` は `deps.json` で参照とピンを持つ外部スキルで、改変しない。
`DESIGN.md` を正本にする決まり（ADR-0001 §11）は変えない。

## Goals / Non-Goals

**Goals:**

- 新規UIの最初の手順を、`ui-guidelines` とユーザー層の `CLAUDE.md` の両方から読めるようにする
- `frontend-design` の出す方向性と、`DESIGN.md` の正本が食い違わない順序を決める

**Non-Goals:**

- `frontend-design` とImpeccableの版を上げること
- 既存の画面の小さな修正の手順を変えること

## Decisions

### D1. 新規UIの手順を「Working on a surface」の先頭に置く

`frontend-design` の手順を、手順1（DESIGN.mdとPRODUCT.mdを読む）の直後に置き、新規UIのときだけ通す。
手順4の条件付きのフォールバックは消す。
別の節を立てる案もあったが、手順の順番が実際の作業の順番と合う位置に置くほうが読み違えにくい。

### D2. DESIGN.md を先に直してから実装する

`frontend-design` の選択は、実装の前に `DESIGN.md` のトークンとproseへ書き、`designmd lint` を通す。
`frontend-design` の選択をそのままコードに書く案は、トークンに無い値を生み、「UIの値はトークンから取る」という手順1に反するため採らない。
`DESIGN.md` があるときは、方向性をその範囲で決める。範囲を超える変更（色の系統を変えるなど）はユーザーに確かめる。

### D3. ユーザー層の CLAUDE.md の UI の行に足す

`ui-guidelines` を読まずに書き始めることもあるため、常に読まれるユーザー層の `CLAUDE.md` の1行にも足す。
行数を増やさないよう、既存のUIの行に句を足す。

### D4. センサーは本文のbatsテスト

手順を守ったかを機械的に確かめる方法は無い。
ほかのスキルと同じく、本文に手順があることをbatsテストで確かめる（`verify-skill.bats` と同じ形）。
テストは、`ui-guidelines` の手順に `frontend-design` があり、DESIGN.mdを先に直すことを書いていて、フォールバックの条件が残っていないことを確かめる。
ユーザー層の `CLAUDE.md` のUIの行が `frontend-design` を名指しすることも確かめる。

## Risks / Trade-offs

- 新規UIかどうかの判断が揺れる。対策：例として新しい画面と新しいアプリの最初の画面を挙げ、既存の画面の小さな修正は対象外と書く
- `frontend-design` が `DESIGN.md` と違う方向を勧める。対策：D2のとおり `DESIGN.md` の範囲で決め、超えるときはユーザーに確かめる

## Migration Plan

`uskn-harness sync` で `ui-guidelines` とユーザー層の `CLAUDE.md` が各端末に届く。戻すときは変更を戻して再び `sync` する。

## Open Questions

なし。
