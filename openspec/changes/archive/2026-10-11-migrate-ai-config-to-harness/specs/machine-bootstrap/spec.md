## MODIFIED Requirements

### Requirement: 手順
dotfilesへ写すbootstrapの正本は `templates/chezmoi/run_after_uskn-harness.sh.tmpl` に置く。
このスクリプトは、LinuxとmacOSで `chezmoi apply` のたびに次を非対話で実行しなければならない（MUST）。

- gitの存在確認
- miseが無ければ `~/.local/bin/mise` に導入
- `~/.local/share/uskn-harness` が無ければ用意する。`~/repos/uskn-harness` があればsymlink、無ければGitHubからclone
- 最後に `uskn-harness sync`

Windowsでは何もしない。
スクリプトはファイルの適用の後に走るので、dotfilesが同じapplyで消したファイルの跡にsyncがsymlinkを置ける。

#### Scenario: 新しい Linux マシン
- **WHEN** `chezmoi apply` が初回実行される
- **THEN** スクリプトが導入から `sync` まで走り、終了時の `uskn-harness doctor` が終了コード0になる

#### Scenario: 2 回目の apply
- **WHEN** 同じマシンで再度 `chezmoi apply` する
- **THEN** スクリプトは再び走り、`sync` は各項目を `ok` と報告する

#### Scenario: ハーネスが進んでいる
- **WHEN** ハーネスのupstreamが進んだ状態で `chezmoi apply` する
- **THEN** `sync` がcheckoutをfast-forwardし、新しい版で導入を続ける

### Requirement: 失敗時の振る舞い
ネットワークが無いなどで途中失敗した場合、スクリプトは非ゼロで終わり、何が済んで何が残ったかを標準エラーに出力しなければならない（MUST）。部分的に作られたsymlinkは次回の `sync` が引き継ぐ。

#### Scenario: clone に失敗
- **WHEN** GitHubに到達できない
- **THEN** スクリプトは非ゼロで終わり、次の `chezmoi apply` か `uskn-harness sync` で続きを行うよう案内する
