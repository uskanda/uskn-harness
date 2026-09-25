## REMOVED Requirements

### Requirement: sessions リポジトリの検査
**Reason**: セッションjournalの仕組みを廃止し、`sync` が `~/.ai-sessions` を用意しなくなる。無いことを `warn` にする理由が無い。
**Migration**: `doctor` は `~/.ai-sessions` を検査しない。残っていても報告しない。
