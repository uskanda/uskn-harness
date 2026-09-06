# uskn-schema Specification

## Purpose
grillingの記録を最初の成果物として要求するOpenSpecワークフロー。リポジトリ側はschemaを選ぶだけで、実体はハーネスがユーザー層に置く。

## Requirements

### Requirement: grilling が proposal の前提
schema `uskn` は `grilling`（`grilling.md`）を最初の成果物とし、`proposal` はそれを要求しなければならない（MUST）。`grilling.md` が無いchangeでは `openspec status` がproposalをblockedと報告する。

#### Scenario: 新しい change
- **WHEN** `openspec new change x` の直後に `openspec status --change x` を実行する
- **THEN** grillingが未完了、proposalが `blocked by: grilling` と表示される

#### Scenario: 記録後
- **WHEN** `grilling.md` を置いて再度statusを見る
- **THEN** proposalがreadyになる

### Requirement: ユーザー層での提供
schemaはハーネスの `schemas/uskn/` を正本とし、`sync` 後に `openspec schema which uskn` がuserレベルから解決されなければならない（MUST）。リポジトリ側に置くのは `openspec/config.yaml` の `schema: uskn` だけ。

#### Scenario: 解決元
- **WHEN** `sync` 済みの端末で `openspec schema which uskn` を実行する
- **THEN** `Source: user` と `~/.local/share/openspec/schemas/uskn` が表示される

### Requirement: 記録のテンプレート
`grilling.md` のテンプレートは「決定 / 選択 / 出典」の表と、「後回しにしたもの」の節を持たなければならない（MUST）。
続けて「frontierは空。共有理解は <日付> に確認済み」の状態行を持つ。
`openspec schema validate uskn` は成功しなければならない（MUST）。

#### Scenario: 検証
- **WHEN** `openspec schema validate uskn` を実行する
- **THEN** validと報告される

### Requirement: 要求文の型
`uskn` schemaのspecs生成指示は、要求文をEARS記法の型で書くよう求めなければならない（MUST）。
型は6つ。常時、状態駆動、イベント駆動、選択機能、不要動作、複合。
日本語では節の順序を固定する。「〈前提〉の間、〈契機〉のとき、〈対象〉は〈振る舞い〉しなければならない（MUST）」。
節は省略できるが、順序は変えない。既存の `#### Scenario:` のWHEN / THEN形式は変えない。

#### Scenario: イベント駆動の要求
- **WHEN** 契機のある要求を書く
- **THEN**「〜のとき、〜は〜しなければならない（MUST）」の順で書かれる

#### Scenario: 常時の要求
- **WHEN** 条件の無い要求を書く
- **THEN** 前提と契機の節を省き、対象と振る舞いだけを書く
