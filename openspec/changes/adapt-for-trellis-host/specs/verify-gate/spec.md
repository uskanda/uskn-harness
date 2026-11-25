# Spec Delta

## ADDED Requirements

### Requirement: 閉じた環境での検証の実行
閉じた環境の間、hookは検証規約を、confined-hook-sandboxの規則の中で実行しなければならない（MUST）。
作業ツリーの指紋を求めるgitも、同じ規則の中で実行する。
PATHには、環境の印の `tools` が指す共有の置き場の `bin/` だけを足し、ホームの下は足さない。
検証の失敗と時間の上限の扱いは、管理者の環境と同じ。

#### Scenario: 閉じた環境の検証
- **WHEN** 閉じた環境のmacOSで、作業ツリーを変えたセッションのStopが発火し、`make verify` が成功する
- **THEN** `make verify` は規則の中で動き、出力は空で、`verified` に指紋が書かれる

#### Scenario: 規則に拒否された検証
- **WHEN** 閉じた環境のmacOSで、検証規約が外のホストへ接続して失敗する
- **THEN** `decision` が `block` で、`reason` に失敗の出力が含まれる

### Requirement: 規則を使えない閉じた環境での検証
閉じた環境の間、`sandbox-exec` を使えないとき、hookは検証規約を実行してはならない（MUST NOT）。
このときはblockせず、検証しなかったことと、その理由を `systemMessage` で返す。

#### Scenario: Linux の閉じた環境
- **WHEN** 閉じた環境のLinuxで、作業ツリーを変えたセッションのStopが発火する
- **THEN** JSONに `decision` は無く、`systemMessage` に検証しなかったことが含まれる
