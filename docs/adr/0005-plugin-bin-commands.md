# ADR-0005: スキル向けの補助コマンドはプラグインの bin/ で配る

- 状態：採用（2026-09-25）。ADR-0002の「結果」のうち、`bin/` についての記述を訂正する
- 決定者：uskanda（変更hook-native-featuresのgrilling、第1ラウンドのQ27）

## 文脈

ADR-0002は「skills-dirプラグインは `bin/` 非対応」と書いた。今のClaude Code（2.1.282で確認）では誤りである。
プラグインの `bin/` は、プラグインが有効な間、Bashツールの `PATH` に載る。skills-dirプラグインも同じ扱いを受ける。
hookの環境には載らない。

スキルは補助スクリプトを長いパスで呼んでいた。パスは参照点から始まり、`plugins/uskn-harness/hooks/scripts/` の下を指す。
参照点は `USKN_HARNESS_DIR` で上書きできるので、パスはその既定値の式ごと書いてあった。
gitスキル8つが `session-start.sh` を、audit-writingスキルが `terms-check.sh` をこの形で呼ぶ。

## 決定

1. `plugins/uskn-harness/bin/` に、スキル向けの短いコマンドを置く。`uskn-repo-context` は `session-start.sh` を、`uskn-terms-check` は `terms-check.sh` を同じ引数で実行する
2. コマンドは、自分のディレクトリから `../hooks/scripts/` のスクリプトを `exec` するだけにする。正本はスクリプトのまま1つに保つ
3. スキルは長いパスをやめて短いコマンドを呼ぶ。代わりのパスの行は残さない。スキルを読み込むのはClaude Codeだけで、プラグインも同じ `sync` が置くからである
4. hook、CI、普通のシェルは `bin/` を `PATH` に持たない。hookは `${CLAUDE_PLUGIN_ROOT}` からスクリプトを直接呼び、それ以外は `~/.local/bin/uskn-harness` を使う
5. 許可ファイルを書く `allow-repo.sh` は短いコマンドにしない。唯一の入口を `PATH` に載せると、エージェントが自分で許可を足しやすくなるからである

## 結果

- 良い点：スキルの本文が短くなり、参照点の場所をスキルが知らなくてよくなる
- 引き受けるコスト：Claude Code以外のエージェントがスキルを読むと、コマンドが見つからない。そのときは別のADRで配り方を決める
- `bin/` のコマンドはshellcheckとbatsの対象に入る。`Makefile` の `SCRIPT_DIRS` と `plugin-bin.bats` が見る
