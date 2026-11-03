# Tasks

## 1. 前提の確認

- [x] 1.1 design.mdのD2の方法で、空でない `allowedDomains` が全ホストの許可を狭めないことを確かめる。入れ子の `claude -p --settings <file>` を、`allowedDomains` に1つのホストだけを入れた設定で起動する。そのセッションに、sandboxの中から `curl -sI https://github.com` を実行させる。結果は、この項目の下に1行で書く。拒否されたら作業を止め、ユーザーに戻す
  - 結果（2026-11-01）：`allowedDomains` を1つのホストだけにしても、sandboxの中の `curl` は `https://github.com` に200を返した

## 2. 設定断片と sync（user-settings）

- [x] 2.1 `bin/tests/user-settings.bats` にテストを先に足す。設定断片の `sandbox.network.allowAllUnixSockets` が `true` であることと、`sandbox.network.allowedDomains` を持たないことを確かめる。端末別設定の `allowedDomains` が、sync後もliveの要素と並んで残ることも確かめる。走らせて失敗することを確かめる
- [x] 2.2 `templates/user/settings.json` に、design.mdのD1のとおり `network` の節を足す。`bin/uskn-harness` の `is_set` に、design.mdのD2のパスを足す。2.1が通ることを確かめる

## 3. sandbox-allow-host の下位コマンド（harness-sync）

- [x] 3.1 `bin/tests/uskn-harness.bats` に、`sandbox-allow-host` のテストを先に足す。足す、既にあるものを足さない、空と `*` とURLの形を拒否する、`--list` の表示、`--remove`、既定値の `--remove` の拒否を確かめる。走らせて失敗することを確かめる
- [x] 3.2 `bin/uskn-harness` に、design.mdのD2のとおり `sandbox-allow-host` を足す。`sandbox-exclude` と共通の部分を、配列のパスを受け取る関数にまとめ、冒頭の説明に書く。3.1と、既存の `sandbox-exclude` のテストが通ることを確かめる

## 4. sandbox-allow-host スキル（sandbox-allow-host-skill）

- [x] 4.1 `bin/tests/sandbox-allow-host-skill.bats` を先に書く。`disable-model-invocation: true` と `argument-hint` を持つことと、`uskn-harness sandbox-allow-host` を名指しすることを確かめる。URLからホストを取り出す手順と、`*` を足さない手順があることも確かめる。走らせて失敗することを確かめる
- [x] 4.2 `skills/sandbox-allow-host/SKILL.md` を、design.mdのD2のとおりに英語で書く。worked exampleを1つ入れる。4.1と `bin/tests/skill-*.bats` が通ることを確かめる

## 5. bash-guard（bash-guard）

- [x] 5.1 `plugins/uskn-harness/hooks/tests/bash-guard.bats` に、仕様のシナリオのテストを先に足し、既存の知らせのテストを仕様の変更に合わせる。拒否は、`cd` の後の `git push`、パイプの前の `git push`、代入の後の `glab`、`-C` の付いた `push`、一覧から外した `docker` を確かめる。`--no-pager` の付いた `push` では、何も出さないことを確かめる。知らせは、`dangerouslyDisableSandbox` が `true`、無い、`false` の3つを確かめる。走らせて失敗することを確かめる
- [x] 5.2 `bash-guard.sh` に、design.mdのD3とD4のとおり、拒否と知らせを足し、冒頭の説明を直す。5.1と残りのbatsが通り、`make verify-shell` が通ることを確かめる

## 6. 仮ファイル（session-baseline、verify-fast）

- [x] 6.1 `plugins/uskn-harness/hooks/tests/common.bats` と `session-baseline.bats` に、仕様のシナリオのテストを先に足す。直下の0バイトの `.bashrc`、`.claude/` の直下の0バイトの `agents` では指紋が変わらないことを確かめる。中身のある `.envrc` と、0バイトの `docs/.keep` で指紋が変わることも確かめる。`bin/tests/makefile.bats` には、`make verify-fast-plan` の対象に0バイトの `.mcp.json` が含まれないテストを足す。走らせて失敗することを確かめる
- [x] 6.2 `lib/common.sh` に、design.mdのD5のとおり仮ファイルを除く関数を足し、`tree_fingerprint` と `Makefile` の `CHANGED` から使う。6.1と、`verify-gate.bats` の既存のテストが通ることを確かめる

## 7. ユーザー層の指示（user-layer-instructions）

- [x] 7.1 `bin/tests/uskn-harness.bats` に、`templates/user/CLAUDE.md` が仮ファイルの行（`.claude/agents` を含む）を持つテストを先に足す。走らせて失敗することを確かめる
- [x] 7.2 `templates/user/CLAUDE.md` に、design.mdのD6のとおり1行足す。7.1と、行数と大きさのテストが通ることを確かめる

## 8. 文書

- [x] 8.1 `<docs/adr/0012-sandbox-rules-revisit.md>` を、design.mdのD7のとおりに書く。ADR-0011の決定6とADR-0009の決定5に注記を足す。textlintとterms-checkが通ることを確かめる
- [x] 8.2 `docs/setup-new-machine.md` のsandboxの節を書き直す。対象は、Unixソケット、`/sandbox-allow-host`、途中に出てくる道具の拒否、仮ファイルである。`git add -A` の注意は、仮ファイルの説明に置き換える。`README.md` の機能の表に、`sandbox-allow-host` スキルを足す。textlintとterms-checkが通ることを確かめる

## 9. 統合

- [x] 9.1 `openspec validate sandbox-rules-revisit --strict` が通ることを確かめる。sandboxの外で `make verify VERIFY_STRICT=1` が通ることも確かめる
- [x] 9.2 `uskn-harness sync` の後、新しいセッションで次の3つを確かめる。sandboxの中から `systemctl --user is-system-running` が `Failed to connect to bus` で失敗しないこと。`/sandbox-allow-host gl.uskan.dev` の後に、sandboxの中から `curl -sI https://gl.uskan.dev` が拒否されないこと。sandboxの中のコマンドの実行中に、Stopでverify gateが走らないこと（archive-pushで完了とみなした）
