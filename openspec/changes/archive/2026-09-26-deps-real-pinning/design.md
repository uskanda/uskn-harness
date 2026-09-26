## Context

動機はproposal.mdのWhyにある。要件はこの変更のdelta specsにある。
`bin/uskn-harness` の `ensure_third_party` は、`deps.json` の各項目の `install` の文字列をそのまま実行していた。
実行するのは `~/.claude/skills/<name>` が無いときだけで、`ref` は読んでいなかった。
`doctor` もディレクトリの有無しか見ていなかった。

2026-09-25に確かめた事実は次のとおり。

- skills CLI 1.7.0は、`<source>#<ref>` と `<source>#<ref>@<name>` を受け付ける。`ref` はタグか40桁のSHAで、12桁のSHAは `git clone --branch` に渡せず失敗する
- `-g -a claude-code -y` を付けると `~/.claude/skills/<name>` にコピーし、入れ直しではディレクトリを置き換える
- skills CLIはglobalの導入をlockファイルに記録する。項目は `source`、`sourceUrl`、`ref`（指定したときだけ）、`skillPath`、`skillFolderHash` を持つ。今のlockの項目はどれも `ref` を持たない
- Impeccableのタグは、スキル（`skill-v*`）、CLI（`cli-v*`）、engine（`engine-v*`）で別々に付く。
  CLIの `install` は、CLIの版に関係なく最新のスキルを取ってくる。手元のzipを `IMPECCABLE_BUNDLE_PATH` で渡したときだけ版が決まり、そのときCLIは署名を確かめない
- Impeccableの `install` は、agentのファイル4つを `~/.claude/agents/` に必ず書く。止めるオプションは無い
- スキル4.2.3以降の新しい画面の手順は、documenterで `DESIGN.md` とサイドカーを書く。鮮度警告は環境変数 `IMPECCABLE_NO_STALENESS_CHECK=1` か、`.impeccable/config.json` の `"stalenessCheck": false` で止まる

## Goals / Non-Goals

**Goals:**
- ピンを上げる作業は `deps.json` の編集だけで済み、次の `sync` で全マシンがその版にそろう
- `doctor` を見れば、マシンの実物とピンのずれが分かる
- 手で置いたスキルのディレクトリは、今までどおり壊さない

**Non-Goals:**
- Claude Codeの版の管理。別の変更が、`doctor` の警告のための下限の版を扱う
- `expo-skills` の導入。プロジェクトごとに入れる扱いのままで、`sync` の対象にしない
- `clis` の `openspec`、`forks`、`runtimes` の `claude-code`。別の変更が扱う
- Impeccableが書いた `DESIGN.md` を機械的に止めるhook。hookは別の変更が書き換え中なので、この変更ではスキルの指示にとどめる

## Decisions

### deps.json はコマンドの文字列ではなく、値を持つ

`skills` の各項目から `install` の文字列を外し、`via` で導入の方法を示す。`via` は `runtimes` で既に使っているキーである。

- `via: skills`：`source` と `ref` から導入のコマンドを組み立てる。
  形は `npx -y skills@<version> add '<source>#<ref>@<name>' -g -a claude-code -y`。
  `<version>` は `clis` の `skills` の版
- `via: impeccable`：`source`、`ref`、`asset`、`sha256`、`version`、`cli`（`package` と `version`）、`remove_agents` を持つ
- `via` の無い項目（`expo-skills`）は `sync` の対象外

文字列に `ref` を埋め込む形も考えた。ピンを上げるたびに `ref` と文字列の2か所を直すことになり、片方だけ直しても気づけないので採らない。

### skills CLI への指定は `<source>#<ref>@<name>` にそろえる

skills CLI 1.7.0は `#` の後ろを `ref` と絞り込むスキルの名前に分け、`ref` をlockに記録する。6つのスキルすべてをこの形で入れる。
`#<ref>` と `--skill` の組み合わせは確かめていない。GitHubのtreeのURLも使えるが、長くなり、`ref` がURLの途中に入る。
lockの項目の名前はスキルの名前で、`deps.json` のキーと同じになる。

### lock の読み方と、lock に無いディレクトリ

lockファイルの場所はskills CLIと同じ規則で決める。`XDG_STATE_HOME` があれば `$XDG_STATE_HOME/skills/.skill-lock.json`、無ければ `~/.agents/.skill-lock.json`。
jqで `.skills[<name>]` を読み、次のように扱う。

| `~/.claude/skills/<name>` | lockの項目 | `sync` | `doctor` |
|---|---|---|---|
| 無い | 問わない | 導入して `created` | `warn`（無い） |
| ある | `ref` がピンと同じ | `ok` | `ok` |
| ある | `ref` が違うか、無い | 入れ直して `updated` | `warn`（両方の値） |
| ある | 項目が無い | 触らずに `conflict` | `warn` |

lockに項目の無いディレクトリは、skills CLIが入れたものではない。手で置いたものかchezmoiのコピーなので、harness-syncの目的に従って触らない。
lockに関係なく入れ直す案は、手で置いたものを消すので採らない。
lockの `skillFolderHash` をupstreamのtreeと比べる案は、`doctor` にネットワークが要るので採らない。

### Impeccable はzipをsha256で確かめてからCLIに渡す

CLIの版を固定しても、スキルの版は固定できない。スキルの版を決める方法は、手元のzipを `IMPECCABLE_BUNDLE_PATH` で渡すことだけである。
そのときCLIは署名を確かめないので、ハーネスが `deps.json` の `sha256` と比べる。

- zipのURLは `https://github.com/<source>/releases/download/<ref>/<asset>` と組み立てる。URLを丸ごと持つと `ref` と2か所になる
- 手順は `impeccable_install` という関数にまとめ、`run_step` に渡す。stubの下では記録だけ、`--dry-run` では予定の出力だけになる
- 実際の手順は、一時ディレクトリへのダウンロード、sha256の比較、CLIの実行、一時ディレクトリの削除の順。
  sha256は `sha256sum`、無ければ `shasum -a 256`（macOS）で計算する。どちらも無ければ失敗にする
- 導入済みの版は `SKILL.md` のfrontmatterの `version` で判定する。Impeccable自身が書く値なので、印のファイルを別に置かない

CLIに最新を取らせてから版を確かめる案は、ピンにならないので採らない。
Impeccableを `forks` にコピーする案は、外部スキルは参照して固定するという、AGENTS.mdの制約に反するので採らない。

### agent は挙げた名前だけ、Impeccable の手順のたびに消す

消すのは `remove_agents` に挙げた4つの名前だけで、`impeccable-*` のglobは使わない。ユーザーが同じ接頭辞で書いたagentを消さないためである。
消すのは導入の直後に限らず、手順が `conflict` でない限り毎回である。
Impeccableの別の経路での更新がagentを戻しても、次の `sync` でそろう。
agentが無いと、Impeccableは同じ仕事をagent無しの手順（`degraded/`）で行う。この影響はgrillingのQ24で受け入れた。

### 鮮度警告はユーザー層の設定の環境変数で止める

4つの案を比べた。

| 案 | 判断 |
|---|---|
| プロダクトリポジトリごとに `.impeccable/config.json` を置く | 採らない。プロダクトリポジトリには規約が求めるものだけを置く、という、AGENTS.mdの制約に反する |
| `~/.claude/settings.json` の `env` に `IMPECCABLE_NO_STALENESS_CHECK=1` を足す | 採る。全セッションとそのBashに効く。ファイルはdotfilesが管理するので、ユーザーが足す |
| プラグインのSessionStart hookで `CLAUDE_ENV_FILE` に書く | この変更では採らない。hookは別の変更が書き換え中で、後から移せる |
| `ui-guidelines` がImpeccableのコマンドの前に環境変数を付けさせる | 採らない。Impeccableのスクリプトを走らせるのはImpeccable自身の指示で、許可の設定の照合も外れる |

設定が入るまで気づけるよう、`doctor` が `~/.claude/settings.json` の `env` と自身の環境を見て、無ければ `warn` を出す。
設定の無い環境で出た警告は、`ui-guidelines` の従来の規則どおり記録だけにする。

### Impeccable が書いた DESIGN.md とサイドカーは戻す

documenterのagentを消しても、Impeccableはagent無しの手順で `DESIGN.md` とサイドカーを書く。そのため `ui-guidelines` に規則を足す。
Impeccableのコマンドのあとに `git status --short -- DESIGN.md .impeccable` で変更を確かめ、Impeccableが書いたものは戻す。
残したい決定は、リポジトリの `DESIGN.md` にGoogle DESIGN.md形式で書いて `designmd lint` を通す。

### humanizer v3.0.0 は1行で足りる

v3.0.0はパターンを35から25にまとめ、返し方を3つ（貼った文章、ファイル、別の作業の中）に分けた。
`en-writing` はパターンの番号を使っていないので、足すのは別の作業の中で使うと伝える1行だけである。
`docs/proposal-2026-09.md` の35のパターンという記述は、調査の記録なので直さない。

### Claude Code の版は固定しない

workflowは既に版を指定せずに入れている。specに方針を書き、workflowにコメントを足し、版を足すと失敗するbatsのテストを置く。
別の変更が足す下限の版は `doctor` の警告のためで、固定ではない。この変更では触らない。

### テストは版を deps.json から読む

batsに `dep() { jq -r "$1" "$REPO/deps.json"; }` を置き、期待する導入のコマンドを `deps.json` から組み立てる。
サードパーティスキルとピンの形式のテストは、新しい `bin/tests/third-party.bats` に置く。
並行する別の変更が `bin/tests/uskn-harness.bats` の末尾に足しても、衝突しにくい。
`impeccable_install` の実際の手順は、スクリプトを読み込んで `USKN_HARNESS_STUB_NET=0` で呼んで試す。
`curl`、`mise`、`npx` はPATHの先頭に置いた偽物で、zipはテストの中で作ってsha256を計算する。

### 12桁の ref を40桁にする

2026-09-25にGitHubのAPIで解決した。

| 項目 | 40桁のSHA |
|---|---|
| mattpocock/skills（4つのスキル） | `3cca18b368ae95cdbdebbff572ccafa662551015` |
| frontend-design | `44490cccaf6d9f82fdeec9416fbf7c9bd72575dc` |
| expo-skills | `d0075ffa09928f1edb3e7ac4f5af07586d4b344d` |
| designmd | `9bf8eae67128b6cc55ad9bf86665767deb4c11cd` |
| agent-style | `99722a59e5ab654bafe68788f3bff7d1c8237f5a` |

frontend-designの `ref` は、`plugins/frontend-design` を最後に変えたcommit（2026-09-01）である。
そのcommitでのスキルのディレクトリのtreeのハッシュ `d79e2a5b` は、導入済みのコピーのlockの `skillFolderHash` と一致する。
humanizerはタグ `v3.0.0`、Impeccableはタグ `skill-v4.3.1` をそのまま使う。
`skill-v4.3.1` の `universal.zip` はダウンロードして、sha256が `1deea4cd` で始まる値と一致することを確かめた。

## Risks / Trade-offs

- skills CLIのlockの場所か形が変わる → CLIは1.7.0に固定した。上げるときは、lockの場所と項目の形を確かめ直す
- 入れ直しでスキルのディレクトリが置き換わる → サードパーティスキルは参照するだけで編集しない。手元で編集していれば失われる
- ImpeccableのCLIが `CLAUDE_CONFIG_DIR` を見ない → `sync` は `CLAUDE_CONFIG_DIR` の下の `agents/` から消す。ユーザーは `CLAUDE_CONFIG_DIR` を設定していない
- `sha256sum` と `shasum` のどちらも無い → Impeccableの手順は `fail` になり、何も入れない
- ImpeccableのCLIは初回に自分の実行ファイルを `~/.impeccable/bin/<version>/` に取ってくる → ハーネスの外だが、CLIの版を固定したので中身も決まる
- Impeccableが書いた `DESIGN.md` を機械的に止めるセンサーが無い → `ui-guidelines` の手順と `designmd lint` で抑える。hookは後の変更で考える
- 初回の `sync` が長くなる → 6つのスキルとImpeccableを1回ずつ入れ直す。2回目からは `ok` になる
- `XDG_STATE_HOME` の値が実行ごとに違う → lockが見つからず `conflict` になる。`doctor` が `warn` を出すので気づける

## Migration Plan

1. mergeのあと、各マシンで `uskn-harness sync` を実行する。6つのスキルが `ref` 付きで入れ直され、Impeccableは4.2.0から4.3.1になり、4つのagentが消える
2. `uskn-harness doctor` で、サードパーティスキルとImpeccableが `ok` になったことを確かめる
3. ユーザーがdotfilesのsettings.json.tmplの `env` に `"IMPECCABLE_NO_STALENESS_CHECK": "1"` を足し、`chezmoi apply` する。`doctor` の警告が消える

戻すときは `deps.json` の `ref` と `version` を戻して `sync` を実行する。lockの `ref` と違うので入れ直される。
