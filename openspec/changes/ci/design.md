## Context

動機は proposal.md の Why を参照。`make verify` の各チェックは `command -v` で道具を探し、無ければ skip と表示して通る。
道具はローカルでは `uskn-harness sync` が入れる。sync は 8 ステップある。CI に不要なものは 4 つ。`~/.claude` の symlink、`npx skills add`、private の sessions repo の clone、ユーザー層 CLAUDE.md。
installer には `USKN_HARNESS_STUB_NET=1` でネットワークと runtime のステップをログに記録するだけにするテスト用の stub がある。

## Goals / Non-Goals

- Goals: push のたびに同じ検証が走る。道具が無いまま緑にならない。版のピンは deps.json と mise.toml の 1 か所
- Non-Goals: リリースの自動化。プロダクト repo の CI。ローカルの `make verify` の振る舞いの変更

## Decisions

1. `sync --tools` はステップ 2（ランタイムと npm global）と 5b（schema symlink）だけを実行する。参照点 `~/.local/share/uskn-harness` は作らない。schema symlink は checkout の `schemas/uskn` を直接指すので参照点は要らない。代替案は `sync` 全体（sessions repo の clone で認証が要る）と workflow への直書き（ピンが 2 か所）
2. strict モードは make 変数 `VERIFY_STRICT` と `skip` マクロで実装する。マクロは skip の出力を 1 か所にまとめ、各ターゲットの skip 分岐から呼ぶ。strict では stderr にチェック名と「この検査は必須」の印を出して exit 1。skills-ref が無いときの frontmatter 検査は劣化であって skip ではない。strict の対象外にする。shellcheck が無いときの `bash -n` は strict では失敗にする
3. claude CLI は workflow で `mise exec -- npm install -g @anthropic-ai/claude-code` の後に `mise reshim` を呼ぶ。`sync --tools` の reshim より後に入れるため、明示の reshim が要る。deps.json にはピンしない。開発機の claude をハーネスが上書きしないため
4. mise は `jdx/mise-action@v2`（`install: true`、`cache: true`）で入れる。mise.toml の node、bats、shellcheck が入る。Makefile は `~/.local/share/mise/shims` を PATH の先頭に足す。shim の解決は action の PATH 設定に依存しない
5. workflow は 1 ジョブ。`concurrency` で同じ ref の実行中ジョブを cancel、`timeout-minutes: 15`

## Risks / Trade-offs

- [`claude plugin validate` がログインや設定を要求して CI で落ちる] → workflow の claude 導入ステップを外す。Makefile の strict では plugin だけ免除し、spec の該当要件を外す
- [npm global の textlint がプリセットを解決できない] → ローカルも同じ global 導入で動いているので同じ挙動になる見込み。落ちたら `--rulesdir` を検討
- [mise-action の mise と `sync --tools` の `mise use -g` が別の設定を見る] → global の版は mise.toml と同じ 24。どちらが解決されても同じ node になる
- [CI の実行時間] → mise-action のキャッシュで 2 回目以降は短くなる。npm global の導入は毎回で 1〜2 分

## Migration Plan

workflow ファイルを足すだけ。ロールバックはファイルの削除。ローカルの `make verify` と Stop hook は既定の非 strict で振る舞いが変わらない。
