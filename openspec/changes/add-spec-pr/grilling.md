# grilling 記録: add-spec-pr

このgrillingは `add-loop-run` と共通で行った（調査と提案は `docs/loop-engineering-2026-09.md`）。
この表には `add-spec-pr` に関わる行だけを載せる。残りの行は `add-loop-run` のgrilling.mdにある。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| changeの分け方 | 2つに分け、`add-spec-pr`、`add-loop-run` の順に進める。grillingは1回で両方を扱い、同じ対話を2つのgrilling.mdに分けて記録する | 第1ラウンド Q1 |
| 仕様PRを作る機能の形 | 新しいスキル `spec-pr` を作る。引数がアイデアなら `spec` を呼んで成果物を作ってから、既存のchange名ならそのまま、ブランチを切ってコミットし、draft PRを作る。`/spec` は計画だけを行うという今の責務を保つ | 第1ラウンド Q4 |
| ブランチ名 | `change/<change名>`。ブランチには実装も載るので `spec/` は使わない | 第2ラウンド Q1 |
| タイトルと本文 | タイトルはproposalの要点を1行にする。本文はproposalの要約、成果物へのリンク、`uskn-loop run` によるループの起動方法にする。tasksは本文に写さない | 第2ラウンド Q2 |
| 前提条件 | 成果物がすべてそろい、`openspec validate --strict` が通ること。コミットするのはchangeのディレクトリだけ。draft PRの向き先は統合ブランチ | 第2ラウンド Q3 |
| 誰が起動できるか | ユーザーとエージェントの両方。`disable-model-invocation` を付けない | 第2ラウンド Q3（ユーザーがBに上書き） |
| GitLab | GitHubとGitLabの両方に対応する。GitLabではdraft MRを作る。GitLabのリポジトリは手元に無いので、実機での確認は後回しにする | 第2ラウンド Q4へのユーザーの追加指示、第3ラウンド Q1 |
| `/spec` の終わり方 | 最後の案内に `/spec-pr <name>` を並べるだけにする。エージェントが `spec-pr` を呼ぶのは、ユーザーが仕様PRを求めたときだけ | 第3ラウンド Q3 |
| 自動マージ | 付けない。`pr` スキルの統合モードは自動マージを付けるので、仕様PRはその経路を使わずに作る | 第3ラウンドの共有理解として会話中に確認 |

## 後回しにしたもの

- GitLabのリポジトリでの実機確認。対象のリポジトリができたときに行う
- Issueから仕様PRの下書きを作ること（段階3）

## 状態

frontierは空。共有理解は2026-09-30に確認済み。
