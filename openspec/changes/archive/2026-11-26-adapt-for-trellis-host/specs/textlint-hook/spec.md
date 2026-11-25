# Spec Delta

## MODIFIED Requirements

### Requirement: 設定の選択
hookは、書いたファイルが属するgitルートに `.textlintrc*` があれば、それを使わなければならない（MUST）。
無ければハーネスの `skills/ja-writing/textlintrc.json` を使う。
textlintは、そのgitルートを作業ディレクトリにして実行する。textlintがgitルートの `.textlintignore` を読むため。
gitルートは、ファイルの置き場のディレクトリから求め、symlinkを解決する。
入力の `cwd` と `CLAUDE_PROJECT_DIR` がほかの場所を指していても、ファイルの側のgitルートで探す。
ファイルがどのgitリポジトリにも属さないときは、ハーネスの設定を使い、ファイルの置き場を作業ディレクトリにする。

#### Scenario: リポジトリの設定
- **WHEN** プロジェクトルートに `.textlintrc.json` がある
- **THEN** `--config` を付けずにプロジェクトルートで実行し、その設定が使われる

#### Scenario: worktree の設定
- **WHEN** `CLAUDE_PROJECT_DIR` がリポジトリ `a` で、そのworktreeにだけ `.textlintrc.json` がある。そのworktreeの中の文書を書く
- **THEN** worktreeの `.textlintrc.json` が使われる

#### Scenario: 別のリポジトリの文書
- **WHEN** `cwd` が `.textlintrc*` の無いリポジトリ `a` で、`.textlintrc.json` のあるリポジトリ `b` の文書を書く
- **THEN** `b` の `.textlintrc.json` が使われ、textlintは `b` のルートで実行される

#### Scenario: 除外したファイル
- **WHEN** gitルートの `.textlintignore` が `docs/legacy/**` の行を持ち、`docs/legacy/a.md` に指摘のある日本語を書く
- **THEN** 出力は空

#### Scenario: リポジトリの外の文書
- **WHEN** gitリポジトリの外の `/tmp/x.md` に、指摘のある日本語を書く
- **THEN** ハーネスの設定で検査され、指摘が返る

## ADDED Requirements

### Requirement: 閉じた環境での textlint の実行
閉じた環境の間、hookはtextlintを、confined-hook-sandboxの規則の中で実行しなければならない（MUST）。
リポジトリの `.textlintrc.js` やプラグインは、エージェントが書けるコードであるため。
textlintは、環境の印の `tools` が指す共有の置き場の `bin/` から選ぶ。
規則を使えないときは、textlintを実行せず、検査しなかったことを `additionalContext` で返す。

#### Scenario: リポジトリの設定が外へ送る
- **WHEN** 閉じた環境のmacOSで、`.textlintrc.js` が外のホストへ接続するリポジトリの文書を書く
- **THEN** 接続は拒否され、書き込みはblockされない

#### Scenario: 規則を使えない
- **WHEN** 閉じた環境のLinuxで、日本語の文書を書く
- **THEN** textlintは実行されず、`additionalContext` に検査しなかったことが含まれる
