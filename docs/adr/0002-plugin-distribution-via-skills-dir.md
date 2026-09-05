# ADR-0002: Claude 向け hook 配布は skills-dir プラグインの symlink で行う

- 状態: 採用（2026-09-05）。ADR-0001 §3（marketplace.json）と §4（plugin 配布）を差し替える
- 決定者: uskanda（Phase 1 grilling Q32〜Q35）

## 文脈

ADR-0001 では Claude Code 向けの hook を marketplace 経由のプラグインで配る想定だった。
検証してみると、`~/.claude/skills/<name>` に置いたディレクトリも読み込まれた。
`.claude-plugin/plugin.json` があれば skills-dir プラグインとして扱われる。
`hooks/hooks.json` も有効になり、置き場は symlink でもよい。
一方で `npx skills add <ローカルパス>` はコピーで、live 編集が効かない。mise の shims はグローバル設定が無いと
他ディレクトリで解決しない。

## 決定

1. 各マシンでのハーネスの参照点は `~/.local/share/uskn-harness`。開発機では `~/repos/uskn-harness` への symlink、
   他端末では managed clone。`USKN_HARNESS_DIR` で上書きできる
2. Claude 向け hook は `~/.claude/skills/uskn-harness -> <harness>/plugins/uskn-harness` の symlink で配る。
   marketplace.json と `claude plugin install` は使わない。settings.json は触らない
3. hook スクリプトの正本は `plugins/uskn-harness/hooks/scripts/`（`${CLAUDE_PLUGIN_ROOT}` 基準で自己完結）。
   トップレベル `hooks/` は他ツール向けアダプタだけを置き、安定パス経由で同じスクリプトを参照する
4. 自作スキルは `sync` が `skills/**/<name>` ごとに `~/.claude/skills/<name>` へ symlink を張る。
   `npx skills add <owner/repo> --skill <name> -g -a claude-code` はサードパーティ専用
5. installer は `mise use -g node@24` でグローバル既定を書く

## 結果

- 良い点: 導入が symlink だけになり、編集が即反映される。settings.json（chezmoi 管理）との競合が無い
- 引き受けるコスト: skills-dir プラグインは `bin/` 非対応（installer は `~/.local/bin/uskn-harness` の symlink で PATH に載せる）。
  マシン間の更新は `git pull`（`sync` が行う）に依存する
