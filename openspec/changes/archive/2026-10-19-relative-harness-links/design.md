# Design

## Context

動機はproposal.mdのWhyを参照。

今の `bin/uskn-harness` の状態は次のとおり。

- symlinkは `ensure_link <target> <source>` が張る。`source` はcheckoutの絶対パス（`$HARNESS/...`）で、`ln -s` にそのまま渡す
- 張り直すかどうかは `link_status` が決める。symlinkを `realpath` で解決し、`source` と同じ実体なら `ok` を返す。中身の文字列は見ない。そのため、絶対パスのsymlinkも相対パスのsymlinkも同じく `ok` になる
- 実体の無いsymlinkは `stale_skill_links` が見分ける。指す先が存在しないので解決できず、中身の文字列が `$HARNESS/skills/` か `$STABLE/skills/` で始まるかを比べている
- 参照点 `$STABLE` は `$HARNESS` へのsymlink、またはmanaged cloneの実ディレクトリ。`sync --tools` は参照点を作らない
- macOSの `/bin/bash` 3.2とBSDのツールでも動く必要がある。BSDの `realpath` には `--relative-to` が無い

## Goals / Non-Goals

**Goals:**

- コンテナに参照点を用意し、`~/.claude` を同じ位置関係で写せば、ハーネスのスキルとプラグインがそのまま読み込まれる
- 既存のマシンは次の `sync` 1回で移行が終わる

**Non-Goals:**

- コンテナの中で `sync` を走らせずに、textlintやopenspecなどのCLIを用意すること。必要ならコンテナで `sync` を走らせる
- `~/.claude` の下にある、ハーネス以外が作った絶対パスのsymlinkを書き換えること。`doctor` で報告するだけにする
- devcontainerの設定ファイルをテンプレートとして配ること

## Decisions

### 1. 相対パスは参照点を経由して組み立てる

symlinkの中身は、symlinkを置くディレクトリから `参照点/<ハーネス内の相対パス>` への相対パスにする。
checkoutへの相対パスにはしない。checkoutの場所はマシンごとに違い、コンテナには無い。参照点はスキル本文も使う固定の場所だ。そのため、マウント先は参照点の1か所で済む。

退けた代替案は次のとおり。

- 絶対パスのまま、devcontainer側でcheckoutを同じ絶対パスにマウントする。コンテナの中にMac固有の `/Users/<name>` を作ることになる。HOMEの違う環境ごとに設定も要る
- `cp -L` で実体をコピーするよう案内する。スキル本文が参照点を直接使うので、参照点が無ければtextlintの設定などが見つからない。結局、参照点の用意は要る
- 実体をまとめた `~/.claude` を書き出すコマンドを `uskn-harness` に足す。ハーネスを更新するたびに作り直しが要る。checkoutの更新がそのまま各マシンに届くという、symlinkの利点も失う

### 2. 相対パスは物理パスで計算する

symlinkを置くディレクトリは `pwd -P` で物理パスにしてから計算する。OSは相対symlinkを、symlinkの物理的な親ディレクトリから解決するためだ。例えば `~/.claude` がdotfilesへのsymlinkでも、ホストで正しく解決される。
参照点の側は、参照点の親ディレクトリだけを物理パスにし、参照点そのものは解決しない。解決するとcheckoutへの相対パスになり、決定1が成り立たない。
置き場のディレクトリがまだ無いとき（初回や `--dry-run`）は、存在する最も深い祖先を物理パスにし、残りをつなげる。

計算はbashの関数で行う。2つのパスを `/` で区切り、共通の先頭の段を除く。symlinkの側に残った段数だけ `..` を並べ、参照点の側の残りをつなげる。BSDに無い `realpath --relative-to` やpythonには頼らない。

### 3. 参照点がこのcheckoutを指さないときは絶対パスに戻す

参照点がこのcheckoutに解決されないときは、今までどおり `$HARNESS` の絶対パスで張る。参照点が別の場所を指す場合と、`sync --tools` で参照点を作らない場合が当たる。参照点経由にすると、別のハーネスや存在しない場所を指してしまうからだ。
参照点の衝突は今も `warn` として報告されるので、新しい報告は足さない。

### 4. 正しいsymlinkの条件に中身の文字列を加える

`link_status` が `ok` を返す条件を2つにする。実体が `source` と同じであること、そして中身が決定1〜3で組み立てた文字列と同じであること。
実体は同じで中身が違うときは `update` を返す。これで既存の絶対パスのsymlinkが張り直され、2回目の `sync` では `ok` だけになる（冪等性）。

### 5. 実体の無いsymlinkは文字列のまま解決する

`stale_skill_links` は、中身が相対パスならsymlinkの物理的な親ディレクトリにつなげる。そのうえで `.` と `..` を文字列として畳み、`$HARNESS/skills/` か `$STABLE/skills/` で始まるかを比べる。
指す先が無いので `realpath` は使えない。文字列で畳むと、途中にsymlinkがある場合に実際の解決とずれることがある。ただし対象はハーネスが張ったsymlinkで、途中のsymlinkは参照点だけなので、比較の対象に `$STABLE` を含めていれば足りる。

### 6. `doctor` の2つの新しい検査は `~/.claude/skills` の直下だけを見る

- 指す先の無いsymlink：すでに報告されるもの（自作スキルの名前のsymlinkと `stale_skill_links` の結果）を除き、残りを `warn` と報告する。同じsymlinkを2回報告しないため
- 絶対パスのsymlink：中身が `/` で始まるものをすべて `warn` と報告する。ハーネスが張ったものでも、決定3で絶対パスに戻ったなら報告される。参照点の衝突の `warn` と合わせて、コンテナへ写せない理由がわかる

どちらも `warn` にとどめ、終了コードは変えない。ハーネス外のsymlinkはユーザーの持ち物で、ホストでは動いているからだ。
見る範囲は `~/.claude/skills` の直下にする。コンテナで指す先が消えて困るのはスキルの読み込みで、実行ファイルとschemaのsymlinkは向き先の検査が既にある。

## Risks / Trade-offs

- `~/.claude` か `~/.local/share` がsymlinkで、HOMEの外に実体がある → 相対パスは物理パスで組むので、ホストでは動く。コンテナへ写すときは同じ位置関係が要る。READMEのdevcontainerの節に、`~/.claude` の実体と参照点の位置関係を保って写すと書く
- Dockerの `COPY` は、ビルドの入力に含まれないパスを指すsymlinkを、指す先ごと写せない → 参照点はビルド時にコピーしない。devcontainerの `mounts` でマウントする手順をREADMEに書く
- 既存のマシンで、次の `sync` がsymlinkを一斉に `updated` と報告する → 1回限り。挙動は変わらないことをコミットとREADMEに書く
- 文字列で畳む解決が、実際の解決とずれる → ハーネスが張るsymlinkでは、途中のsymlinkは参照点だけだ（決定5）。参照点を比較対象に含めて扱う。ハーネス外のsymlinkはこの判定で消さない（今の規則のまま）

## Migration Plan

1. この変更を入れたハーネスで `uskn-harness sync` を実行する。ハーネス内を指すsymlinkが相対パスに張り直される
2. `uskn-harness doctor` で、ハーネス外の絶対パスのsymlinkと指す先の無いsymlinkを確かめる。必要なら持ち主（dotfilesなど）の側で直す
3. devcontainerでは、ハーネスをコンテナの `~/.local/share/uskn-harness` にマウントし、`~/.claude` を写す

戻すときは、前の版のハーネスで `sync` を実行する。前の版は実体が同じなら `ok` とみなすので、相対パスのsymlinkは残るが、そのまま動く。
