# ADR-0003: 指示ファイルはAGENTS.mdだけにする

- 状態：採用（2026-09-25）。ADR-0001 §1.3と§5のうち、`CLAUDE.md` を置くという記述を差し替える
- 決定者：uskanda（`agents-md-only` のgrillingと、2026-09-25の確認）

## 文脈

ADR-0001では、各リポジトリに `@AGENTS.md` とClaude固有の数行だけを持つ `CLAUDE.md` を置いていた。
当時のClaude Codeは `AGENTS.md` を読まなかったため、`CLAUDE.md` から取り込ませる必要があった。

Claude Codeはv2.1.277から、`CLAUDE.md` の無いプロジェクトで `AGENTS.md` を読む。
v2.1.281からは、Amazon Bedrock、Google Vertex AI、Microsoft Foundry、LLM gateway、telemetryを無効にしたセッションでも読む。
出典は[Claude Codeの公式文書](https://code.claude.com/docs/en/memory#agents-md)とCHANGELOGで、2026-09-25に確かめた。

読むファイルを決める既定の設定は `claude-md-or-agents-md` である。
作業ディレクトリか上位に `CLAUDE.md`、`.claude/CLAUDE.md`、`CLAUDE.local.md` のどれかがあると、`AGENTS.md` は読まれない。
`~/.claude/CLAUDE.md` と組織が管理する `CLAUDE.md` はこの判定に数えず、どちらも `AGENTS.md` と並んで読まれる。

## 決定

1. 指示ファイルは `AGENTS.md` だけにする。プロダクトリポジトリとこのリポジトリのどちらにも、`CLAUDE.md` は置かない。
   `templates/repo/CLAUDE.md` は削除し、`onboard-harness` は `CLAUDE.md` を作らない
2. Claudeだけに適用される記述は、`AGENTS.md` の任意の `## Claude Code` 節に書く
3. `AGENTS.md` が無く `CLAUDE.md` が正本の既存リポジトリでは、導入のときに中身を `AGENTS.md` へ移し、`CLAUDE.md` を削除する
4. `@AGENTS.md` を取り込む既存の `CLAUDE.md` には触らない
5. Claude Codeの最低版を2.1.281とし、`deps.json` の `runtimes.claude-code.min_version` に書く。
   接続先やtelemetryの設定によらず `AGENTS.md` が読まれる最初の版だから。
   `doctor` はPATHの `claude` とVS Code拡張の版をそれぞれ比べ、古いものごとに `warn` を出す
6. 最低版は下限であり、ハーネスはClaude Codeの版を縛らない。最新版の利用を妨げない。
   `sync` はClaude Codeをインストールせず、版のピンもしない。CIは版を指定せずに最新版を入れる
7. `onboard-check` は、`CLAUDE.md` の無い状態を `ok` とする。
   `@AGENTS.md` を取り込まない `CLAUDE.md` と `.claude/CLAUDE.md` には `warn` を出す。
   `CLAUDE.md` も `.claude/CLAUDE.md` も無いリポジトリの `CLAUDE.local.md` にも `warn` を出し、直し方を示す

## 結果

- 良い点：指示ファイルが1つになり、Claude Codeと他のエージェントが同じファイルを読む。
  `@AGENTS.md` の1行だけの `CLAUDE.md` を、リポジトリごとに保つ手間が無くなる
- `AGENTS.md` が読まれない条件：版が2.1.277より古いとき。Bedrock、Vertex、Foundry、LLM gateway、telemetry無効のセッションでは、2.1.281より古いとき
- `AGENTS.md` が読まれない条件：組み込みの `agents-md` プラグインを `/plugin` で無効にしたとき。
  v2.1.276以前から更新した直後の最初のセッションでも、読まれないことがある
- `AGENTS.md` が読まれない条件：作業ディレクトリか上位に `CLAUDE.md`、`.claude/CLAUDE.md`、`CLAUDE.local.md` のどれかがあるとき
- 回避策：一時的な `CLAUDE.md` に `@AGENTS.md` の1行を書く。この決定を戻すときも同じ1行で元の動きになる
- 回避策：`CLAUDE.local.md` を使い続ける人は、ユーザー層の設定で `instructionFiles` を `claude-md-and-agents-md` にする。
  `/config` のProject instructionsで変えられ、設定ファイルでは `pluginConfigs["agents-md@builtin"].options.instructionFiles` に書く。
  この値が有効になるのは `~/.claude/settings.json` などユーザー層の設定だけで、プロジェクトとlocalの設定ファイルでは無視される。
  ハーネスはこの設定を入れない
- 既存リポジトリの `CLAUDE.md` を触らない根拠：`@AGENTS.md` だけを持つ `CLAUDE.md` は、残しても `AGENTS.md` を2度読ませない。
  公式文書は、残してもよく、中身がそれだけなら消してもよいと案内している
- 引き受けるコスト：古いClaude Codeのマシンでは、新しいリポジトリの指示が何も読まれない。`doctor` の `warn` で気づく。
  更新直後の最初のセッションで読まれない件は、`doctor` では検知できない
- 後回し：`disableAllHooks` を指定したスキル評価で `AGENTS.md` が読まれるかは、評価の手順を文書にする段階で確かめる
