# Tasks

## 1. 実機の確認

- [x] 1.1 `bubblewrap` と `socat` を、ユーザーがこの端末に入れる。`bwrap --version` と `socat -V` が成功することを確かめる。Ubuntu 24.04以降で `bwrap` がAppArmorに拒否されるときは、要る設定を控える
- [x] 1.2 design.mdのD1の設定を書いたJSONを、`claude -p --settings <file>` に渡して、sandboxの中のBashの振る舞いを確かめる。`touch ~/.local/state/uskn-harness/x` が拒否されること、`npx -y cowsay hi` と `mise ls` が通ることを確かめる。`allowWrite` の3つのキャッシュのうち、外すと失敗するものだけを残す
- [x] 1.3 `excludedCommands` のパターンを、1.2と同じ方法で決める。次の3つが、sandboxの外で動くことを確かめる。`/allow-repo` と同じ絶対パスで起動する `allow-repo.sh --list`、`uskn-harness sync --dry-run`、`chezmoi --version` である
- [x] 1.4 `WebFetch(domain:*)` だけを許可した状態で、1.2と同じ方法でネットワークを確かめる。`curl -sI https://example.com` と `gh api user` を実行する。`git ls-remote` を、github.comと `gl.uskan.dev` へ実行する。どれかが拒否されたら、D2のホストの一覧を `sandbox.network.allowedDomains` に足して再び確かめる
- [x] 1.5 `make verify` と `git commit` が、ルートの中で通ることを、1.2と同じ方法で確かめる。1.1から1.5の結果を、design.mdのMigration Planの後ろに追記する。textlintとterms-checkが通ることを確かめる

## 2. 設定断片（user-settings）

- [x] 2.1 `bin/tests/user-settings.bats` にテストを先に足す。設定断片の `sandbox.enabled`、`failIfUnavailable`、`allowUnsandboxedCommands` の値を確かめる。`excludedCommands` が3つのコマンドに当たること、`allowWrite` に状態ディレクトリが無いことも確かめる。`permissions.allow` に `WebFetch(domain:*)` があることも確かめる。走らせて失敗することを確かめる
- [x] 2.2 `templates/user/settings.json` に、1.2から1.4で決めた値を書く。2.1が通ることを確かめる

## 3. bash-guard

- [x] 3.1 `plugins/uskn-harness/hooks/tests/bash-guard.bats` の、ルートの外への書き込みが警告されるテストを、何も出力しないテストに書き換える。対象は、外へのコピー、移動、リダイレクト、`cd` の後の書き込み、`cwd` が別のリポジトリに移った後の書き込みである。状態ファイルへのリダイレクトが拒否されるテストは残す。走らせて失敗することを確かめる
- [x] 3.2 `plugins/uskn-harness/hooks/scripts/bash-guard.sh` から、警告の判定と出力を削除し、冒頭の説明を直す。design.mdのD3のとおりにする。3.1と残りのbatsが通り、`make verify-shell` が通ることを確かめる
- [x] 3.3 `openspec/specs/bash-guard/spec.md` のPurposeを、拒否だけを受け持つhookの説明に書き直す。ルートの外への書き込みはsandboxが制限すると書く。textlintが通ることを確かめる

## 4. doctor（harness-doctor）

- [x] 4.1 `bin/tests/uskn-harness.bats` にテストを先に足す。`USKN_HARNESS_OS` とPATHの差し替えで、Linuxで `bwrap` が無いときの `warn`、両方あるときの `ok`、macOSとsandboxの無効な端末で行が出ないことを確かめる。走らせて失敗することを確かめる
- [x] 4.2 `bin/uskn-harness` のdoctorに、design.mdのD4のとおりにsandboxの依存の検査を足す。4.1が通ることを確かめる。冒頭の説明の検査項目にも足す

## 5. allow-repo スキル（allow-repo-skill）

- [x] 5.1 `skills/allow-repo/SKILL.md` が `/add-dir` の案内を持つことのテストを先に足す。足す先は、Makefileがこのスキルに対応づける `bin/tests/allow-repo-skill.bats` である。走らせて失敗することを確かめる
- [x] 5.2 `skills/allow-repo/SKILL.md` の手順3に、design.mdのD5のとおりに `/add-dir <resolved path>` の案内を足す。冒頭の説明に、sandboxの中のBashが追加したディレクトリにだけ書けることを書く。5.1が通ることを確かめる

## 6. 文書

- [x] 6.1 `docs/adr/0009-bash-sandbox.md` を、design.mdのD6のとおりに書く。ADR-0001の §7に、warnパターンをADR-0009で置き換えた旨の注記を足す。textlintとterms-checkが通ることを確かめる
- [x] 6.2 `docs/setup-new-machine.md` に、Linuxの端末での `bubblewrap` と `socat` の導入と、1.1で控えたAppArmorの設定を書く。端末別設定で `excludedCommands` を足すときに3つのパターンも書き写すことと、sandboxを切る方法も書く。`README.md` のhookの説明のうち、bash-guardの警告の記述を直す。textlintとterms-checkが通ることを確かめる

## 7. 統合

- [x] 7.1 `openspec validate adopt-bash-sandbox --strict` と `make verify VERIFY_STRICT=1` が通ることを確かめる
- [x] 7.2 `uskn-harness sync` を作業ツリーから実行する。liveの `sandbox.enabled` が `true` になり、doctorのsandboxの依存の行が `ok` になることを確かめる。新しいセッションで `/allow-repo <scratchpadの外のディレクトリ>` と `/add-dir` を実行し、Bashからそこへ書けることを確かめる（archive-pushの手順で完了とみなした）
- [x] 7.3 PRをmainへマージする（archive-pushの手順で完了とみなした）
