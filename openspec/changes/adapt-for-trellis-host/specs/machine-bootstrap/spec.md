# Spec Delta

## MODIFIED Requirements

### Requirement: 手順
dotfilesへ写すbootstrapの正本は `templates/chezmoi/run_after_uskn-harness.sh.tmpl` に置く。
このスクリプトは、LinuxとmacOSで `chezmoi apply` のたびに次を非対話で実行しなければならない（MUST）。

- gitの存在確認
- miseが無ければ `~/.local/bin/mise` に導入
- `~/.local/share/uskn-harness` が無ければ用意する。開発用のcheckoutがあればsymlink、無ければGitHubからclone
- 最後に `uskn-harness sync`

開発用のcheckoutの場所は、`~/.config/uskn-harness/dev-checkout` の1行目である。`~` で始まる値はホームに展開する。
ファイルが無いか空のときは `~/repos/uskn-harness` とする。
jqの入る前に走るので、このファイルはJSONにしない。
Windowsでは何もしない。
スクリプトはファイルの適用の後に走るので、dotfilesが同じapplyで消したファイルの跡にsyncがsymlinkを置ける。
閉じた環境は、このスクリプトの対象外である。閉じた環境のcheckoutとsyncの実行は、端末の土台が用意する。

#### Scenario: 新しい Linux マシン
- **WHEN** `chezmoi apply` が初回実行される
- **THEN** スクリプトが導入から `sync` まで走り、終了時の `uskn-harness doctor` が終了コード0になる

#### Scenario: 2 回目の apply
- **WHEN** 同じマシンで再度 `chezmoi apply` する
- **THEN** スクリプトは再び走り、`sync` は各項目を `ok` と報告する

#### Scenario: ハーネスが進んでいる
- **WHEN** ハーネスのupstreamが進んだ状態で `chezmoi apply` する
- **THEN** `sync` がcheckoutをfast-forwardし、新しい版で導入を続ける

#### Scenario: 開発用の checkout を別の場所に置く
- **WHEN** `~/.config/uskn-harness/dev-checkout` が `~/src/uskn-harness` を指し、そこにgitのcheckoutがあり、参照点が無い
- **THEN** 参照点は `~/src/uskn-harness` へのsymlinkになり、cloneは行われない

#### Scenario: 設定の無い端末
- **WHEN** `~/.config/uskn-harness/dev-checkout` が無く、`~/repos/uskn-harness` にgitのcheckoutがあり、参照点が無い
- **THEN** 参照点は `~/repos/uskn-harness` へのsymlinkになる
