# grilling 記録: hook-native-features

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| hookの `if` | textlint-checkとterms-checkは `**/*.md` に限る。`if` は1つの規則しか書けないので、EditとWriteに1つずつ書く。grilling-guardは `**/openspec/changes/**` に限る | 第1ラウンド Q17 |
| Stop時のverify | Makefileに `verify-fast` があればそれを使い、無ければ `verify` を使う。ハーネスの `verify-fast` は、変更された文書のtextlintとterms、変更されたスクリプトのshellcheck、スクリプトやテストに変更があるときのbats。フルのverifyはCIとarchive-pushで回す | 第1ラウンド Q18 |
| block後の再検証 | 失敗が続くあいだは、1ターンで3回までblockする | 第1ラウンド Q19 |
| rootの定義 | guardは、セッションのroot（`CLAUDE_PROJECT_DIR`）とcwdのgit top-levelの両方を許す。verifyとbaselineはcwdのtop-levelを使う | 第1ラウンド Q20 |
| pluginの `bin/` | スキルが長いパスで呼んでいる補助スクリプトを、pluginの `bin/` の短いコマンドにする。`~/.local/bin/uskn-harness` はhook、CI、通常のシェル用に残す。ADR-0002の記述を直す | 第1ラウンド Q27 |
| verify gateの状態ファイル | `verified` と `baseline` を、許可ファイルと同じくエージェントのWrite、Edit、Bashから守る | fix-hook-bugsの残課題。Q19の実装に伴う |

## 後回しにしたもの

- なし

## 状態

frontierは空。共有理解は2026-09-25に/okで確認済み。
