## Why

「完了と言う前に検証する」はユーザー層の指示だけでは守られない。Stop hook で、そのセッションで作業ツリーが変わったときにだけリポジトリの検証規約を実行し、失敗したら終了させない。検証コマンドは `make verify` → `pnpm run verify` / `npm run verify` の規約（Q17）に従い、新しい設定ファイルは増やさない。

## What Changes

- SessionStart hook `session-baseline.sh` を追加し、セッション開始時の作業ツリーの指紋（HEAD、status、diff）を状態ディレクトリに記録する
- Stop hook `verify-gate.sh` を追加する。指紋が開始時（または前回成功時）から変わっていれば検証規約を実行し、失敗なら `decision: block` で失敗の要約を返す。`stop_hook_active`、`USKN_SKIP_VERIFY=1`、サブエージェント、非 git ディレクトリ、検証規約なしでは何もしない
- `verify` スキルを追加する（規約の見つけ方、実行、修正ループ、無いときの報告）
- 状態ディレクトリは `${XDG_STATE_HOME:-~/.local/state}/uskn-harness/sessions/<session_id>/`。プラグイン専用の環境変数ではなく固定パスにするのは、スキル（Bash ツール）からも同じ場所を参照するため
- `hooks.json` に SessionStart（baseline）と Stop（timeout 600 秒）を追加する

## Capabilities

### New Capabilities
- `session-baseline`: セッション開始時の作業ツリーの指紋の記録
- `verify-gate`: Stop 時の検証実行と block の条件
- `verify-skill`: `verify` スキルの外形的な振る舞い

### Modified Capabilities
（なし）

## Impact

- 新規: `plugins/uskn-harness/hooks/scripts/{session-baseline.sh,verify-gate.sh}`、同 tests、`skills/verify/`
- 変更: `plugins/uskn-harness/hooks/hooks.json`、`README.md`
- 実行時間: この repo の `make verify` は 1〜2 分。変更が無い応答では走らない
