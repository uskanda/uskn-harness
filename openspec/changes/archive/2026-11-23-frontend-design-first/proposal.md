# Proposal

## Why

いまの `ui-guidelines` は、`frontend-design` を「DESIGN.mdがまだ無いWebの新規UIで、ユーザーが方向性を探りたいとき」だけのフォールバックにしている。
そのため新しい画面の多くは、見た目の方向性を決めないまま既定の見た目で書き始められる。
新規UIでは原則として最初に方向性を決めるよう、指針を変える。

## What Changes

- `ui-guidelines` スキルに、新規UIの最初の手順として `frontend-design` で方向性を決めることを書く。対象はWebとExpo（React Native）の両方
- `DESIGN.md` があるリポジトリでも `frontend-design` を通す。方向性は `DESIGN.md` のトークンとproseの範囲で決め、足りない値は実装の前に `DESIGN.md` へ足す
- `DESIGN.md` が無いリポジトリでは、テンプレートから作る手順の中で `frontend-design` が方向性を出し、その選択をトークンとproseに書いてからユーザーに確認する
- 既存の画面の小さな修正は対象外とし、Impeccableのコマンドで直す
- ユーザー層の `CLAUDE.md` のUIの行に、新規UIは `frontend-design` から始めることを足す
- `deps.json` の `frontend-design` の `role` を、フォールバックから新規UIの最初の手順に改める
- 本文を確かめるbatsテスト（センサー）を足す
- Impeccableは導入済み（4.3.1、`uskn-harness sync` が入れる）のため、版と導入方法は変えない

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

- `ui-guidelines-skill`: `frontend-design` をフォールバックから新規UIの最初の手順に改める（WebとExpoの両方、DESIGN.mdの有無を問わない）
- `user-layer-instructions`: UI節に、新規UIは `frontend-design` で方向性を決めてから着手することを足す

## Impact

- `skills/ui-guidelines/SKILL.md`
- `templates/user/CLAUDE.md`（`uskn-harness sync` で各端末の `~/.claude/CLAUDE.md` に届く）
- `deps.json` の `frontend-design` の `role`
- `bin/tests/` に `ui-guidelines` の本文のテストを足す。ユーザー層の `CLAUDE.md` の行もテストで確かめる
- 外部スキルの版、`sync`、`doctor` は変わらない
