# Proposal

## Why

ハーネスは、管理者が自分のホームで使う端末だけを前提にしている。
端末の土台は、エージェントを別のOSのユーザーで動かし、`--settings` でsandboxの最低線を固定する。
2026-11-25の実機の確認では、最低線があっても、ユーザー層の `sandbox.excludedCommands` と `WebFetch(domain:*)` がsandboxを緩めた。
今の設定断片をそのOSのユーザーへ入れると、最低線が崩れる。
あわせて、hookの誤検知、`~/repos` に固定した開発用のcheckout、Linuxだけで意味を持つ許可が、同じ端末で問題になっている。

## What Changes

- 環境の種類を、管理者の環境（`admin`）と閉じた環境（`confined`）の2つにする。checkoutの直下にあるrootの持ち物の環境の印 `.uskn-environment` で判定し、印が無ければ管理者の環境とする
- 設定断片を、共通の `templates/user/settings.json`、環境の種類別、OS別に分ける。合成は、共通、環境の種類、OS、端末別設定の順に重ねる
- BREAKING（設定断片の形）。sandboxを緩めるキーを、共通の設定断片から管理者の環境用へ移す
- 移すキーは、`failIfUnavailable: false`、`allowUnsandboxedCommands: true`、`excludedCommands` の11個である
- `WebFetch(domain:*)`、`allowAllUnixSockets`、`remoteControlAtStartup`、`defaultMode: auto` も移す
- 閉じた環境用の設定断片は、上のキーを持たず、`permissions.allow` に `Edit` と `Write` を持つ。`allowWrite` からmiseとpnpmの置き場を外す
- 閉じた環境のsyncは、端末別設定からsandboxを緩めるキーを持ち込まない。doctorは警告し、`sandbox-exclude` と `sandbox-allow-host` は止まって理由を出す
- Linuxだけで意味を持つ許可（`apt-cache`、`systemctl`、`lscpu`、`/sys` と `/usr/lib` の読み取り）を、OS別の設定断片 `settings-linux.json` へ移す
- 管理者が、ピンどおりの道具とサードパーティスキルを共有の置き場へ入れるコマンド `uskn-harness install-shared <dir>` を足す。閉じた環境のsyncは導入せず、共有の置き場へlinkを張る
- 合成した設定を書き込まずに出力するコマンド `uskn-harness print-settings` を足す。端末の土台が、自分の持ち物として設定を置くために使う
- 閉じた環境では、読み上げ通知のプラグインと、画面向けのスキル（`set-workspace-theme`、`cleanup`）を入れない
- 閉じた環境のhookは、ホームの下をPATHに足さない。リポジトリのコード（検証規約、リポジトリのtextlintの設定）は、`sandbox-exec` の中で動かす。その規則は、環境の印が挙げる秘密の置き場の読み取りと、自分の端末の外への直接の接続を禁じる
- `terms-check` と `textlint-check` は、書いたファイルが属するgitルートで用語集と設定を選び、そのリポジトリの `.textlintignore` に従う
- bash-guardの「sandboxの中で動く」の知らせを、1つのセッションで1回にする
- 開発用のcheckoutの置き場を、`~/.config/uskn-harness/dev-checkout` で変えられるようにする。既定は `~/repos/uskn-harness` のまま
- 閉じた環境のセッションは、ローカルのcommitまでを行う。pushとPRを行うスキルは止まり、bash-guardは `git push` とPRの作成を拒否する
- ADRを1つ足す。ADR-0009の決定1と、ADR-0011の決定2に、閉じた環境の例外を設ける

## Capabilities

### New Capabilities

- `environment-kind`: 環境の印の置き場と書式、環境の種類の判定、印が正しくないときの扱い
- `confined-hook-sandbox`: 閉じた環境のhookが、リポジトリのコードを `sandbox-exec` の中で動かす規則と、PATHの組み立て
- `shared-tools`: 共有の置き場への道具とサードパーティスキルの導入と、その記録

### Modified Capabilities

- `user-settings`: 設定断片の分割、合成の順序、閉じた環境で持ち込まないキー、sandboxの値の環境の種類ごとの規則、合成の出力
- `harness-sync`: 閉じた環境での導入の範囲（共有の置き場へのlink、checkoutの更新の省略、入れないプラグインとスキル）。`sandbox-exclude` と `sandbox-allow-host` の拒否
- `harness-doctor`: 環境の印、書き込みの権限、共有の置き場の版、持ち込まないキー、参照点の移行の案内の検査
- `machine-bootstrap`: 開発用のcheckoutの置き場を設定から読む
- `terminology-guard`: 読むリポジトリを、書いたファイルのgitルートにする。`.textlintignore` に従う
- `textlint-hook`: 設定と作業ディレクトリを、書いたファイルのgitルートで選ぶ。`.textlintignore` に従う。閉じた環境の実行の規則を足す
- `verify-gate`: 閉じた環境での検証の実行
- `bash-guard`: 知らせを1つのセッションで1回にする。閉じた環境でpushとPRの作成を拒否する
- `sandbox-exclude-skill`: 閉じた環境では足さずに止まる
- `sandbox-allow-host-skill`: 閉じた環境では足さずに止まる
- `notify-plugin`: 通知のコマンドとLaunchAgentを、管理者の環境だけで扱う
- `utility-skills`: 画面向けのスキルに、管理者の環境だけで使う印を付ける
- `git-workflow-skills`: 閉じた環境では、pushとPRの前に止まる
- `spec-pr-skill`: 閉じた環境では、pushの前に止まる
- `archive-push-skill`: 閉じた環境では、pushの前に止まる

## Impact

- インストーラ：`bin/uskn-harness` のsync、doctor、`sandbox-exclude`、`sandbox-allow-host`。新しく `install-shared` と `print-settings` を足す
- hook：`plugins/uskn-harness/hooks/scripts/` の下の5つ。`verify-gate.sh`、`textlint-check.sh`、`terms-check.sh`、`bash-guard.sh`、`lib/common.sh` である
- プラグインのコマンド：`plugins/uskn-harness/bin/` に `uskn-environment` を足す
- 設定：`templates/user/settings.json` を分け、環境の種類別とOS別の4つのファイルを足す
  - `templates/user/settings-admin.json` と `templates/user/settings-confined.json`
  - `templates/user/settings-linux.json` と `templates/user/settings-darwin.json`
- gitのスキル：`skills/git/pr`、`skills/git/push`、`skills/spec-pr`、`skills/archive-push`
- そのほかのスキル：`skills/sandbox-exclude`、`skills/sandbox-allow-host`、`skills/cleanup`、`skills/set-workspace-theme`
- bootstrap：`templates/chezmoi/run_after_uskn-harness.sh.tmpl`
- 文書：`openspec/glossary.yml`、新しいADR、`README.md`、`docs/setup-new-machine.md`
- 既存の管理者の環境では、syncの後のliveの設定は今と同じになる。共通から管理者の環境用へ移したキーは、合成で同じ値に戻るため
- 対象外：uskn-loopとswitchboardの閉じた環境での実行、Linuxの閉じた環境、端末の土台の側の呼び出しとユーザー層の設定の持ち主
