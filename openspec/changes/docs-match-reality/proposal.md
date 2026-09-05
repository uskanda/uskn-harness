## Why

ADR-0002 で Claude 向け hook の配布を skills-dir プラグインに変えたとき、構成を説明する文書が追随しなかった。
AGENTS.md の Layout、ADR-0001 §3 と §7、プラグイン README、proposal §12.2 が存在しないパスを指している。
該当は `hooks/scripts/`、`hooks/adapters/`、`docs/trends/`、`docs/principles.md`、`docs/portability-matrix.md` の 5 つ。
逆に、追跡されている `templates/chezmoi/` はどの表にも載っていない。
前セッションの引き継ぎ文書はこのずれの調査に時間を使った。単一の情報源を保つのはハーネスの原則の 1 つで、放置すると次のセッションも同じ調査を繰り返す。

## What Changes

- AGENTS.md の Layout: `hooks/scripts/`・`hooks/adapters/` の行を消す。`plugins/uskn-harness/` の行に hook 本体（scripts、tests、hooks.json）があると書く。`templates/` の行に `templates/chezmoi/` を足す
- ADR-0001 §3: hook の置き場を `plugins/uskn-harness/hooks/` に直す。アダプタは必要が出た時点で `hooks/adapters/<tool>/` に置くと書く（ADR-0002）。`docs/{adr,handoffs,trends}` から trends を消し、`templates/chezmoi/` を足す
- ADR-0001 §7: Stop の行に journal の骨格生成と更新を、SessionEnd の行に最終更新と commit・push を書く
- プラグイン README: アダプタの文を「他ツールは `~/.local/share/uskn-harness` 経由で同じスクリプトを呼ぶ。まだ無い」に直す
- proposal §12.2: 冒頭に「現状の構成は AGENTS.md の Layout を正とする」と注記する。`docs/` の行から `principles.md`、`portability-matrix.md`、`trends/` を消す。他の行は記録として残す
- ローカルにだけある空ディレクトリ `hooks/` と `docs/trends/` を削除する

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

なし。文書だけの変更で振る舞いは変わらないため、`.openspec.yaml` に `skip_specs: true` を置く。

## Impact

- 変更: `AGENTS.md`、ADR-0001、プラグイン README、`docs/proposal-2026-09.md`
- 削除: ローカルの空ディレクトリ 2 つ。git は未追跡なので履歴には影響しない
- コードと hook の振る舞いは変わらない。`make verify` の textlint が ADR を検査する。英語の AGENTS.md とプラグイン README は対象外
