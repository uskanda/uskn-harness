## Why

セッションで何を決め、何を変え、何が未解決かは、会話が閉じると失われる。全文トランスクリプトは重く機密も混ざる。決定的に抽出できる骨格を hook が書き、判断だけをエージェントが追記する軽量な journal を、専用 repo で全マシンに同期する。

## What Changes

- GitHub private `uskanda/ai-sessions` を作り、`sync` が `~/.ai-sessions` に clone する
- Stop hook `journal-update.sh`: そのセッションの journal（`<owner>__<repo>/<日付>-<HHMM>-<slug|sid8>.md`）の決定的な部分（メタ、プロンプト、変更、コミット、使ったスキル）を増分更新する。作業ツリーに変更があり決定欄が空なら、セッション中 1 回だけ `decision: block` で `journal` スキルの実行を求める
- SessionEnd hook `journal-end.sh`（timeout 60 秒）: 最終更新のうえ sessions repo に commit し、push を試みる（失敗は無視）
- SessionStart hook `journal-recent.sh`: 同じプロジェクトの直近 3 件の title / Decisions / Next を `<recent-sessions>` として注入する。`session-start.sh` は `session: <sid8>` を `<repo-context>` に加える
- `journal` スキル（決定 / 未解決 / 次の一手の追記と slug 付け）、`recall` スキル（ripgrep 検索）
- `commit` スキルは `Session: <sid8>` トレーラを付ける
- `sync` / `doctor` は sessions repo の clone を扱う

## Capabilities

### New Capabilities
- `journal-skeleton`: Stop 時の決定的な journal 更新と、決定欄を書かせる 1 回限りの block
- `journal-sync`: SessionEnd の commit / push と sessions repo の配置
- `journal-context`: SessionStart で注入する直近 journal と、`<repo-context>` の session 行
- `journal-skill`: `journal` スキルの振る舞い
- `recall-skill`: `recall` スキルの振る舞い

### Modified Capabilities
- `git-workflow-skills`: `commit` が `Session:` トレーラを付ける要件を追加
- `harness-sync`: sessions repo の clone を追加
- `harness-doctor`: sessions repo の検査を追加

## Impact

- 新規: `plugins/uskn-harness/hooks/scripts/{journal-update.sh,journal-end.sh,journal-recent.sh}`、同 tests、`skills/journal/`、`skills/recall/`、GitHub repo `uskanda/ai-sessions`
- 変更: `session-start.sh`、`hooks.json`、`skills/git/commit/SKILL.md`、`bin/uskn-harness`、`deps.json`、`templates/user/CLAUDE.md`
- 依存: `rg`（recall。無ければ `grep -r`）、gh（repo 作成時のみ）
