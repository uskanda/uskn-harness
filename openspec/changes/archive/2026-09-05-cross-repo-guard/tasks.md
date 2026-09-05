## 1. write-guard（TDD）

- [x] 1.1 `write-guard.bats`: ルート内は無出力、ルート外は deny（理由に /allow-repo）、`/tmp` と `$TMPDIR` と `~/.ai-sessions` と memory と状態ディレクトリは無出力、symlink 経由のルート内、allow ファイルによる解除、`CLAUDE_PROJECT_DIR` 無しで git ルート、壊れた入力。RED
- [x] 1.2 `write-guard.sh` を実装して GREEN、shellcheck 警告ゼロ

## 2. bash-guard（TDD）

- [x] 2.1 `bash-guard.bats`: `chezmoi apply` deny、`cd ~/dotfiles && git push` deny、`git -C <外> commit` deny、`git -C <外> log` 無出力、ルート内の git push 無出力、`cp x <外>/` warn（additionalContext）、`> <外>/f` warn、allow で解除、壊れた入力。RED
- [x] 2.2 `bash-guard.sh` を実装して GREEN、shellcheck 警告ゼロ

## 3. allow-repo と配線

- [x] 3.1 `allow-repo.sh`（`--session <sid8> <path>`、`--list`）と bats、`skills/allow-repo/SKILL.md`。frontmatter 検査が通る
- [x] 3.2 `hooks.json` に write-guard（既存 matcher に追加）と bash-guard（`Bash`）を配線し、`claude plugin validate --strict` が通る
- [x] 3.3 `templates/user/CLAUDE.md` の Boundaries と README を更新し、`sync` で反映。`openspec validate cross-repo-guard --strict` と `make verify` が通ることを確認してコミットする
