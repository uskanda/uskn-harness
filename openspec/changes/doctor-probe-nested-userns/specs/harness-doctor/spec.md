## MODIFIED Requirements

### Requirement: sandbox の依存の検査
liveの `sandbox.enabled` が `true` のLinuxの端末で、`doctor` はsandboxの依存を1行で報告しなければならない（MUST）。
WSL2もLinuxの端末として扱う。
`bwrap` と `socat` のどちらかがPATHに無ければ `warn` とする。
`warn` には、無いコマンドの名前と、`bubblewrap` と `socat` を入れる案内と、無いあいだBashが制限なしで動くことを含める。
両方があるときの結果は、要件「入れ子のユーザー名前空間の確認」と要件「sandboxの中で動くdoctor」が決める。
`doctor` はどちらもインストールしない。

#### Scenario: bwrap の無い端末
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` が無く、`socat` はある
- **THEN** `warn` に `bwrap` と案内が含まれ、終了コードは0

#### Scenario: 両方ある端末
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` と `socat` がある
- **THEN** その行は、コマンドが無いことの `warn` ではない。`ok` か `warn` かは、入れ子の確認とsandboxの中かどうかで決まる

## ADDED Requirements

### Requirement: 入れ子のユーザー名前空間の確認
`doctor` がsandboxの外で動いている間、`bwrap` と `socat` の両方があれば、`doctor` は `bwrap` の中で入れ子のユーザー名前空間を作れるかを試さなければならない（MUST）。
対象の端末は、sandboxの依存を検査する端末（liveの `sandbox.enabled` が `true` のLinuxの端末）である。
作れれば `ok`、作れなければ `warn` とする。
`warn` には、sandboxの中のBashが全て失敗することと、新しい端末の手順の直し方を見る案内を含める。
`doctor` はAppArmorの設定を書き換えない。

#### Scenario: 入れ子を作れる端末
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` と `socat` があり、`bwrap` の中で入れ子のユーザー名前空間を作れる
- **THEN** その行は `ok`

#### Scenario: 入れ子を作れない端末
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` と `socat` があり、`bwrap` の中で入れ子のユーザー名前空間を作れない
- **THEN** その行は `warn` で、sandboxの中のBashが失敗することと、新しい端末の手順への案内が含まれ、終了コードは0

### Requirement: sandboxの中で動くdoctor
`doctor` がClaude Codeのsandboxの中で動いている間、`doctor` は入れ子のユーザー名前空間を試してはならない（MUST NOT）。
対象の端末は、sandboxの依存を検査する端末で、`bwrap` と `socat` の両方があるときに限る。
その行は `ok` とし、sandboxの中で動いているので試していないことを含める。
sandboxの中で動いていること自体が、その端末で入れ子を作れた証拠になる。sandboxの中から試すと、端末の設定に関係なく、sandboxの制限で失敗する。

#### Scenario: sandbox の中で動く doctor
- **WHEN** liveの `sandbox.enabled` が `true` のLinuxの端末に `bwrap` と `socat` があり、`doctor` がClaude Codeのsandboxの中で動く
- **THEN** その行は `ok` で、試していないことが含まれ、`bwrap` は起動されない
