# Tasks

## 1. センサー（先に失敗させる）

- [x] 1.1 `bin/tests/ui-guidelines-skill.bats` を足す。`ui-guidelines` の手順が、`frontend-design` を新規UIの手順として名指しし、WebとExpoの両方を対象にすることを確かめる。`DESIGN.md` を実装の前に直すと書き、手順4のフォールバックの条件が残っていないことも確かめる
- [x] 1.2 `templates/user/CLAUDE.md` のUIの行が `frontend-design` を名指しすることも、このテストで確かめる
- [x] 1.3 `bats bin/tests/ui-guidelines-skill.bats` が失敗することを確かめる

## 2. 指針

- [x] 2.1 `skills/ui-guidelines/SKILL.md` の「Working on a surface」に、新規UIの手順を手順1の直後に置く（D1、D2）。手順4のフォールバックは消し、既存の画面の小さな修正は対象外と書く。例を1つ本文に足す
- [x] 2.2 `templates/user/CLAUDE.md` のUIの行に、新規UIは `frontend-design` で方向性を決めてから着手することを足す（D3）
- [x] 2.3 `deps.json` の `frontend-design` の `role` を新規UIの最初の手順に改める
- [x] 2.4 `bats bin/tests/ui-guidelines-skill.bats` が通ることを確かめる

## 3. 確認

- [x] 3.1 `make verify` が通る
