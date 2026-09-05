## Why

ハーネスの正本（スキル、プラグイン、テンプレート、外部依存のピン）はリポジトリに揃うが、各マシンの `~/.claude` や `~/.local` へ届ける手段が無い。手作業の symlink は再現できず、chezmoi 管理の dotfiles と衝突する。冪等な `uskn-harness sync` と状態レポート `doctor` を用意し、dotfiles 側は「mise を入れてハーネスを clone し `sync` を呼ぶ」だけにする。

## What Changes

- `bin/uskn-harness` を新設する（bash）。サブコマンドは `sync`（冪等な導入と更新）、`doctor`（状態レポート、問題があれば非ゼロ終了）、`init`（`sync` の別名）。`--dry-run` で書き込みを抑止する
- `sync` は次を行う: 参照点 `~/.local/share/uskn-harness` の用意（開発 checkout への symlink か managed clone）、mise の導入とグローバル既定（`node@24`、`jq`）、`deps.json` のバージョンで CLI（openspec）を導入、`~/.local/bin/uskn-harness` の symlink、`skills/**/<name>` の `~/.claude/skills/<name>` への symlink（既存の実ディレクトリはスキップして警告）、`plugins/uskn-harness` の `~/.claude/skills/uskn-harness` への symlink、`deps.json` の `skills`（mode=reference）を `npx skills add` で導入、OpenSpec の Claude 用スキルとコマンドをユーザー層へ生成、`templates/user/CLAUDE.md` を `~/.claude/CLAUDE.md` へ配置（ハーネス管理の印が無いファイルは上書きしない）
- `doctor` は symlink の欠落や向き先違い、CLI のバージョン不一致、mise / node / jq の有無、chezmoi 管理の同名スキルとの衝突、`deps.json` の ref と導入済みサードパーティの差を報告する
- `templates/user/CLAUDE.md`（ユーザー層の指示）と `templates/chezmoi/run_once_install-uskn-harness.sh.tmpl`（dotfiles 用 bootstrap）を新設する
- dotfiles PR #10 に積む内容（本 change のタスクとして実施、ライブの作業ツリーには触れない）: zshrc の nvm / pyenv 記述の削除、run_once の追加、`.chezmoiignore` へハーネス由来 symlink と `~/.claude/CLAUDE.md` の追加、`dot_claude/skills` から移管済み 13 スキルと `openspec-*` の削除、`settings.json.tmpl` から `claude-hosting-hook` の SessionStart を削除、`dot_local/bin/executable_claude-hosting-hook` の削除
- このリポジトリ自身の `.claude/skills/openspec-*` と `.claude/commands/opsx` は、ユーザー層で提供されるようになった時点で削除する（プロダクト repo と同じ扱いにする）

## Capabilities

### New Capabilities
- `harness-sync`: `uskn-harness sync` の冪等な導入手順と、既存物との衝突時の振る舞い
- `harness-doctor`: `uskn-harness doctor` の検査項目と終了コード
- `user-layer-instructions`: ユーザー層の指示ファイルの内容と配置の契約
- `machine-bootstrap`: 新しいマシンで dotfiles の適用からハーネスが使えるまでの契約（run_once スクリプト）

### Modified Capabilities
（なし）

## Impact

- 新規: `bin/uskn-harness`, `bin/tests/*.bats`, `templates/user/CLAUDE.md`, `templates/chezmoi/run_once_install-uskn-harness.sh.tmpl`
- 変更: `deps.json`（jq の追加、openspec の導入コマンド）、`Makefile`（bin のテスト）、`README.md`
- 他リポジトリ: `uskanda/dotfiles` PR #10（別クローンから push）。`~/.claude/skills` と `~/.local` はこのマシンで `sync` により変化する（ユーザー承認済み、Q37）
- 依存: mise（curl で導入）、Node 24（mise）、jq（mise または OS）、git、gh（PR 作成時）
