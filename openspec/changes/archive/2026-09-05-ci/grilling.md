# grilling 記録: ci

ハーネス全体の第 1 ラウンド Q12「validate を CI で回す」を実装する change（2026-09-05、セッション d69404e3）。
事実の調査はエージェント、決定はユーザー。

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| CI での道具の入れ方 | `uskn-harness sync` に `--tools` オプションを足し、ステップ 2（mise の道具と npm global）と 5b（schema symlink）だけを実行する。deps.json のピンが CI とローカルで 1 つになる。workflow への直書きと、`sync` 全体の実行は採らない | 第 1 ラウンド Q1 |
| mise の用意 | `jdx/mise-action@v2` で mise を入れ、mise.toml の道具を install してキャッシュさせる。`sync` の mise 導入ステップは mise があれば何もしない | 第 1 ラウンド Q2 |
| 道具が無いときの扱い | Makefile に strict モード（`make verify VERIFY_STRICT=1`）を足し、CI では skip を失敗にする。ローカルと Stop hook は今までどおり skip。strict モードには bats を書く | 第 1 ラウンド Q3 |
| claude CLI と plugin validate | CI で `npm install -g @anthropic-ai/claude-code` を毎回入れて `claude plugin validate --strict` を走らせる。ログインを要求するなど不安定なら、CI では plugin validate を対象外にする案に落とす | 第 1 ラウンド Q4 |
| トリガー | main への push、pull_request、workflow_dispatch の 3 つ | 第 1 ラウンド Q5 |
| 仮定（質問にせず提示して承認） | runner は ubuntu-latest、timeout 15 分、同じ ref の実行中ジョブは cancel。CI が走らせるのは `make verify` だけ。新しい ADR は起こさず、README の「開発」に CI の 1 行を足す | 第 1 ラウンド 前提 |

## 後回しにしたもの

- CalVer の初回タグ `v26.09.1`。CI が緑になってから release スキルで切る（会話中に確認）
- リリースの自動化（tag から GitHub Release を作る workflow）。release スキルの手動運用で足りている

## 状態

frontier は空。共有理解は 2026-09-05 に確認済み。
