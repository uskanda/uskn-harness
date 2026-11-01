## 1. テスト（TDD）

- [x] 1.1 `bin/tests/uskn-harness.bats` に `sync` のテストを足す。参照点がcheckoutを指すとき、自作スキル、プラグイン、実行ファイル、OpenSpec schemaの `readlink` が相対パスになることを確かめる。走らせて失敗を確認する
- [x] 1.2 `bin/tests/uskn-harness.bats` に3つのテストを足す。絶対パスの既存symlinkが `updated` で張り直され、2回目の `sync` が `ok` だけになること。参照点が別のcheckoutを指すときは絶対パスで張ること。`sync --tools` のschemaのsymlinkが絶対パスのままであること。走らせて失敗を確認する
- [x] 1.3 `cp -RP` でHOMEを写すテストを足す。`sync` 後の `$HOME/.claude` を別の一時HOMEへ写し、その参照点をcheckoutへのsymlinkとして作る。写した先で `SKILL.md` が読めることを確かめる。走らせて失敗を確認する
- [x] 1.4 `sync` と `doctor` のテストを足す。消えたスキルを相対パスで指すsymlinkを、`sync` が削除し、`doctor` が `warn` と報告することを確かめる。走らせて失敗を確認する
- [x] 1.5 `doctor` のテストを足す。ハーネスが張った絶対パスのsymlinkは `warn`。ハーネス外で指す先の無いsymlinkは `warn` を1回だけ。ハーネス外で絶対パスを指すsymlinkは `warn`。`sync` 直後は新しい `warn` が出ない。走らせて失敗を確認する
- [x] 1.6 `readlink "$SKILLS/pr"` のように、symlinkの中身を絶対パスと比べている既存のテストを見直す。`readlink -f` で実体を比べているものはそのまま通ることを確かめる

## 2. 実装

- [x] 2.1 `bin/uskn-harness` に関数を2つ足す。2つの物理パスから相対パスを組み立てる関数と、symlinkの中身を文字列として畳む関数である。bash 3.2とBSDのツールで動かす（designの決定2、決定5）
- [x] 2.2 `ensure_link` と `link_status` を変え、参照点を経由した相対パスを期待する中身にする。参照点がこのcheckoutに解決されないときは、絶対パスを期待する中身にする。実体は同じで中身だけ違うときは `update` を返す（決定1、3、4）。1.1〜1.3と既存のテストが通ることを確認する
- [x] 2.3 `stale_skill_links` を変え、相対パスの中身を畳んでから比べる。1.4が通ることを確認する
- [x] 2.4 `check_link` と `cmd_doctor` に3つの `warn` を足す。中身が違うもの、ハーネス外で指す先の無いもの、絶対パスのものである（決定6）。1.5が通ることを確認する
- [x] 2.5 `bin/uskn-harness` の先頭のコメント（step 4、5の説明）を、相対パスで張ることがわかる書き方に直す

## 3. 文書

- [x] 3.1 `README.md` の「導入」の節に、devcontainerで使う手順を足す。ハーネスをコンテナの `~/.local/share/uskn-harness` にマウントする。`~/.claude` は参照点との位置関係を保って写す。CLIが要るならコンテナで `uskn-harness sync` を実行する。次の `sync` で既存のsymlinkが一度だけ `updated` になることも書く
- [x] 3.2 `plugins/uskn-harness/README.md` とADR-0002のsymlinkの例を、参照点経由の相対パスに合わせる。ADRは決定の追記として書く
- [x] 3.3 `textlint` とterms checkが通ることを確認する

## 4. 検証

- [x] 4.1 `openspec validate relative-harness-links --strict` と `make verify` が通ることを確認する
- [x] 4.2 `uskn-harness sync` をこの開発機で実行する。既存のsymlinkが `updated` になり、続く `sync` が `ok` だけになることを確かめる。`uskn-harness doctor` の新しい `warn` を確かめる
- [x] 4.3 `~/.claude` を写したdevcontainerで、ユーザーが確かめる。マウントした参照点から、ハーネスのスキルとhookが読み込まれること（archive-pushで完了とみなした）
