## 1. CLI の骨格とテスト基盤

- [x] 1.1 `bin/uskn-harness` に `main` / `cmd_sync` / `cmd_doctor` / `cmd_init` の骨格と `do_link` `do_copy` `do_run`（`--dry-run` 対応）を作り、`bin/tests/uskn-harness.bats` で `--dry-run` が書き込みをしないことと `--help` の出力を検証する。`shellcheck` が警告ゼロ
- [x] 1.2 `Makefile` の `verify-shell` に `bin/tests` を含め、`make verify` が通ることを確認する

## 2. sync（TDD）

- [x] 2.1 bats に「参照点の決定（`USKN_HARNESS_DIR`、`~/repos/uskn-harness`、無し）」「自作スキルの symlink 作成」「実ディレクトリとの衝突スキップ」「ハーネス外を指す symlink の衝突」「名前重複でエラー」「プラグイン symlink」「`~/.local/bin/uskn-harness` symlink」「2 回目の実行で変更なし」「ユーザー層 CLAUDE.md のコピーと印の無いファイルの保護」を RED で書く
- [x] 2.2 上記を実装して GREEN にする
- [x] 2.3 ネットワークを伴う手順（mise 導入、`mise use -g`、openspec の導入、`npx skills add`、openspec ユーザー層スキルの生成）をスタブ可能な `do_run` 経由で実装し、`USKN_HARNESS_STUB_NET=1` のテストで呼び出し順と引数を検証する
- [x] 2.4 `sync --remove` を実装し、ハーネス由来の symlink だけを消して実ディレクトリは残すことをテストで確認する

## 3. doctor（TDD）

- [x] 3.1 bats に「健全な環境で 0」「向き先違い symlink で 1」「chezmoi 衝突のみで warn かつ 0」「openspec version 不一致で warn」「書き込みをしない」を RED で書く
- [x] 3.2 実装して GREEN にする

## 4. テンプレート

- [x] 4.1 `templates/user/CLAUDE.md` を管理印付き 60 行以内で書き、`wc -l` と印の存在をテストで確認する
- [x] 4.2 `templates/chezmoi/run_once_install-uskn-harness.sh.tmpl` を 20 行以内で書き、`bash -n`（テンプレート部分を除いた本体）が通ることを確認する
- [x] 4.3 `deps.json` に `runtimes.jq` と `clis.openspec.install` の整合を反映し、`python3 -c 'import json; json.load(open("deps.json"))'` が通ることを確認する

## 5. このマシンへの導入

- [x] 5.1 `uskn-harness sync --dry-run` の出力を確認してから `sync` を実行し、`doctor` の出力で旧スキルとの `conflict` が warn、他が ok であることを確認する
- [x] 5.2 `claude plugin list` に `uskn-harness@skills-dir` が loaded で現れ、`claude plugin details` に SessionStart が 1 件あることを確認する
- [ ] 5.3 このリポジトリの `.claude/skills/openspec-*` と `.claude/commands/opsx` を削除し、ユーザー層のコピーで `openspec status` 系スキルが見えることを確認する（**保留**: ユーザー層の `openspec-*` 4 つは dotfiles PR #10 のマージまで chezmoi の 1.3.1 世代コピーが残るため、マージ後に実施）

## 6. dotfiles PR #10

- [x] 6.1 scratchpad の別クローンで `harness/mise-shims` に、zshrc の nvm / pyenv ブロック削除、run_once の追加、`.chezmoiignore` の追記、`dot_claude/skills` から移管済み 13 スキルと `openspec-*` の削除、`settings.json.tmpl` の hosting hook 削除、`executable_claude-hosting-hook` の削除を、目的ごとに分けたコミットで積む。`zsh -n` と `chezmoi execute-template`（run_once）で構文を確認する
- [x] 6.2 PR #10 の本文を「マージ後の手順（`chezmoi apply` → `uskn-harness sync` → `uskn-harness doctor`）」を含めて更新し、draft のまま push する

## 7. 記録

- [x] 7.1 `README.md` に導入手順（新しいマシン、開発機）を書き、`openspec validate harness-installer --strict` と `make verify` が通ることを確認してコミットする
