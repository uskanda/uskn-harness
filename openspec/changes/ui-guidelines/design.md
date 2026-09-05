## Context

- Google DESIGN.md（`@google/design.md` 0.4.0、alpha）は 2 層。YAML front matter のトークンは colors、typography、rounded、spacing、components
- `##` 節の順序は Overview、Colors、Typography、Layout、Elevation & Depth、Shapes、Components、Do's and Don'ts
- `lint` は broken-ref をエラー、primary 欠落や contrast を警告にする
- Impeccable 4.0.1（npm、スキルは 4.2.0）: 1 スキル 23 コマンド。`context` が PRODUCT.md と DESIGN.md を読む。`init` は PRODUCT.md、`document` / `extract` は独自形式の DESIGN.md を書く。PRODUCT.md は `<!-- impeccable:product-schema 1 -->` 付きの Markdown で節名だけが契約
- Impeccable の導入は `npx impeccable install -y --providers=claude --scope=global --no-hooks` で非対話。hook（UI ファイル編集後の検出器）はプロジェクトの設定に書き込むので入れない
- frontend-design は Anthropic 公式 marketplace の plugin。中身は SKILL.md 1 つ（Web の新規 UI 向け）。`skills` CLI で monorepo からスキル名指定で入れられる

## Goals / Non-Goals

**Goals:**
- DESIGN.md / PRODUCT.md を書く・読む・確認する手順を 1 スキルにまとめる
- テンプレートに計算的センサー（lint）を付ける

**Non-Goals:**
- Impeccable の hook（検出器）の導入
- Expo 公式 skills の global 導入（プロジェクト単位、Phase 4）
- DESIGN.md から Tailwind などへの export の運用

## Decisions

1. **PRODUCT.md は Impeccable の節構成をそのまま使う**。形式は Markdown の節見出しだけなので Google 形式と衝突しない。`init` を使わない代わりにテンプレートで同じ節を用意する
2. **DESIGN.md テンプレートは lint を通る最小の実例**。プレースホルダの色や書体を入れ、`primary` と components を含めて `missing-primary` / `orphaned-tokens` の警告も出ない形にする。prose は「何を書くか」の案内
3. **Impeccable は `skills` として導入**（`clis` から移す）。届く物がスキルであり、`ensure_third_party` の「無いときだけ入れる」で扱える
4. **frontend-design は `skills` CLI で参照導入**。Claude の marketplace 経由より tool 非依存で、他の参照スキルと同じ経路
5. **`@google/design.md` は `clis` に入れ、bin は `designmd`**（`design.md` という名前は Windows で衝突する）
6. **`make verify` の `verify-design` はテンプレートだけを対象**。プロダクト repo の DESIGN.md は各 repo の `verify` に `designmd lint DESIGN.md` を足す（Phase 4 の onboard で提案）

## Risks / Trade-offs

- [Impeccable の `context` が Google 形式の DESIGN.md を「古い」と判定する] → 判定は報告だけで書き換えない（Impeccable の設計）。`doctor` / `document` を使わないことをスキルに明記
- [DESIGN.md 仕様が alpha で変わる] → `deps.json` でピン、`lint` の失敗で気付く
- [Impeccable の launcher が初回にバイナリを取得する] → `sync` 時ではなく初回コマンド時。オフラインなら失敗するだけ
