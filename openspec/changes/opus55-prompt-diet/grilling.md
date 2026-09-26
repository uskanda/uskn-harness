# grilling 記録: opus55-prompt-diet

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| ユーザー層のCLAUDE.mdに残すもの | 言語、`/spec`・`/no-grilling`・`/ok` の短い説明、境界の1文（`/allow-repo` を含む）、verify規約の1行（「完了前に回せ」は外しgateに任せる）、テストを先に書くこと、日本語と英語のライティングの参照先、UIの正本。repo-contextの説明、gitスキルの一覧、検証を促す文は消す | 第1ラウンド Q12 |
| AGENTS.md | ユーザー層と重なる記述を消し、このリポジトリに固有のことだけを残す。Layoutに `bin/` の行を足す | 第1ラウンド Q13 |
| TDDとsystematic-debugging | 肯定形の書き方に直し、Iron Law、言い訳の表、Red Flagsを消す（約190行と約170行）。deps.jsonに上流と分岐済みで再取り込みしないと記録する。systematic-debuggingの説明文は原因の分からないバグや失敗に絞る | 第1ラウンド Q14 |
| スキルの説明文 | 約200字以内にし、引数の説明は `argument-hint` に移す | 第1ラウンド Q15 |
| user-onlyにするスキル | `rebase`、`cleanup-merged`、`release`、`onboard-harness`、`audit-writing` を `disable-model-invocation: true` にする。`pr`、`sync-base`、`switch-base` は残す | 第1ラウンド Q16 |

## 後回しにしたもの

- dotfiles側のスキル（chezmoi-merge、set-workspace-theme、sync-claude-settings）の説明文
- Claude Codeのsettingsのeffort（dotfilesの管理）

## 状態

frontierは空。共有理解は2026-09-25に/okで確認済み。
