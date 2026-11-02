# Proposal

## Why

ADR-0011の後も、sandboxの中で失敗し、sandboxの外で再実行するコマンドが多い。2026-10-26から2026-10-31までに、`dangerouslyDisableSandbox: true` の呼び出しは846回あった。
原因は、Unixソケットの禁止、この端末のIPに解決されるホスト、外の道具が途中にある複合コマンド、そして一度失敗した後にsandboxの中で動くコマンドまで外で動かす癖である。
また、sandboxが保護パスに作る0バイトのファイルを、verify gateの指紋と `verify-fast` の範囲が変更と数え、エージェントも `git status` を読んで変更と誤解する。

## What Changes

- 設定断片で `sandbox.network.allowAllUnixSockets` を `true` にする。D-Busを使う `systemctl --user`、`journalctl`、`secret-tool` と、ソケットで待つテストが、sandboxの中で動く
- 新しい下位コマンド `uskn-harness sandbox-allow-host` が、端末別設定の `sandbox.network.allowedDomains` にホストを足し、外し、一覧を出す。新しいスキル `sandbox-allow-host` が、それを呼ぶ
- syncは、`sandbox.network.allowedDomains` も集合として扱う
- bash-guardは、sandboxの中で失敗すると分かっている外の道具が複合コマンドの途中にあるとき、拒否して単独での実行を促す。対象は、`.git/config` に書くかネットワークを使うgitの下位コマンドと、`glab`、`docker`、`ssh`、`scp`、`claude` である。ほかの外の道具は、今までどおり知らせるだけにする
- bash-guardは、`dangerouslyDisableSandbox: true` の呼び出しのたびに、外すのはsandboxの制限による失敗を見たときだけだと知らせる
- 作業ツリーの指紋と `verify-fast` の範囲は、sandboxの0バイトのファイルを数えない
- ユーザー層の指示に、`git status` に出るsandboxの0バイトのファイルの説明を1行足す
- ADR-0012を書き、ADR-0011の決定6を差し替え、ADR-0009の決定5を補う

## Capabilities

### New Capabilities

- `sandbox-allow-host-skill`: この端末のIPに解決されるホストなどを、ユーザーがsandboxの接続先として足すスキル

### Modified Capabilities

- `user-settings`: Unixソケットの許可、集合として扱う配列への `sandbox.network.allowedDomains` の追加、`allowedDomains` に足すホスト
- `harness-sync`: `sandbox-allow-host` の下位コマンド
- `bash-guard`: 途中に出てくる外の道具の拒否と、sandboxを外した呼び出しの知らせ
- `session-baseline`: 指紋がsandboxの0バイトのファイルを数えないこと
- `verify-fast`: 変更の範囲がsandboxの0バイトのファイルを含まないこと
- `user-layer-instructions`: sandboxの0バイトのファイルの説明

## Impact

- 設定断片：`templates/user/settings.json`、`bin/tests/user-settings.bats`
- sync：`bin/uskn-harness`、`bin/tests/uskn-harness.bats`
- hook：`plugins/uskn-harness/hooks/scripts/bash-guard.sh`、`lib/common.sh` と、それぞれのbats
- `Makefile` の `CHANGED` と `bin/tests/makefile.bats`
- `skills/sandbox-allow-host/SKILL.md` と、そのbats
- `templates/user/CLAUDE.md`
- ADR：`<docs/adr/0012-sandbox-rules-revisit.md>`、`docs/adr/0011-narrow-sandbox-scope.md`
- 文書：`README.md`、`docs/setup-new-machine.md`
- 引き受けるコスト：sandboxの中のコードが、`docker.sock` やD-Busを通じてsandboxを抜けられるようになる
