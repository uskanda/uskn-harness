# bash-guard Specification

## Purpose
Bash 経由で他のプロジェクトを書き換える典型（chezmoi の適用、他 repo への git 操作）を止め、それ以外の疑わしい操作は警告に留める hook。誤検知よりも取りこぼしを許容する。

## Requirements

### Requirement: deny パターン
コマンドが `chezmoi apply|add|update|edit|re-add|merge`、または `git -C <ルート外の絶対パス>` もしくは `cd <ルート外の絶対パス>` に続く `git push|commit|reset|checkout|switch|rebase|merge|cherry-pick|apply` を含むとき、hook は `permissionDecision: deny` と理由を返さなければならない（MUST）。ルート内や許可リスト内、allow に列挙されたパスは対象外。`~` は `$HOME` に展開して判定する。

#### Scenario: chezmoi apply
- **WHEN** `chezmoi apply --force` を実行しようとする
- **THEN** 拒否される

#### Scenario: 他 repo への push
- **WHEN** `cd ~/dotfiles && git push origin master` を実行しようとする
- **THEN** 拒否される

#### Scenario: 読み取り
- **WHEN** `git -C ~/dotfiles log --oneline -3` を実行しようとする
- **THEN** 何も出力しない

### Requirement: warn パターン
コマンドがルート外の絶対パスへのリダイレクト（`>`、`>>`）や `cp|mv|rm|ln|tee|mkdir|touch|sed -i` を含むとき、hook は `hookSpecificOutput.additionalContext` に警告（対象パスと、他 repo は PR か handoff で扱う旨）を返し、拒否はしてはならない（MUST NOT）。

#### Scenario: 外へのコピー
- **WHEN** `cp x.md ~/repos/b/` を実行しようとする
- **THEN** 警告が付き、拒否はされない

### Requirement: 失敗しても止めない
入力が読めない場合は何も出力せず終了コード 0（MUST）。

#### Scenario: 壊れた入力
- **WHEN** stdin が JSON でない
- **THEN** 出力は空
