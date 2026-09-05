# uskn-schema Specification

## Purpose
grilling の記録を最初のアーティファクトとして要求する OpenSpec ワークフロー。リポジトリ側は schema を選ぶだけで、実体はハーネスがユーザー層に置く。

## Requirements

### Requirement: grilling が proposal の前提
schema `uskn` は `grilling`（`grilling.md`）を最初のアーティファクトとし、`proposal` はそれを要求しなければならない（MUST）。`grilling.md` が無い change では `openspec status` が proposal を blocked と報告する。

#### Scenario: 新しい change
- **WHEN** `openspec new change x` の直後に `openspec status --change x` を実行する
- **THEN** grilling が未完了、proposal が `blocked by: grilling` と表示される

#### Scenario: 記録後
- **WHEN** `grilling.md` を置いて再度 status を見る
- **THEN** proposal が ready になる

### Requirement: ユーザー層での提供
schema はハーネスの `schemas/uskn/` を正本とし、`sync` 後に `openspec schema which uskn` が user レベルから解決されなければならない（MUST）。リポジトリ側に置くのは `openspec/config.yaml` の `schema: uskn` だけ。

#### Scenario: 解決元
- **WHEN** `sync` 済みの端末で `openspec schema which uskn` を実行する
- **THEN** `Source: user` と `~/.local/share/openspec/schemas/uskn` が表示される

### Requirement: 記録のテンプレート
`grilling.md` のテンプレートは「決定 / 選択 / 出典」の表と、「後回しにしたもの」の節を持たなければならない（MUST）。
続けて「frontier は空。共有理解は <日付> に確認済み」の状態行を持つ。
`openspec schema validate uskn` は成功しなければならない（MUST）。

#### Scenario: 検証
- **WHEN** `openspec schema validate uskn` を実行する
- **THEN** valid と報告される
