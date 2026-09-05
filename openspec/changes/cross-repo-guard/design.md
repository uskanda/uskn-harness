## Context

- PreToolUse の入力に `tool_name`、`tool_input`、`cwd`、`session_id`。プロジェクトルートは環境変数 `CLAUDE_PROJECT_DIR`
- deny は `hookSpecificOutput.permissionDecision`、警告は `hookSpecificOutput.additionalContext`（判断なし）
- 状態ディレクトリは verify-gate / journal と共用。スキルは `sid8` から前方一致でディレクトリを探す（`allow-repo.sh` が担当）

## Goals / Non-Goals

**Goals:**
- 編集ツールは実体パスで確実に判定する
- Bash は誤検知を抑え、確実な典型だけ deny

**Non-Goals:**
- サブシェル、`eval`、変数展開を介した回避の網羅（警告レベルで拾えれば十分。最終的な担保はユーザー層の指示と journal）

## Decisions

1. **ルートの決定**: `CLAUDE_PROJECT_DIR` → `git -C cwd rev-parse --show-toplevel` → `cwd`。すべて `realpath` で比較
2. **許可リストは固定 + allow ファイル**。固定: `/tmp`、`$TMPDIR`、`~/.ai-sessions`、`~/.claude/projects/*/memory`、状態ディレクトリ、`$CLAUDE_PLUGIN_DATA`。`~/.claude/skills` は含めない（そこはハーネスの `sync` が触る場所であり、セッションが直接書く場所ではない）
3. **Bash の判定はトークン化せず正規表現**。`chezmoi (apply|add|update|edit|re-add|merge)`、`git -C (\S+) .*\b(push|commit|reset|checkout|switch|rebase|merge|cherry-pick|apply)\b`、`cd (\S+)[^|;&]*(&&|;)[^|;&]*git (push|…)`。パスは `~` と `$HOME` を展開し、絶対パスのときだけ外かどうかを判定する（相対パスはルート内とみなす）
4. **warn は 1 コマンドにつき 1 回、パスを列挙**。`additionalContext` に「他 repo は PR か handoff。必要なら /allow-repo」
5. **`allow-repo.sh` の引数は `--session <sid8> <path>`**。`sessions/` を走査して `<sid8>*` に一致する 1 つを選ぶ。複数一致なら最新を使い警告
6. **hooks.json の matcher**: `Write|Edit|MultiEdit|NotebookEdit` に `write-guard.sh` を grilling-guard と並べ、`Bash` に `bash-guard.sh`

## Risks / Trade-offs

- [`CLAUDE_PROJECT_DIR` が無い実行系] → git ルートにフォールバック。他ツールでも同じスクリプトが動く
- [正規表現の取りこぼし] → deny は典型に限定し、それ以外は警告 + ユーザー層の指示で抑止
- [ハーネス自身の `sync` が `~/.claude/skills` を書く] → `sync` は Bash から呼ばれる別プロセスで、Write ツールではないので write-guard の対象外。bash-guard のパターンにも該当しない

## Migration Plan

hooks.json に追加。問題があれば該当行を外す。
