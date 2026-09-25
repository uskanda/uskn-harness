## REMOVED Requirements

### Requirement: sessions リポジトリの配置
**Reason**: journalを貯める場所が要らなくなる。`sync` は `~/.ai-sessions` を作らず、`doctor` は検査しない。
**Migration**: 既存の `~/.ai-sessions` には触れない。消すかはユーザーが決める。

### Requirement: SessionEnd で commit
**Reason**: journalを確定するSessionEnd hookを削除する。
**Migration**: 不要。`hooks.json` からSessionEndの節を外す。
