# grilling 記録: deps-real-pinning

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 第三者スキルのピン | deps.jsonのrefをタグか40桁のSHAにそろえる。`npx -y skills@1.7.0 add '<source>#<ref>'` で入れる。lockの `ref` とdeps.jsonを比べ、違えば入れ直す。doctorも差を報告する。初回は全スキルを1回ずつ入れ直す | 第1ラウンド Q21 |
| skills CLI | `latest` をやめて1.7.0に固定する | 第1ラウンド Q21 |
| humanizer | v3.0.0に固定する。en-writingはhumanizerを最終の文章だけ返す形で呼ぶ1行を足す | 第1ラウンド Q22 |
| impeccable | スキル4.3.1（zipとsha256）とCLI 4.1.0に固定し、`IMPECCABLE_BUNDLE_PATH` で入れる。ui-guidelinesに、Impeccableが書いたDESIGN.mdとサイドカーは採らないと明記し、鮮度警告を止める | 第1ラウンド Q23（ユーザーがAを選択） |
| impeccableのagent | `sync` がインストール後に `~/.claude/agents/impeccable-*.md` の4つを消す | 第1ラウンド Q24 |
| Claude Codeの版 | 厳密に管理しない。最新版の利用を妨げない。CIは版を指定せずに入れる。問題が起きたらこのリポジトリの更新を検討する | 第1ラウンド Q26（ユーザーの指示で推奨案から変更） |

## 後回しにしたもの

- なし

## 状態

frontierは空。共有理解は2026-09-25に/okで確認済み。
