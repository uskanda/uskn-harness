# bash-guard Specification

## Purpose
Bash 経由で他のプロジェクトを書き換える典型（chezmoi の適用、他 repo への git 操作）を止め、それ以外の疑わしい操作は警告に留める hook。誤検知よりも取りこぼしを許容する。

## Requirements

### Requirement: deny パターン
コマンドが次のいずれかを含むとき、hook は `permissionDecision: deny` と理由を返さなければならない（MUST）。

- `chezmoi apply|add|update|edit|re-add|merge`
- ルート外の絶対パスを指す `git -C <path>`、またはそこへ `cd` したあとの git の書き込み操作
- 書き込み操作とは `push`、`commit`、`reset`、`checkout`、`switch`、`rebase`、`merge`、`cherry-pick`、`apply`

ルート内、許可リスト内、allow に列挙されたパスは対象外。`~` は `$HOME` に展開して判定する。

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
コマンドがルート外の絶対パスへのリダイレクト（`>`、`>>`）や `cp|mv|rm|ln|tee|mkdir|touch|sed -i` を含むとき、hook は警告を返さなければならない（MUST）。
警告は `hookSpecificOutput.additionalContext` に入れ、対象パスと、他 repo は PR か handoff で扱う旨を書く。
このとき拒否してはならない（MUST NOT）。

#### Scenario: 外へのコピー
- **WHEN** `cp x.md ~/repos/b/` を実行しようとする
- **THEN** 警告が付き、拒否はされない

### Requirement: 失敗しても止めない
入力が読めない場合は何も出力せず終了コード 0（MUST）。

#### Scenario: 壊れた入力
- **WHEN** stdin が JSON でない
- **THEN** 出力は空
