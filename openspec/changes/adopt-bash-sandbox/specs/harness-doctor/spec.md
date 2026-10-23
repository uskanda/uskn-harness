## ADDED Requirements

### Requirement: sandbox の依存の検査
liveの `sandbox.enabled` が `true` のLinuxの端末で、`doctor` はsandboxの依存を1行で報告しなければならない（MUST）。
WSL2もLinuxの端末として扱う。
`bwrap` と `socat` の両方がPATHにあれば `ok`、どちらかが無ければ `warn` とする。
`warn` には、無いコマンドの名前と、`bubblewrap` と `socat` を入れる案内と、無いあいだBashが制限なしで動くことを含める。
`doctor` はどちらもインストールしない。

#### Scenario: bwrap の無い端末
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` が無く、`socat` はある
- **THEN** `warn` に `bwrap` と案内が含まれ、終了コードは0

#### Scenario: 両方ある端末
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` と `socat` がある
- **THEN** その行は `ok`

### Requirement: sandbox の依存を検査しない端末
macOSの端末と、liveの `sandbox.enabled` が `true` でない端末で、`doctor` はsandboxの依存を報告してはならない（MUST NOT）。
macOSのsandboxは、OSに付属する仕組みで動くため。

#### Scenario: macOS
- **WHEN** liveの `sandbox.enabled` が `true` のmacOSの端末で `doctor` を実行する
- **THEN** sandboxの依存の行は報告に現れない

#### Scenario: sandbox を切った端末
- **WHEN** 端末別設定で `sandbox.enabled` を `false` にし、sync後に `doctor` を実行する
- **THEN** sandboxの依存の行は報告に現れない
