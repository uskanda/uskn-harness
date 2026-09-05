# machine-bootstrap Specification

## Purpose
新しいマシンで dotfiles を適用するだけでハーネスが使える状態にする、chezmoi の run_once スクリプトの契約。スクリプトの正本はハーネスに置き、dotfiles へは PR でコピーする。

## Requirements

### Requirement: 手順
`templates/chezmoi/run_once_install-uskn-harness.sh.tmpl` は、Linux と macOS で次を非対話で実行しなければならない（MUST）。

- git の存在確認
- mise が無ければ `~/.local/bin/mise` に導入
- `~/.local/share/uskn-harness` が無ければ用意する。`~/repos/uskn-harness` があれば symlink、無ければ GitHub から clone
- 最後に `uskn-harness sync`

Windows では何もしない。

#### Scenario: 新しい Linux マシン
- **WHEN** `chezmoi apply` が初回実行される
- **THEN** スクリプトは 1 回だけ走り、終了時の `uskn-harness doctor` が終了コード 0 になる

#### Scenario: 2 回目の apply
- **WHEN** 同じマシンで再度 `chezmoi apply` する
- **THEN** run_once は再実行されない

### Requirement: 失敗時の振る舞い
ネットワークが無いなどで途中失敗した場合、スクリプトは非ゼロで終わり、何が済んで何が残ったかを標準エラーに出力しなければならない（MUST）。部分的に作られた symlink は次回の `sync` が引き継ぐ。

#### Scenario: clone に失敗
- **WHEN** GitHub に到達できない
- **THEN** スクリプトは非ゼロで終わり、`sync` を後で手動実行するよう案内する
