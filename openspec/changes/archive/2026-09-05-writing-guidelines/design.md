## Context

- textlint はプリセットを global の `node_modules` から解決する。global に入れた textlint と同じ場所にプリセットがあれば `--config` で任意の設定ファイルを指せる
- 試走（2026-09-05）: 生きている文書（README、ADR、main specs）に 2 つのプリセットを掛けると 70 件の指摘が出た。うち 57 件は `sentence-length`（100 字）
- `docs/proposal-2026-09.md` と archive は記録なので対象外にする
- ja-technical-writing の `sentence-length` は英語にも掛かる（英語の SKILL.md で誤検知する）。hook は日本語を含むファイルだけを対象にする
- agent-style は npm パッケージに `RULES.md` と `rule-pack-compact.md` を同梱する。CLI は `agent-style rules` と `agent-style review --audit-only`
- `enable` は CLAUDE.md へ追記するので使わない。ユーザー層 CLAUDE.md はハーネスが管理する
- hook の非対話シェルからは mise の shims を解決できないことがある。verify-gate と同じく、スクリプト内で PATH に足す

## Goals / Non-Goals

**Goals:**
- 日本語 Markdown を書くたびに textlint の指摘が返り、直さないまま終えにくくする
- 設定はハーネスに 1 つ。プロダクト repo に新しいファイルを増やさない

**Non-Goals:**
- 英語文章の hook（agent-style の監査はスキルから手で呼ぶ。SKILL.md などエージェント向け文書に掛かると誤検知が多い）
- textlint の MCP サーバ化
- 文体基準の確定（grilling で決める。スキルには暫定基準）

## Decisions

1. **設定は `skills/ja-writing/textlintrc.json`**。指針（SKILL.md）とセンサー（設定）を同じディレクトリに置き、hook と `make verify` の両方がこの 1 ファイルを参照する。`.textlintrc` を `templates/repo/` に置く案（ADR-0001 §12.2 の木）は「プロダクト repo に置くのは 5 点だけ」の制約に反するので採らない
2. **プリセットは既定値のまま**。`sentence-length` を緩める案は退け、既存文書は文を分けて直す。インラインコードを除外する `exclusionPatterns` は試したが指摘が増えた（文の分割位置が変わる）ので使わない
3. **日本語判定は UTF-8 のバイト列**（`E3 81`〜`E3 83` = ひらがな・カタカナ）。ロケールに依存しない。漢字だけのファイルは対象外だが実害は無い
4. **hook は block しない**。指摘は `additionalContext` で返し、直すかどうかはエージェントとユーザー層の指示に委ねる。書き込みを止めると仕様書の下書きが進まない
5. `sync` の npm global 導入を汎用化する。
   `deps.json` の `clis` を `package` / `version` / `bin` / `bundle` の形に揃える。
   1 つのループで openspec、textlint、agent-style、design.md を扱う。
   版の確認は `npm root -g` 配下の `package.json` を jq で読む（`npm ls -g` より速い）。
   導入後に `mise reshim` を呼び、shims に bin を載せる
6. `make verify` の対象は生きている文書に限る。
   対象は README、`docs/adr/`、`openspec/specs/`、進行中の `openspec/changes/`。
   `docs/proposal-2026-09.md` と `openspec/changes/archive/` は記録なので掛けない
7. **agent-style は CLI として global に入れる**（`clis`）。同梱の `style-review` スキルはプロジェクト内 `.agent-style/RULES.md` を前提にするので使わず、`en-writing` が CLI を直接呼ぶ

## Risks / Trade-offs

- [textlint の指摘が多くて作業が止まる] → 生きている文書は本 change で直す。hook は 20 行で打ち切り、全文は再実行で見る
- [プリセットの更新で指摘が増える] → 版は `deps.json` でピン。更新は意図的に行う
- [global npm が mise の Node 更新で消える] → `doctor` が版の不一致を警告し、`sync` が入れ直す

## Migration Plan

`hooks.json` に PostToolUse を足し、`sync` を実行するだけ。問題があれば PostToolUse の行を外すか `USKN_SKIP_TEXTLINT=1`。
