# grilling 記録: fork-skills-model-effort

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| 設定を付ける範囲 | forkで動かせるスキルにだけ `context: fork` と `model:` と `effort:` を付ける。インラインのスキルには付けない。インラインの `effort:` はターンの終わりまで残り、変わった時点で会話のキャッシュを作り直す。インラインの `model:` は `claude -p` の実験でAPIに反映されなかった | 会話中に確認（A案、2026-09-15） |
| モデルの書き方 | バージョンを書かず、別名（haiku、sonnet、opus、fable）だけを使う | 会話中に確認（ユーザーの指示） |
| commitのモデル | sonnetとする。過去コミットの再現評価で、haikuはファイルの種類で分け、内容と合わないメッセージを書いた | 会話中に確認（A案） |
| commitのfrontmatter | `context: fork`、`model: sonnet`、`effort: low`、`background: false` | 会話中に確認（A案） |
| Session trailerの出どころ | `<repo-context>` ではなく `${CLAUDE_SESSION_ID}` から作る。forkした先でも親セッションのIDになると実験で確かめた | 会話中に確認（A案） |
| この変更で扱うスキル | commit、recall（`model: sonnet` と `effort: low`）、switch-base（`model: haiku`）、sync-base（`model: haiku`）。cloneで再現して評価し、結果が崩れたスキルはforkにしない。prとreleaseはインラインのまま | 第1ラウンド Q1 |
| haikuのeffort | haikuのスキルには `effort:` を書かない。forkの実験でhaikuにはeffortが渡らなかった | 第1ラウンド Q1（実験の結果で補足） |
| 呼び出し側からcommitへの指示 | commitの引数を `[課題ID] [指示の文]` に広げる。最初の語が課題IDの形なら課題IDとし、残りを指示の文として読む。引数が無いときは現行と同じ動き。archive-pushは指示の文を渡し、pushは引数を渡さない | 第1ラウンド Q2（引数が無いときの扱いはユーザーが追加） |
| 分割の規則 | 変更の目的ごとに1〜5個とし、目的が1つなら1コミットとする形に改める | 第1ラウンド Q3 |
| ユーザーが直接打つ `/commit` | forkになり、会話で話した理由がメッセージに入らないことを受け入れる | 第1ラウンド Q4 |
| Session trailerを付ける条件 | 常に付ける。値は `${CLAUDE_SESSION_ID}` の先頭8文字 | 第1ラウンド Q5 |
| センサー | batsで、変えたスキルのfrontmatterと全スキル共通の規則を確かめる。共通の規則は、`model:` は別名だけ、`context: fork` には `background: false` が必須で `AskUserQuestion` を持たない、`model:` と `effort:` はforkのスキルにだけ置く、`model: haiku` には `effort:` を置かない | 第1ラウンド Q6（haikuの規則は実験の結果で補足） |
| recallの前提 | `<repo-context>` が届かないときに、git remoteから対象のプロジェクトを決める手順を足す | 会話中に確認（2026-09-15） |
| 成果物の置き場所 | 共通の規則は新しい能力に書く。commit、recall、switch-base、sync-baseの変更は既存のspecの差分に書く。「fork」「インライン」を用語集に足す | 会話中に確認（2026-09-15） |

## 後回しにしたもの

- prとreleaseのfork。評価すると実際にPRやリリースを作ってしまう
- fix-ciとpre-mergeのfork。直した経緯が本体に報告でしか残らないので勧めない
- インラインのスキルのeffort。変わった時点でキャッシュを作り直す費用がかかる

## 状態

frontierは空。共有理解は2026-09-15に確認済み。
