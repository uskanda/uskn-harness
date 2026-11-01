## MODIFIED Requirements

### Requirement: 変更の範囲
`verify-fast` は、基準のcommitから変わったファイルと、追跡されていないファイルを対象にしなければならない（MUST）。
基準は、HEADと次の参照とのmerge-baseである。上流ブランチ、`origin/HEAD`、`origin/main`、`origin/master` のうち、最初に得られたものを使う。
どれも得られなければHEADを基準とする。`VERIFY_BASE` を渡せば、それを基準にする。
削除されたファイルは対象にしない。
仮ファイルは対象にしない（MUST NOT）。仮ファイルとして扱う形は、session-baselineの指紋と同じである。

#### Scenario: commit 済みの変更
- **WHEN** `origin/main` から分かれたブランチで文書を1つcommitし、作業ツリーに変更が無い状態で `make verify-fast` を実行する
- **THEN** commitした文書が検査される

#### Scenario: 追跡されていないファイル
- **WHEN** gitへ足していない新しい文書を置いて `make verify-fast` を実行する
- **THEN** その文書が検査される

#### Scenario: 仮ファイル
- **WHEN** 作業ツリーの直下に0バイトの `.mcp.json` がある状態で、`make verify-fast-plan` を実行する
- **THEN** 対象に `.mcp.json` は含まれない
