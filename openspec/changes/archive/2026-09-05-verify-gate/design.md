## Context

- Stop hook の入力には `session_id`、`cwd`、`stop_hook_active`、`agent_type`（サブエージェント時）がある。block は `decision: block` と `reason`。timeout は hooks.json の `timeout`（既定 600 秒）
- SessionStart は `startup` / `resume` / `clear` / `compact` / `fork` で発火する。compact でも同じ session_id
- スキル（Bash ツール）からは `CLAUDE_PLUGIN_DATA` が見えないので、状態は固定パス `${XDG_STATE_HOME:-~/.local/state}/uskn-harness/` に置く。テストは `USKN_STATE_DIR` で差し替える
- hook の非対話シェルには mise の shims が無いことがあるので、スクリプト内で `~/.local/share/mise/shims` を PATH に足す

## Goals / Non-Goals

**Goals:**
- 変更があるときだけ、規約どおりの検証を Stop で強制する
- 無限ループと二重ブロックを避ける

**Non-Goals:**
- 検証の並列化やキャッシュ
- src 変更に対するテスト未変更の警告（Q8 で見送り）

## Decisions

1. **指紋 = sha256(HEAD の SHA + `git status --porcelain` + `git diff HEAD`)**。ファイル名だけでなく内容の変化も拾う。untracked は status に出る
2. **`baseline` と `verified` の 2 つの指紋**。`verified` は成功時に更新し、成功後に変更が無ければ再実行しない。失敗時は更新しないので、次の Stop でも再実行される
3. **block の出力は top-level の `decision` / `reason` と `hookSpecificOutput` の両方に同じ値を入れる**。ドキュメントは後者を示すが、既存の実装例は前者。両方あっても害は無い
4. **検証は `timeout 570` で包む**。hooks.json の timeout は 600。打ち切りは exit 124 として失敗扱い
5. **出力ログは `sessions/<sid>/verify.log`**。reason には末尾 40 行だけ入れ、全文はログを参照させる
6. **session-baseline.sh は session-start.sh と別スクリプト**。session-start は文脈の注入、baseline は状態の記録。hooks.json の同じ SessionStart に 2 つ並べる
7. **サブエージェント判定は `agent_type` の有無**。サブエージェントの Stop で verify を回すと親と二重になる

## Risks / Trade-offs

- [`make verify` が長い] → 570 秒で打ち切り、reason に明記。プロダクト側で `verify` を速い部分集合にするのは repo の判断
- [Stop の block でエージェントが同じ失敗を繰り返す] → `stop_hook_active` で 2 回目は通す。修正手順は `verify` スキルに書く
- [状態ディレクトリが肥大化] → セッション単位のディレクトリ。掃除は `doctor` の警告で後追い（本 change では対象外）

## Migration Plan

hooks.json に追加するだけ。問題があれば Stop の行を外す。
