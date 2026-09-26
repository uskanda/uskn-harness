## Why

`deps.json` はサードパーティスキルをピンしているように見えて、実際には固定していない。
`sync` は `skills@latest` で、しかも既定のブランチから入れる。スキルが既にあれば入れ直さないので、`ref` を変えても入れ替わらない。
`ref` の多くは12桁のSHAで、skills CLIに渡せない。Impeccableは、CLIの版を固定しても最新のスキルを入れる。
マシンごとに違う版が入り、`deps.json` の記録と実物がずれる。humanizer v3.0.0とImpeccable 4.3.1が出た今、ピンを実物に合わせる。

## What Changes

- `deps.json` の `ref` を、タグか40桁のSHAにそろえる。`clis` の `skills` の版を `latest` から1.7.0に固定する
- `sync` はskills CLIのスキルを `npx -y skills@1.7.0 add '<source>#<ref>@<name>' -g -a claude-code -y` で入れる。
  コマンドは `deps.json` の `via`、`source`、`ref` から組み立て、項目ごとの `install` の文字列はやめる
- `sync` はskills CLIのlockファイルの `ref` を `deps.json` と比べ、違えば入れ直す。lockに項目の無い既存のディレクトリには触らない。
  今のlockには `ref` が無いので、初回の `sync` は全スキルを1回ずつ入れ直す
- humanizerをv3.0.0に固定する。`en-writing` は、humanizerが最終の文章だけを返すように呼ぶ1行を足す
- Impeccableは、スキル4.3.1のリリースのzipをsha256で確かめ、CLI 4.1.0に `IMPECCABLE_BUNDLE_PATH` で渡して入れる。
  導入済みの版は `SKILL.md` の `version` で判定する
- `sync` はImpeccableの手順のあと、Impeccableが入れる4つのagent（`~/.claude/agents/impeccable-*.md`）を消す
- `doctor` は、lockの `ref`、Impeccableの版、残ったagent、鮮度警告を止める環境変数の有無を報告する
- `ui-guidelines` に、Impeccableが書いた `DESIGN.md` とサイドカーは採らないこと、鮮度警告の止め方を書く
- Claude Codeの版は固定しない。CIは版を指定せずに入れる。この方針をspecに書き、batsでworkflowを検査する
- batsのテストは版を `deps.json` から読む。ピンの更新でテストを直さずに済む

## Capabilities

### New Capabilities

なし。

### Modified Capabilities

- `harness-sync`: サードパーティスキルの導入をピンのrefとlockの比較で行い、Impeccableをzipとsha256で入れてagentを消す。`deps.json` の `ref` の形を定める
- `harness-doctor`: サードパーティスキルのピンとの差、Impeccableのagent、鮮度警告の設定を報告する
- `ui-guidelines-skill`: Impeccableが書いた `DESIGN.md` とサイドカーの扱いと、鮮度警告の止め方を定める
- `en-writing-skill`: humanizerに最終の文章だけを返させる
- `ci-verify`: Claude Codeの版を固定しないことを定める

## Impact

- インストーラ：`bin/uskn-harness` の `ensure_third_party` と `cmd_doctor`
- テスト：`bin/tests/uskn-harness.bats`（版を `deps.json` から読む）、新しい `bin/tests/third-party.bats`
- ピン：`deps.json` の `updated` と `skills` の各項目、`clis` の `skills`、`designmd`、`agent-style`。
  `clis` の `openspec`、`forks`、`runtimes` の `claude-code` は別の変更が扱うので触らない
- スキル：`skills/ui-guidelines/SKILL.md`、`skills/en-writing/SKILL.md`
- CI：`.github/workflows/verify.yml` のコメント
- 用語集：`openspec/glossary.yml` に「サイドカー」を足す
- 各マシン：次の `sync` でサードパーティスキルとImpeccableが入れ直され、Impeccableのagentが消える。
  鮮度警告の環境変数は、dotfilesが管理するユーザー層の `~/.claude/settings.json` に、ユーザーが足す
