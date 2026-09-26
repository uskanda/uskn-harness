# grilling 記録: agents-md-only

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 既存リポジトリの `CLAUDE.md` の扱い | 触らない。`onboard-check` は、あれば `@AGENTS.md` の参照を確認し、無ければ何も言わない。 | 第1ラウンドQ1 |
| Claude固有の記述の置き場 | `AGENTS.md` の `## Claude Code` 節。`CLAUDE.md` は作らない。`templates/repo/AGENTS.md` に任意の節として案内する。 | 第1ラウンドQ2 |
| `CLAUDE.md` が正本の既存リポジトリ | 中身を `AGENTS.md` へ移し、`CLAUDE.md` は削除する。 | 第1ラウンドQ3 |
| このリポジトリ自身の `CLAUDE.md` | 削除し、OpenSpecの1行は `AGENTS.md` へ移す。 | 第1ラウンドQ4 |
| 古いClaude Codeへの備え | `doctor` に最低バージョンの検査を足す。対応はv2.1.277から。 | 第1ラウンドQ5 |
| 最低バージョンの置き場 | `deps.json` に書く。`claude` が無いときは既存の道具と同じ扱い（skip、strictでは失敗）。 | 第2ラウンドQ6 |
| このリポジトリの `CLAUDE.md` を消す時期 | この変更に含める。Claude Codeを2.1.277以上へ更新し、新しいセッションで `AGENTS.md` が読まれることを確認してから消す。 | 第2ラウンドQ7 |
| `disableAllHooks` での評価で `AGENTS.md` が読まれない件 | 注意書きを足す方針。ただし評価手順の文書がリポジトリに無いため、この変更では扱わず後回しにする。 | 第2ラウンドQ8、第3ラウンドで確認 |
| `onboard-check` の判定 | `CLAUDE.md` が無ければok。あって `@AGENTS.md` を含めばok。あって含まなければwarn。`.claude/CLAUDE.md` も同じ判定。`CLAUDE.local.md` は対象外。 | 第2ラウンドQ9 |
| ADRの扱い | ADR-0003を新しく書く。ADR-0001の該当2か所には置き換えの注記だけを足す。 | 第3ラウンドQ10 |
| `deps.json` での区分 | `runtimes` に `claude-code` を置く。`sync` はインストールしない。キー名は既存の項目の形に合わせる。 | 第3ラウンドQ11 |
| 変更の名前と範囲 | `agents-md-only`。テンプレート、`onboard-harness`、`onboard-check`、`doctor`、spec 4本、このリポジトリの `AGENTS.md` と `CLAUDE.md`、ADR-0003、README。 | 第3ラウンドQ12 |

## 後回しにしたもの

- スキル評価（`claude -p --settings '{"disableAllHooks":true}'`）の手順の文書化。`CLAUDE.md` の無いcloneでは `AGENTS.md` が読まれないので、一時的な `CLAUDE.md`（`@AGENTS.md`）を置く必要がある。手順の文書ができるときに書く。
- 既存のプロダクトリポジトリから `CLAUDE.md` を消すこと。害が無いので触らない。
- ユーザー層の `~/.claude/CLAUDE.md`。プロジェクトのファイルではなく、`AGENTS.md` の読み込みにも影響しない。
- `push` スキル、`git-workflow-skills` のspec、`en-writing` にある `CLAUDE.md` への言及。既存のファイルがあれば読むという記述なので変えない。

## 状態

frontierは空。共有理解は2026-09-19に確認済み。
