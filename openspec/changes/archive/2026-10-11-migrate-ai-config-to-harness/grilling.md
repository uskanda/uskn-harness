# grilling 記録: migrate-ai-config-to-harness

dotfiles（`uskanda/dotfiles`）が持つClaude CodeとAI関連の設定をハーネスへ移し、dotfilesにはハーネスの導入とsyncの呼び出しだけを残す。
grillingの前に、dotfiles側の変更箇所を会話中に洗い出した。
対象はユーザー層の設定、スキル4つ、読み上げ通知の一式、setupのopt-in、`.chezmoiignore`、文書。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| changeの置き場 | ハーネスに置き、作業用のcloneから仕様PRにする。dotfiles側の撤去と配線は同じchangeのtasksに含め、dotfilesのmasterへ直接コミットする | 第1ラウンド Q1 |
| Windowsネイティブの扱い | 段階的に移す。このchangeはLinux、macOS、WSLだけを対象にする。WindowsネイティブのAI設定はdotfilesに凍結して残し、ハーネスのWindows対応は別のchangeにする。その間、ユーザー層の設定の中身は2か所にある | 第1ラウンド Q2 |
| settings.jsonの持ち方 | 管理するキーだけを設定断片からliveの `~/.claude/settings.json` へマージする。設定断片のキーはハーネスが上書きし、`permissions.allow` は和集合を取り、設定断片に無いキーは残す | 第1ラウンド Q3 |
| dotfilesからの呼び出し時期 | `chezmoi apply` のたびに呼ぶ。run_onceを `run_after_` の1本に置き換え、無ければ導入、あれば `uskn-harness sync` を実行する | 第1ラウンド Q4 |
| 読み上げ通知の移し方 | 独立したプラグイン uskn-notify をハーネスに作る。hook、通知のスクリプト、VOICEVOXのインストーラを持つ。syncはプラグインのsymlinkを一般化する。Windowsネイティブ用のコピーはdotfilesに凍結する | 第2ラウンド Q5 |
| 端末ごとの上書き | 端末別設定 `~/.config/uskn-harness/settings.json` を設け、設定断片の後にマージする。リポジトリには入らない | 第2ラウンド Q6 |
| 消したキーの片付け | 適用記録を状態として残し、3方向で比べる。前回の設定断片にあって今回の設定断片に無いものだけをliveから消す。ローカルで足したものには触らない | 第2ラウンド Q7 |
| dotfilesのスキル4つ | chezmoi-mergeとsync-claude-settingsは、dotfilesのプロジェクト層 `.claude/skills/` へ移す。cleanupとset-workspace-themeはハーネスへ移して英訳する。set-workspace-themeのWindowsネイティブ用のコピーはdotfilesに凍結する | 第2ラウンド Q8 |
| Claude Code外のAI関連 | ローカルLLMのスクリプト3対、opencodeの設定、Fusion MCPは、移さずにdotfilesへ置き続ける。端末の構成であり、エージェントの作法ではないため | 第2ラウンド Q9 |
| 通知の秘密 | `~/.config/claude-notify/config.env` をユーザーが持つ管理外のファイルにする。既存の端末ではchezmoiが描画済みのファイルが残る | 第3ラウンド Q10 |
| dotfilesで進行中のtelegramのchange | dotfilesから消し、このchangeが済んでからハーネスで新しいchangeとして出し直す。実装は1つも進んでいない | 第3ラウンド Q11 |
| 設定断片に入れる値 | hooks以外の今のキーを入れる。superpowersのmarketplaceは入れない。`env` に `IMPECCABLE_NO_STALENESS_CHECK=1` を足す | 第3ラウンド Q12（effortはユーザーがQ17へ上書き） |
| allowの仕分け | 汎用のものは設定断片、特定の端末向けのものは端末別設定、一度きりのコマンドと古いスキル名は捨てる。PowerShellのchezmoi系はdotfilesのプロジェクト層の設定へ移す | 第3ラウンド Q13 |
| 初回syncの片付け | 適用記録が無い端末では、dotfilesの最後のテンプレートを前回の設定断片とみなす。通知のhook、superpowers、捨てるallowは初回のsyncがliveから消す | 第3ラウンド Q14 |
| 受信の常駐プロセスとVOICEVOXのopt-in | ハーネスがuskn-notifyのコマンドとして持ち、手順はハーネスのdocsに書く。dotfilesのsetupからは該当の節を消す。LaunchAgentが既にある端末では、syncが入れ直してopt-inを保つ | 第3ラウンド Q15 |
| 毎回のsyncが失敗したとき | 今のrun_onceと同じにする。導入の失敗は非ゼロで終え、syncの終了コードはそのまま返す | 第3ラウンド Q16 |
| effortの扱い | 設定断片には共通の既定値としてtop-levelの `effortLevel` だけを入れ、`modelSettings` は入れない。syncはliveの `modelSettings` のeffortを毎回消す。端末の値はどこにも書き戻さない | 第4ラウンド Q17（Q12へのユーザーの上書き「effortは頻繁に変えるので、端末の現在の設定を永続化しない」を受けた） |

## 後回しにしたもの

- ハーネスのWindowsネイティブ対応。Git Bashでのsync、symlinkの代わりのコピー、`timeout.exe`、miseのshims、jqを扱う。dotfilesに凍結したWindows用の設定、通知、set-workspace-theme、sync-claude-settingsはこのときに移すか廃止する
- dotfilesで進めていたTelegram経由の通知の出し直し

## 状態

frontierは空。共有理解は2026-10-05に確認済み。
