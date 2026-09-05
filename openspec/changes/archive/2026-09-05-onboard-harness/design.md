## Context

- monolith: Expo + Supabase のアプリ。`AGENTS.md` は 262 行あり、コマンド一覧や React の一般論を含む
- monolith の `CLAUDE.md` は nvm 前提のプレフィックスを求める。`openspec/` と Makefile は存在しない
- monolith にテストは無く、lint は `expo lint`。`tsconfig` の `strict` は true で TypeScript 5.9 が入る
- monolith の `docs/DESIGN.md` はシステム設計の文書で、視覚の DESIGN.md とは別物
- monolith の default ブランチは `master`。GitHub Actions は無い
- uskn75-kb: ハードウェア設計の資料 repo。ビルドとテストと CI を持たない
- uskn75-kb の正本は `CLAUDE.md` で、`AGENTS.md` は存在しない。設計制約と生成物の扱いが濃く書かれている
- uskn75-kb の `python3 tools/gen-layout.py` は、仕様と配列が食い違うと落ちる
- ハーネス側の制約: 作業ディレクトリ外は編集しない。他 repo への変更は別クローンからの PR か handoff 文書

## Goals / Non-Goals

**Goals:**
- repo の性質から「置くもの」を決める手順を 1 か所に置く
- 導入状態を読み取り専用で点検できるようにする
- monolith と uskn75-kb に、いつでもマージできる draft PR を残す

**Non-Goals:**
- 既存 AGENTS.md の実際の圧縮（PR を受けたセッションでユーザーと行う）
- DESIGN.md のトークンの確定（書体と spacing はユーザーの決定）
- dotfiles への導入

## Decisions

1. onboard は installer ではなくスキルが主で、`onboard-check` は点検だけを持つ。
   配置には判断（何を残し何を削るか）が要るので、機械化できるのは点検の側だけ。
2. UI の判定は `package.json` の依存で行う。`react`、`react-native`、`expo`、`vue`、`svelte`、`next` のいずれかがあれば UI ありとする。
   `app.json` の有無や画面ディレクトリの名前より安定して読める。
3. `onboard-check` は `doctor` と同じ出力形式（`ok` / `warn` の行）を使う。
   ただし終了コードは常に 0 とする。未導入を異常として扱わず、これから導入する状態と見るため。
4. `templates/repo/Makefile` は各チェックを `command -v` で囲む。
   道具が入っていない環境でも `make verify` が通ることを、ハーネス自身の Makefile と揃える。
5. monolith の verify は `expo lint` と `tsc --noEmit` の 2 つ。
   テストが無いので「テストを追加する」ことは verify の前提にしない。追加は別の change。
6. uskn75-kb の verify は `python3 tools/gen-layout.py`。
   既に仕様と配列の突合として機能しており、新しい検査を発明しない。
7. draft PR の中身は機械的に置けるものに限る。
   AGENTS.md 本体の圧縮を PR に含めると、レビューが「ハーネス導入の可否」ではなく「文章の是非」になる。

## Risks / Trade-offs

- [monolith の feature ブランチと衝突する] → 触るのは新規ファイルと Makefile だけ。既存の AGENTS.md は Branch model 節の追記にとどめる
- [draft PR が長く放置される] → 手順書を PR 本文に持たせ、時間が経っても単体で読めるようにする。同じ内容を `docs/handoffs/` にも残す
- [`onboard-check` の UI 判定が外れる] → 判定は報告の内容が変わるだけで、書き込みには影響しない

## Migration Plan

スキルと `onboard-check` はハーネス内で完結する。プロダクト repo 側は draft PR のマージで入り、取り消しは PR を閉じるだけ。
