# Spec Delta

## Purpose

閉じた環境で、Claude Codeのsandboxの外で動くhookが、リポジトリのコードとホームの下の道具を動かす範囲を限る規則。
エージェントが書けるコードを、秘密の置き場を読めず、外へ直接つなげない規則の中だけで動かす。

## ADDED Requirements

### Requirement: 閉じた環境の hook の PATH
閉じた環境の間、hookはホームの下のディレクトリをPATHに足してはならない（MUST NOT）。
足すのは、環境の印の `tools` が指す共有の置き場の `bin/` だけである。
管理者の環境では、今までどおり `~/.local/share/mise/shims` と `~/.local/bin` を先頭に足す。

#### Scenario: ホームの textlint
- **WHEN** 閉じた環境で、`~/.local/bin/textlint` と `<tools>/bin/textlint` の両方がある
- **THEN** textlint-checkが実行するのは `<tools>/bin/textlint`

### Requirement: リポジトリのコードを規則の中で動かす
閉じた環境の間、hookは、リポジトリの中で起動する外部のコマンドを、`sandbox-exec` の規則の中で動かさなければならない（MUST）。
対象は3種類で、verify gateの検証規約、textlint、hookがリポジトリに対して実行するgitである。
gitを含めるのは、エージェントが `.git/config` に、gitの実行するコマンドを書けるため。
規則は `plugins/uskn-harness/hooks/scripts/lib/confined.sb` に置く。

#### Scenario: 検証規約
- **WHEN** 閉じた環境のmacOSで、verify gateが `make verify` を実行する
- **THEN** `make verify` は `sandbox-exec` の規則の中で動く

#### Scenario: 作業ツリーの指紋
- **WHEN** 閉じた環境のmacOSで、`.git/config` の `core.fsmonitor` にコマンドを書いたリポジトリで、verify gateが指紋を計算する
- **THEN** そのコマンドは規則の中で動き、秘密の置き場を読めない

### Requirement: 規則が禁じるもの
規則は、環境の印の `secrets` が指すディレクトリの下の読み書きを禁じなければならない（MUST）。
規則は、外への接続を禁じなければならない（MUST）。ただし `localhost` への接続は許す。
これ以外の操作は、OSのユーザーの権限に任せる。
印に `secrets` が無いときは、接続の禁止だけを使う。

#### Scenario: 秘密を読む検証
- **WHEN** 閉じた環境のmacOSで、検証規約が `secrets` の下のファイルを `cat` する
- **THEN** 読み取りは拒否され、検証は失敗としてblockされる

#### Scenario: 外へ送る検証
- **WHEN** 閉じた環境のmacOSで、検証規約が `curl https://example.com` を実行する
- **THEN** 接続は拒否される

#### Scenario: 手元のテスト用のサーバー
- **WHEN** 閉じた環境のmacOSで、検証規約が `localhost` で待つテスト用のサーバーへ接続する
- **THEN** 接続は通る

### Requirement: 規則を使えない閉じた環境
閉じた環境の間、`sandbox-exec` を使えないとき、hookはリポジトリのコードを動かしてはならない（MUST NOT）。
使えないとは、OSがmacOSでないとき、またはPATHに `sandbox-exec` が無いときを言う。
このとき、verify gateは検証しなかったことを `systemMessage` で知らせ、blockしない。
textlint-checkは、検査しなかったことを `additionalContext` で知らせる。
Linuxの閉じた環境は、この変更の対象外である。

#### Scenario: Linux の閉じた環境
- **WHEN** 閉じた環境のLinuxで、作業ツリーを変えたセッションのStopが発火する
- **THEN** 検証規約は実行されず、`systemMessage` に検証しなかったことが含まれる
