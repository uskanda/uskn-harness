## Why

`uskn-harness sync` が `~/.claude/skills` などに張るsymlinkは、checkoutの絶対パスを指す。例は `/Users/kanda/uskn-harness/skills/git/commit`。
devcontainerのビルドで `~/.claude` をコンテナへ写すと、そのパスはコンテナに無い。symlinkの指す先が消える。
Claude Codeは指す先の無いスキルを黙って読み飛ばす。そのため、ハーネスのスキルとプラグインのhookだけが使えなくなる。
スキル本文も参照点 `~/.local/share/uskn-harness` を直接使うので、コンテナでも参照点さえ用意すれば済む形にそろえたい。

## What Changes

- `sync` がハーネス内へ張るsymlink（実行ファイル、自作スキル、プラグイン、OpenSpec schema）の中身を、参照点を経由する相対パスにする。例：`~/.claude/skills/commit -> ../../.local/share/uskn-harness/skills/git/commit`
  - これで `~/.claude` と参照点の位置関係が同じなら、HOMEが `/home/vscode` でも `/root` でもsymlinkの指す先が残る
  - 参照点そのもの（`~/.local/share/uskn-harness -> checkout`）は今までどおり絶対パスにする。コンテナではここにハーネスをマウントする
  - 参照点がこのcheckoutを指していないときは、今までどおりcheckoutの絶対パスで張る。参照点が別の場所を指す場合と、`sync --tools` で参照点を作らない場合が当たる
- 既存の絶対パスのsymlinkは、指す先が正しくても `sync` が相対パスに張り直し、`updated` と報告する。2回目の `sync` は `ok` だけになる
- 実体の無いsymlinkの削除（`sync`）と検査（`doctor`）が、相対パスのsymlinkもハーネスを指すものとして見分ける
- `doctor` に検査を2つ足す
  - `~/.claude/skills` の下で、指す先の無いsymlinkをハーネスの内外を問わず `warn` と報告する
  - `~/.claude/skills` の下で、絶対パスを指すsymlinkを `warn` と報告する。コンテナへ写すと指す先が消えるため
  - 会話では、HOMEの外を指す絶対パスを報告すると書いた。しかしMacでは `/Users/kanda/...` がHOMEの内側にあるので、今回の例が報告されない。そこで条件を絶対パスかどうかにした
- `doctor` のsymlinkの向き先の検査が、相対パスでないハーネスのsymlinkを `warn` と報告する。`sync` で直る
- READMEに、devcontainerで使うときの手順を書く。ハーネスをコンテナの `~/.local/share/uskn-harness` にマウントし、`~/.claude` を写す

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

- `harness-sync`: ハーネス内へ張るsymlinkを参照点経由の相対パスにする。絶対パスのsymlinkを張り直す。実体の無いsymlinkの見分けを相対パスにも広げる
- `harness-doctor`: symlinkの向き先の検査に相対パスかどうかを加え、指す先の無いsymlinkと絶対パスのsymlinkを `~/.claude/skills` 全体で報告する

## Impact

- 変更：`bin/uskn-harness`。対象は `link_status`、`ensure_link`、`check_link`、`stale_skill_links`、`cmd_doctor`
- 変更：`bin/tests/uskn-harness.bats`。相対パスの中身、張り直し、参照点が無いときの絶対パス、`doctor` の新しい検査
- 文書：`README.md` にdevcontainerの節を足す。`plugins/uskn-harness/README.md` と `docs/adr/0002-plugin-distribution-via-skills-dir.md` のsymlinkの書き方を直す
- 既存のマシン：次の `sync` で既存のsymlinkがすべて `updated` になる。挙動は変わらない
- 範囲外：`~/.claude/settings.json` や `plugins/installed_plugins.json` の絶対パス。dotfilesとClaude Codeが管理する
- 用語：「マウント」を用語集に足した
