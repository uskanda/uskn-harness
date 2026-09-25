## Context

動機はproposal.mdのWhyにある。Claude Code 2.1.270で、使い捨てのスキルを使って次の挙動を確かめた。

- インラインの `effort:` はスキルに入った時点で効き、ターンの終わりまで残る。変わった時点で会話部分のキャッシュが作り直される
- インラインの `model:` は、`claude -p` ではモデルの案内の文だけが変わり、APIの呼び出しは元のモデルのままだった
- forkでは `model:` と `effort:` が効き、会話の文脈を持たない。ユーザーが直接打ったforkのスキルでは、本体のモデルは動かない
- `background` を書かないと、forkのスキルの完了を呼び出し側は待たない。`false` にすると結果を待つ
- haikuにはeffortが渡らない。hookの入力の `effort` は `null` だった
- forkした先でも、`${CLAUDE_SESSION_ID}` と環境変数 `CLAUDE_CODE_SESSION_ID` は親セッションのIDになる
- forkした先には `<repo-context>` が届かない。`switch-base` と `sync-base` は、無いときに `session-start.sh --json` で補う手順をすでに持つ

スキルは `uskn-harness sync` がsymlinkで配る。作業ツリーを編集すると、その時点からこのマシンのすべてのセッションに効く。

## Goals / Non-Goals

**Goals:**

- forkにしたスキルの費用が、呼び出した会話の長さで変わらない形にする
- forkとインラインの規則を、batsのテストで保つ

**Non-Goals:**

- grilling.mdで後回しにしたもの（prとrelease、fix-ciとpre-merge、インラインのスキルのeffort）
- プロンプトごとに難度を推定してeffortを変える仕組み。UserPromptSubmit hookの出力にはeffortを変える項目が無い

## Decisions

### commitはsonnetで動かす

過去のコミットを未コミットに戻し、会話の文脈なしで2つの状態を再現した。
1つは3つの変更が混ざった状態で、もう1つは1つの変更で19ファイルの状態である。
haikuはどちらも5コミットに分けた。ファイルの種類で分け、内容と合わない要約行を書いた。
sonnetは目的ごとに分け、メッセージも差分と合っていた。費用は1回$0.51〜$0.66で、現状の中央値$0.91を下回る。
opusは費用が下がらないので採らない。

### 呼び出し側の指示は引数で渡す

forkした `commit` が読めるのは引数だけなので、`archive-push` の指示を引数の文にする。
`archive-push` が自分で `git commit` する案は採らない。分割の規則とtextlintの手順が2か所に分かれるためである。

### Session trailerは置換変数から作る

スキル本文に `${CLAUDE_SESSION_ID}` を書き、読み込み時に置換された値の先頭8文字を使う。
置換されずに文字のまま残ったときは、Bashで環境変数 `CLAUDE_CODE_SESSION_ID` を読む。どちらも無ければ付けない。

### switch-baseとsync-baseはインラインのまま

`recall` も一度sonnetのforkにして評価し、journalの決定だけを引用することを確かめた。
ただし2026-09-25にjournalの仕組みを廃止すると決めたので、この変更の対象から外し、frontmatterも元に戻した。

`switch-base` と `sync-base` は決まったgitコマンドを順に打つだけなので、haikuで足りると見込んで評価した。
結果は5つの状態すべてで崩れた。haikuのforkはスキル本文を読んだうえで、gitコマンドを1つも打たずに「頼まれたことが無い」と返すか、
コンフリクトの状態では無関係な作業をしたと報告した。対照としてsonnetで同じ状態を走らせると、3つの状態とも正しく動いた（1回$0.16〜$0.19）。
grillingで決めたモデルはhaikuなので、下の「崩れたときの扱い」に従い、2つのスキルはインラインに戻す。sonnetのforkにするかは別の変更で決める。

### 評価の方法と、崩れたときの扱い

scratchpadに作ったcloneで過去の状態を再現し、hookを切った `claude -p` から変更後のスキルを実行する。

- `commit`：前回と同じ2つの状態を再現する。目的ごとの分割、差分と合うメッセージ、trailerの値を確かめる
- `switch-base`：未コミットの変更がある場合と、fast-forwardできる場合を確かめる（haikuで崩れた）
- `sync-base`：未コミットの変更がある場合と、fast-forward、マージ、コンフリクトの場合を確かめる（haikuで崩れた）

基準を満たさないスキルはforkにせず、frontmatterを戻す。そのスキルの要件はspecの差分から外す。

### 2.1.282での再評価

Opus 5.5を既定にした2.1.282で、`commit` の評価をやり直した（2026-09-25）。
`claude -p` に `--session-id` で既知のIDを渡し、trailerが例の値ではなく実行したセッションのIDになるかも確かめた。

- 目的が1つで19ファイルの状態（c9bf949を未コミットに戻したもの）：1コミットにまとまった。$0.35
- 目的が3つの状態（e60c342からce740ddまでを未コミットに戻したもの）：最初は2コミットになった。別々のスキル2つを1コミットにまとめ、textlint用の一時ファイルの見出し記号 `# ` を要約行に残した
- スキルを直した。見出し記号は一時ファイルだけのものだと書き、共有のファイルに触れる2つの目的の例を足した。やり直すと、目的どおり3コミットに分かれ、要約行に記号は無かった。$0.40
- trailerの値は、どの実行でも渡したIDの先頭8文字と一致した

forkの `commit` はCo-Authored-Byを付けない。本体のセッションが受け取るattributionの案内は、forkした先には届かない。

### センサーは1つのbatsファイルで全スキルを走査する

`<bin/tests/skill-fork-policy.bats>` は、`skills/` 配下のすべての `SKILL.md` のfrontmatterを読む。
そのうえで `skill-fork-policy` の規則を確かめる。forkにした `commit` の期待値も同じファイルで確かめる。
既存の `bin/tests/ok-skill.bats` と同じく、frontmatterはsedで切り出す。

## Risks / Trade-offs

- 会話で話した理由がコミットメッセージに入らない → 呼び出し側は指示の文で渡せる。OpenSpecの成果物にも理由が残る
- 短い会話では、forkの固定費がインラインの費用を上回る → grillingで受け入れた
- 編集した時点で全セッションに効く → スキルを1つずつ変え、評価で崩れたらすぐに戻す
- forkのスキルは、hookを切った評価の中で本リポジトリのパスに触れようとする → 評価はscratchpadのcloneで行い、終わったら本リポジトリの差分を確かめる
- Claude Codeの更新でforkの挙動が変わる → batsはfrontmatterしか見ない。挙動は評価の手順で確かめ直す
- forkの `commit` はattributionの設定を反映しない → Co-Authored-Byを付けるかは、別の判断として扱う

## Migration Plan

pushした後、ほかのマシンには `uskn-harness sync` で届く。戻すときは `commit` のfrontmatterから4つの行を消す。
