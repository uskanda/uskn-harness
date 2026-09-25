## MODIFIED Requirements

### Requirement: 道具はローカルと同じピンで入れる
workflowは道具を `uskn-harness sync --tools` で入れなければならない（MUST）。対象はmise.tomlの道具（node、bats、shellcheck）と、`deps.json` でピンしたnpm globalのCLI。
workflowに版を直書きしない。
python3のPyYAMLがrunnerに無いときは、OSのパッケージから入れる。

#### Scenario: ピンの更新
- **WHEN** `deps.json` のtextlintのversionを上げてpushする
- **THEN** workflowは変更なしで新しい版を入れて検証する

#### Scenario: PyYAML の無い runner
- **WHEN** runnerのpython3が `import yaml` に失敗する
- **THEN** workflowはOSのパッケージでPyYAMLを入れてから `make verify` を実行する

### Requirement: strict モード
`make verify VERIFY_STRICT=1` は、道具が無くてskipしていたチェックを失敗にしなければならない（MUST）。
対象はopenspec、openspec schema、shellcheck、bats、claude plugin validate、textlint、designmd。
`terms-check` が使うpython3と、スキルのfrontmatterを解析するPyYAMLも対象にする。
失敗の出力にはチェック名と `VERIFY_STRICT` を含める。`VERIFY_STRICT` が未設定または `0` のときは今までどおりskipして終了コード0。

#### Scenario: designmd が無い（strict）
- **WHEN** designmdがPATHに無い状態で `make verify-design VERIFY_STRICT=1` を実行する
- **THEN** 終了コードは非ゼロで、出力に `[design.md]` と `VERIFY_STRICT` が含まれる

#### Scenario: designmd が無い（既定）
- **WHEN** designmdがPATHに無い状態で `make verify-design` を実行する
- **THEN** 終了コードは0で、出力に `skipped` が含まれる

#### Scenario: PyYAML が無い（strict）
- **WHEN** PyYAMLを読めないpython3しか無い状態で `make verify-skills VERIFY_STRICT=1` を実行する
- **THEN** 終了コードは非ゼロで、出力に `[skills]` と `VERIFY_STRICT` が含まれる

## ADDED Requirements

### Requirement: スキルの frontmatter 検査
`make verify` は、`skills/` 配下のすべての `SKILL.md` のfrontmatterをYAMLとして解析しなければならない（MUST）。
解析に失敗したとき、結果がmappingでないとき、`name` がディレクトリ名と違うとき、`description` が空のときは失敗にする。
失敗の出力にはファイルのパスと理由を含める。

#### Scenario: 引用符の無いコロン
- **WHEN** `description` の値に `Argument: <name>` のような「コロンと空白」を引用符なしで含むスキルがある
- **THEN** `make verify-skills` は非ゼロで終わり、そのファイルのパスが出力される

#### Scenario: 正しい frontmatter
- **WHEN** すべてのスキルのfrontmatterがYAMLとして正しく、`name` がディレクトリ名と同じ
- **THEN** `make verify-skills` は終了コード0で終わる
