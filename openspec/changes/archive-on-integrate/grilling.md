# grilling 記録: archive-on-integrate

issue #19のコメントで、計画についての質問（Q1〜Q6）に推奨回答を付けて尋ね、issueの持ち主が答えた。
その後、回答を前提にした計画を示し、`/ok` で承認を得た。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| どの操作を「作業を終える」とみなすか | `pr` のintegrationモードとcustomモード、`push` による統合ブランチか既定ブランチへの直接のpush、エージェントが実行する `gh pr merge` と `glab mr merge` の3つ。releaseモード、qaモード、`spec-pr` は対象にしない。作業ブランチへの途中のpushも対象にしない | issue #19 Q1（推奨どおり） |
| archiveをだれが実行するか | `pr` と `push` が、未archiveの変更を見つけたら `archive-push` を呼ぶ。`archive-push` から `disable-model-invocation` を外し、specを「ユーザーか、統合の操作を行うスキルが呼ぶ」に改める | issue #19 Q2（A） |
| 「archiveしない」の宣言の書き方 | 変更のディレクトリに `.archive-later` を置き、理由を1行書く。ユーザーがチャットで宣言したときは、エージェントがこのファイルを作る。用語集に足す | issue #19 Q3（A） |
| センサーの形 | PreToolUse hook（bash-guardの拡張）が統合の操作を拒否する。加えて、このリポジトリのCIが、draftでないPRで未archiveの変更を確かめる。製品リポジトリには配らない | issue #19 Q4（B） |
| uskn-loopの扱い | 変えない。完了コメントの案内もそのままにし、`pr` の自動archiveとCIで補う | issue #19 Q5（A） |
| 残っている未archiveの変更2件 | このブランチでdoctor-probe-nested-usernsとsandbox-rules-revisitをarchiveする。sandbox-rules-revisitの9.2は、archive-pushの規則どおり「（archive-pushで完了とみなした）」と注記する。実装とは別のコミットにする | issue #19 Q6（A） |
| 計画全体 | 計画（判定を1つのコマンド `uskn-archive-check` にまとめる、ADR-0014に残す、この変更自体もPRの前にarchiveする、など）を承認した | issue #19 の計画への `/ok` |

## 後回しにしたもの

- uskn-loopが完了基準を満たした後にブランチ上でarchiveする案（Q5のB）。docsでarchiveを人の承認の後に置いているので、別のissueでgrillingする

## 状態

frontierは空。共有理解は2026-11-03に確認済み（issue #19の計画への `/ok`）。
