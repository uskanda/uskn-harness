# ADR-0004: セッションjournalを廃止する

- 状態：採用（2026-09-25）。ADR-0001 §10（履歴）と、§7のjournalに関わる行を差し替える
- 決定者：uskanda（change `retire-session-journal` のgrilling第1ラウンド。/okで確認）

## 文脈

ADR-0001 §10は、セッションごとの要約（journal）をsessionsリポジトリに貯める形を決めた。
コミットには `Session:` トレーラを付け、`recall` で当時のjournalを引く。
2026-09-14には、sessionsリポジトリを端末ごとのローカルgitに閉じた（change `journal-local-only`）。
2026-09-25時点の状況は次のとおり。

- 決定の記録は、変更ごとの `grilling.md` と `design.md`、ADR、コミットに残る。journalの決定欄はその写しになる
- journalは端末ごとに閉じていて、ほかの端末からは引けない
- 仕組みの維持に、Stop hookのblock、トランスクリプトの解析、SessionEndのcommit、sessionsリポジトリの管理が要る
- デスクトップアプリでは、SessionEndはアプリがセッションを閉じるまで走らない
- 好みや指摘は、Claude Codeのauto memoryが覚える

## 決定

1. セッションjournalの仕組みを廃止する。
   `journal` と `recall` のスキル、hookのjournal-recent.sh、journal-update.sh、journal-end.shを削除する。
   `sync` によるsessionsリポジトリの管理も外す
2. 代わりの仕組みは作らない。決定はOpenSpecのアーカイブ（`grilling.md`、`design.md`）、ADR、コミットに残す。好みの記録はauto memoryに任せる
3. `commit` はSessionトレーラを付けない。既存のコミットのトレーラはそのまま残す。代わりに、常に `Co-Authored-By: Claude <noreply@anthropic.com>` を付ける
4. `<repo-context>` にsession行を出さない。セッションIDが要るスキルは `${CLAUDE_SESSION_ID}` を使う。置換されないときは環境変数 `CLAUDE_CODE_SESSION_ID` を読む
5. 各端末の `~/.ai-sessions` には触れない。`sync` は作らず、`doctor` は検査しない。ガードの許可リストからも外す。消すかはユーザーが決める
6. 状態ディレクトリには、hookが読むファイルだけを書く。30日より長く更新されていないセッションのディレクトリは `sync` が消す

ADR-0001 §7の表のうち、差し替える行は次のとおり。ほかの行はそのまま。

| イベント | 役割 |
|---|---|
| SessionStart | hosting（GitHub / GitLab）とブランチモデル（既定・統合・QA）を判定して注入。作業ツリーの指紋を記録 |
| PreToolUse Write / Edit / NotebookEdit | プロジェクトルート外を拒否。許可リストは scratchpad、`~/.claude/projects/*/memory`、`/tmp`、ハーネスの状態ディレクトリ。`/allow-repo <path>` でセッション限定に解除 |
| Stop | 作業ツリーに変更があれば verify。緊急回避は環境変数 1 つ |
| SessionEnd | 使わない |

## 結果

- 良い点：hookが3本、スキルが2つ減る。Stopでblockするのはverify gateだけになる。インストーラは端末ごとのgitリポジトリを管理しなくてよい
- 引き受けるコスト：セッション単位の要約は残らず、コミットからセッションへは辿れない。過去の決定は `openspec/changes/archive/` と `docs/adr/` を検索して探す
- 後回し：既存のjournalの削除。端末ごとにユーザーが決める
