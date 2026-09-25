## Context

動機はproposal.mdのWhyにある。ここでは形を決める前提だけを書く。

- `templates/user/CLAUDE.md` は `uskn-harness sync` が `~/.claude/CLAUDE.md` に置き、すべてのセッションで読まれる。このリポジトリの `AGENTS.md` も、ここでのセッションでは毎回読まれる。
- モデルから起動できるスキルの `description` は、スキルの一覧として毎ターン文脈に入る。`disable-model-invocation: true` を持つスキルの `description` は文脈に入らない。そのスキルはSkillツールからも起動できない（code.claude.com/docs/en/skills）。
- `argument-hint` は、`/` で始まるコマンドの入力補完に出る。スキルの一覧には入らない。引数の詳しい意味は、各スキルの本文がすでに持つ。
- Stop hookの `verify-gate` は、作業ツリーが変わったセッションで検証規約を実行し、失敗の間は終了させない。textlint hookの返す文は「直してから終える」ことを伝える。grilling guardの拒否理由は、grillingを先に済ませることと `no-grilling` を伝える。
- SessionStart hookの `<repo-context>` は、自分の値をスキルで使い、検出し直さないよう自ら書いている。
- 方法論スキルの2つは、superpowers v6.3.0から取り込んだ。本文はIron Law、言い訳の表、Red Flags、大文字の強調で振る舞いを縛る書き方をしている。
- 並行する変更が2つある。`hook-native-features` はgitスキルの本文と `plugins/uskn-harness/bin/` を、`deps-real-pinning` は `deps.json` のピンを変える。この変更はgitスキルのfrontmatterと、`deps.json` の `forks` の2項目だけに触れる。

## Goals / Non-Goals

**Goals:**

- 常に読み込まれる文（ユーザー層の `CLAUDE.md`、`AGENTS.md`、モデルが読む説明文）を、環境やhookが伝えない規則と導線だけにする。
- 完了前の検証を促す文を、verify gateが強制する範囲から外す。
- 方法論スキルを、とるべき手順を肯定形で書いた文書にする。
- 説明文の長さと、ユーザーだけが起動するスキルの呼び出しを、batsのテストで確かめる。

**Non-Goals:**

- hook、`hooks.json`、`bin/uskn-harness`、`Makefile` の変更。
- gitスキル、`ui-guidelines`、`en-writing` の本文の変更。frontmatterだけを変える。
- dotfiles側のスキルの説明文と、Claude Codeのsettingsのeffort。grilling.mdの後回しの項目にある。
- `verify` スキルの本文にある「完了の根拠」の規則。`retire-obsolete-skills` の第1ラウンドQ9で決まったもので、この変更では触れない。

## Decisions

### 1. ユーザー層の CLAUDE.md は見出しの無い1段の箇条書き

各行の先頭に短い見出し語を置く。見出し語はLanguage、Planning、Approval、Boundaries、Verify convention、Tests、Writing、UI、Earlier decisionsの9つ。
見出し語が、その行を読む条件になる。
節の見出しは、行数が少ないので要らない。

残した行と理由は次のとおり。

- Verify convention：検証規約の1行と、`verify-gate` がそれを実行すること。「完了前に実行せよ」の代わりに、gateが実行すると知らせる。モデルが自分でも実行する回数が減る。
- Boundaries：`/allow-repo` は `disable-model-invocation` を持つので、「ユーザーが実行する」と書く。以前の「you run `/allow-repo`」は、モデルが起動できない指示だった。
- Approval：`ok` スキルは直前の返答から「次の入力」を1つ探す。提案の終わりに次の入力を1つ名指しするよう、この行で伝える。
- Earlier decisions：`retire-session-journal` が `recall` の代わりに置いた行。アーカイブを探す習慣は環境から分からないので残す。

消した行と、代わりに伝えるものは次のとおり。

| 消した記述 | 代わりに伝えるもの |
|---|---|
| `<repo-context>` の説明 | ブロック自身の1行目 |
| gitスキルの一覧 | スキルの一覧 |
| `/archive-push` の説明と「ユーザーだけが始める」 | `disable-model-invocation` |
| grillingの無い変更への書き込みの禁止 | grilling guardの拒否理由と `spec` スキル |
| 完了前の検証とその根拠の示し方 | `verify-gate` と `verify` スキル |
| `systematic-debugging` への導線 | そのスキルの説明文 |
| ネイティブのworktreeの説明 | Claude Codeのworktreeの機能 |
| textlintの指摘を直すこと | textlint hookの返す文 |
| ImpeccableのinitとDESIGN.mdの形式 | `ui-guidelines` の本文 |

大きさのセンサーは、既存のbatsのテストに2,000バイトの上限を足して作る。60行の上限は、1行が長いと効かない。60行のScenarioは既存のspecにあるので残す。

代案として、節の見出しを残す形も考えた。見出しの分だけバイトが増え、読む条件は見出し語で足りるので採らない。

### 2. AGENTS.md はこのリポジトリに固有のことだけ

「How work happens here」は、batsのテストを先に書くこと、スキルに実例を載せること、CIが `VERIFY_STRICT=1` で走ることの3つにする。
Language節とClaude Code節は消す。言語はユーザー層が持ち、OpenSpecの置き場はLayoutの `openspec/` の行が持つ。
hard constraintから、作業ディレクトリ外の編集の禁止を消す。ユーザー層の境界の行とwrite guardが持つ。

Layoutの `plugins/uskn-harness/` の行は「hookの本体、`hooks.json`、そのbatsのテスト、スキルが呼ぶ短いコマンド」と書く。
`hook-native-features` がマージされる前と後のどちらでも正しい書き方にするため。
`bin/` の行は、インストーラ `bin/uskn-harness` と、それとスキルのfrontmatterを確かめるbatsのテストを書く。

### 3. 方法論スキルは、構成を残して言い方を替える

見出しの並び、RED・GREEN・REFACTORの例、Good Tests、When Stuck、デバッグの4つの段階、参照ファイルへの導線、Harness Notesは残す。
消すのはIron Law、言い訳の表、Red Flags、「MANDATORY」、Final Rule、完了前の確認の一覧、TDDの状態遷移図。

禁止で縛っていた箇所は、代わりの手順を書く。

- 「Delete means delete」は「テストより先に書いたコードは下書き。脇に置き、テストを書いて失敗を見てから、テストから実装する」にする。
- 「STOP. Return to Phase 1」の一覧は、Phase 1へ戻る合図を1段落にまとめる。合図は修正が効かないとき、修正のたびに別の場所で問題が出るとき、ユーザーが推測をやめるよう言ったとき。
- 3回の修正で直らないときに設計を疑い、ユーザーと相談する手順は残す。

Verify GREENは、触ったテストのファイルとその周りを実行する段にする。
検証規約の全体の実行は、RED・GREEN・REFACTORの1回りごとには求めない。`verify-gate` が作業の終わりに実行するとHarness Notesに書く。
以前のHarness Notesは「All tests pass」を検証規約と読み替えていて、1回りごとに `make verify` を走らせる形だった。

参照ファイルは、本文と同じ言い方を繰り返す箇所だけを直す。
`root-cause-tracing.md` の「NEVER fix just the symptom」と、`defense-in-depth.md` の大文字の「EVERY」が該当する。
`writing-good-tests.md` は具体的な規則だけなので、変えない。

`deps.json` の `forks` の2項目には、`diverged`（分岐した日）と `note`（Opus 5.x向けに書き直し、再取り込みしない）を足す。`changes` にも1行足す。

代案として、上流の最新版を取り込み直す形も考えた。上流は同じ書き方を保っているので、取り込むたびに書き直しが要る。grilling.mdのQ14で分岐を選んだ。

### 4. 説明文は用途を先頭に、200文字以内

1つの分岐に1つの起動条件を書き、同じ分岐の言い換えは1つにまとめる。
本文が持つ説明（`pr` の引数ごとの動き、`sync-base` がrebaseしないこと、`en-writing` がhumanizerを使うこと）は説明文から外す。

`verify` の説明文からは「Use before calling work done, fixed, or passing」を外す。
Q12で、完了前の検証はgateに任せると決めたため。起動条件は、gateが止めたとき、PRを開く前、検証を頼まれたときの3つにする。

`argument-hint` の値は、YAMLの文字列として引用符で囲む。
`[issue-id]` を引用符無しで書くと、YAMLでは配列になる。`make verify` のfrontmatterの検査はYAMLとして読むので、文字列にそろえる。

上限は、`description` と `when_to_use` を合わせた長さに掛ける。スキルの一覧には2つを合わせた文が入るため。

`disable-model-invocation` を持つスキルの説明文は、人が `/` の候補の一覧で読む1行にする。起動条件の列挙は外す。

### 5. 5つのスキルはユーザーだけが起動する

`rebase`、`cleanup-merged`、`release`、`onboard-harness`、`audit-writing` は、ユーザーが自分で始める作業なので、説明文を文脈から外す。
`pr`、`sync-base`、`switch-base` は、ユーザーが自然な言葉で頼むことが多いので残す（Q16）。

別のスキルがSkillツールでこの5つを呼ぶ箇所は無い。
`commit` の本文は「コミットの整理は `rebase` の役目」と書くが、呼び出しではない。
`ok` スキルは、次の入力が起動できないスキルなら、ユーザーに打つよう頼む。

### 6. センサーは新しいbatsファイル

`bin/tests/skill-invocation.bats` を足す。確かめるのは3つ。

- モデルから起動できるスキルの説明文が200文字以内であること。frontmatterはpython3とPyYAMLで読む。`make verify` のfrontmatterの検査と同じ読み方。
- 本文が `$ARGUMENTS` を使うか、引数の見出しを持つスキルが `argument-hint` を持つこと。
- `Run the Skill tool with` と `with the Skill tool` の形で名指しされたスキルが、`disable-model-invocation` を持たないこと。

`Makefile` は `bin/tests` の下のbatsをすべて実行するので、`Makefile` は変えない。
方法論スキルの本文に禁止語が無いことは、テストにしない。`writing-good-tests.md` の「本文の文字を検索するテストは書かない」に従う。

## Risks / Trade-offs

- 5つのスキルを、モデルが自分で勧めなくなる → `ok` スキルが、起動できないスキルの入力をユーザーに頼む。onboard-skillとaudit-writing-skillのScenarioで、入力を勧めることを定める。
- `verify` の説明文から完了前の起動条件を外すと、検証結果を示さずに完了と報告する場面が増える → 検証の失敗中はgateが終了を止める。失敗したまま終わることは無い。
  `verify-skill` の「完了の根拠」は、完了の報告に同じターンの実行結果を求めている。これをgateに合わせて狭めるかは、この変更では決めない。
- 説明文を短くしたことで、起動の取りこぼしが出る → 分岐ごとの起動条件は残した。取りこぼしが見つかったら、その分岐の語を説明文に戻す。
- 方法論スキルが上流から離れ、上流の改善が届かない → `deps.json` に分岐を記録した。上流の改善は、読んだうえで個別に本文へ移す。
- `AGENTS.md` から作業ディレクトリ外の禁止を消すと、ユーザー層を持たないエージェントに伝わらない → ADR-0001の2節で、動作を保証するのはClaude Codeだけ。write guardとbash guardも止める。
- 並行する変更と同じファイル（gitスキル、`bin/tests/uskn-harness.bats`）に触れる → gitスキルはfrontmatterだけを変える。`uskn-harness.bats` は1つのテストの1行だけを変え、衝突の範囲を狭める。

## Migration Plan

1. このブランチをmainへ統合する。スキルはsymlinkで配っているので、frontmatterの変更はすぐ効く。
2. 各マシンで `uskn-harness sync` を実行し、`~/.claude/CLAUDE.md` を入れ替える。
3. 戻すときは、この変更のコミットをrevertして `sync` を実行する。

## 測定

モデルが読む説明文の文字数は、`disable-model-invocation` を持たないスキルの `description` の合計。

| 対象 | 変更前 | 変更後 |
|---|---|---|
| モデルが読む説明文の合計 | 19スキル、5,194文字 | 測定待ち |
| `skills/test-driven-development/SKILL.md` | 333行、9,834バイト | 測定待ち |
| `skills/systematic-debugging/SKILL.md` | 287行、9,719バイト | 測定待ち |
| `templates/user/CLAUDE.md` | 39行、3,595バイト | 測定待ち |
| `AGENTS.md` | 64行、3,406バイト | 測定待ち |
