## Why

ADR-0001 §11 は UI の正本を Google DESIGN.md 形式とし、Impeccable はコマンドだけ使うと決めた。
一方で指針スキルも、DESIGN.md と PRODUCT.md のテンプレートもまだ無い。
Phase 4 でプロダクト repo へ入る前に、UI 作業の入口を用意する。
テンプレートには計算的センサーとして `design.md lint` を付ける。

## What Changes

- `ui-guidelines` スキルを追加する。DESIGN.md（Google 形式）と PRODUCT.md を正本にする手順を書く
- スキルには Impeccable のコマンドの使い分け、RN / Expo の補い方、frontend-design へのフォールバック、`design.md lint` による確認も書く。`init` / `document` / `extract` は使わない
- `templates/repo/DESIGN.md` を追加する。Google 形式で、`design.md lint` のエラーは 0
- `templates/repo/PRODUCT.md` を追加する。節構成は Impeccable が読むものに合わせる
- `uskn-harness sync` が Impeccable と frontend-design のスキルを参照導入する。`@google/design.md` CLI もピンで global に入れる。`doctor` が確認する
- `make verify` に `verify-design`（テンプレートの lint）を足す
- ユーザー層 `CLAUDE.md` に UI の 1 行を足す

## Capabilities

### New Capabilities
- `ui-guidelines-skill`: UI 作業の入口スキル（正本、コマンドの使い分け、lint）
- `design-templates`: プロダクト repo に置く DESIGN.md と PRODUCT.md のテンプレート

### Modified Capabilities
- `harness-sync`: 参照スキル（impeccable、frontend-design）と `@google/design.md` の導入
- `user-layer-instructions`: UI の指針への導線

## Impact

- 新規: `skills/ui-guidelines/SKILL.md`、`templates/repo/DESIGN.md`、`templates/repo/PRODUCT.md`
- 変更: `deps.json`、`bin/uskn-harness` と bats、`Makefile`、`templates/user/CLAUDE.md`、README
- `deps.json` では impeccable を skills へ、designmd を clis へ移し、frontend-design に install を足す
- Impeccable の launcher は初回実行時に `~/.impeccable/bin/` へバイナリを取得する（ネットワーク）
