## 1. OpenSpecのユーザー層をcommandsだけにする

- [ ] 1.1 `bin/tests/uskn-harness.bats` に生成のテストを書く。偽の `mise` と `openspec` を使い、次の3点が失敗することを確かめる。
  生成は一時的な `XDG_CONFIG_HOME`（profile `core`、delivery `commands`）で走る。`commands/opsx` だけが印付きで置かれる。ユーザーの `~/.config/openspec/config.json` は変わらない
- [ ] 1.2 `openspec-*` の削除のテストを書く。印のあるものを消し、印の無いものは残し、`--dry-run` では消さないことについて、失敗を確かめる
- [ ] 1.3 `bin/uskn-harness` の生成と旧スキルの削除を実装し、1.1と1.2のテストが通ることを確かめる
- [ ] 1.4 `doctor` の検査を `commands/opsx` の6ファイルに替える。そろっていれば `ok`、欠ければ名前入りの `warn` になることをbatsで確かめる
- [ ] 1.5 `deps.json` のopenspecを1.13.2にし、`checked` を2026-09-25にする。batsの版の期待を直し、テストが通ることを確かめる
- [ ] 1.6 `skills/archive-push/SKILL.md` の手順5の呼び出しを `opsx:archive` に替える。
  `skills/` の下に `openspec-archive-change` が残っていないことを `grep` で確かめる
- [ ] 1.7 ADR-0001の§6に、profileとdeliveryとその理由を日付付きで追記し、textlintとterms-checkが通ることを確かめる

## 2. 実体の無いsymlinkを掃除する

- [ ] 2.1 `sync` の掃除のテストを偽のHOMEで書く。ハーネスの `skills/` を指す実体の無いsymlinkを消すことについて、失敗を確かめる。
  ハーネス外を指すもの、移動したスキル、`--dry-run`、`sync --remove` の場合も含める
- [ ] 2.2 `sync` と `sync --remove` に削除を実装し、2.1のテストと既存の「dangling or moved symlink」のテストが通ることを確かめる
- [ ] 2.3 `doctor` が同じsymlinkを名前入りの `warn` と報告するテストを書いてから実装し、通ることを確かめる

## 3. スキルを削除し、verifyに統合する

- [ ] 3.1 `skills/verify/SKILL.md` に、完了の根拠の規則、CIの設定から確認コマンドを導く手順、報告の例を足す。descriptionも合わせ、`make verify-skills` が通ることを確かめる
- [ ] 3.2 `nessun-dorma`、`pre-merge`、`using-git-worktrees`、`verification-before-completion` のディレクトリを削除する。
  `deps.json` の `forks` の2項目も削除する。batsの導入スキルの一覧を直し、テストが通ることを確かめる
- [ ] 3.3 `templates/user/CLAUDE.md`、`skills/git/fix-ci`、`skills/verify`、`skills/systematic-debugging` の参照を直す。
  `templates/user/CLAUDE.md` が削除したスキルの名前を含まないことを確かめるbatsのテストを足し、通ることを確かめる
- [ ] 3.4 README、ADR-0001の§8と§9、`docs/setup-new-machine.md`、`methodology-skills` のmain specのPurposeを直す。
  archiveとproposalの記録を除く `grep` で、削除したスキルの名前が残っていないことを確かめる

## 4. uskn schemaに上流の案内文を取り込む

- [ ] 4.1 `schemas/uskn/schema.yaml` の指示とテンプレートに、上流 `spec-driven` の1.12.0から1.13.2までの差分を移す。
  1.13.2と1.12.0の両方で `openspec schema validate uskn` が通ることを確かめる
- [ ] 4.2 `openspec instructions proposal` の出力に `openspec list --specs` が含まれることを、この作業ツリーのschemaを解決させた状態で確かめる

## 5. 移行スクリプトを削除する

- [ ] 5.1 `templates/chezmoi/` の移行スクリプトを削除し、ファイル名を `openspec/known-names.txt` に足す。`make verify-terms` が通ることを確かめる
- [ ] 5.2 dotfilesをscratchpadにfresh cloneし、スクリプトのコピーを消すdraft PRを作る。PRのURLを確かめる

## 6. 全体の確認

- [ ] 6.1 `make verify` と `openspec validate retire-obsolete-skills --strict` が通ることを確かめる
- [ ] 6.2 `fix-hook-bugs` とこの変更を、一時的なcloneで順にarchiveする。main specsにRENAMEDとMODIFIEDが反映されることを確かめる
