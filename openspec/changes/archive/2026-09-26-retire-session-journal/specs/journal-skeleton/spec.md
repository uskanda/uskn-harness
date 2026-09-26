## REMOVED Requirements

### Requirement: journal の場所と名前
**Reason**: セッションjournalの仕組みを廃止する。Stop hookはjournalを作らない。
**Migration**: 既存の `~/.ai-sessions` はハーネスの管理から外れて残る。消すかはユーザーが決める。

### Requirement: 決定的な内容
**Reason**: journalを作らないので、事実の部分を生成するhookも要らない。
**Migration**: 何が変わったかは `git log` と `git diff` で確かめる。

### Requirement: エージェント欄の保全
**Reason**: journalを再生成するhookが無くなる。
**Migration**: 不要。決定はOpenSpecの成果物とADRに書く。

### Requirement: 決定欄を書かせる 1 回限りの block
**Reason**: journalへの記入を求める必要が無くなる。Stopでblockするのはverify gateだけになる。
**Migration**: 回避用の環境変数 `USKN_SKIP_JOURNAL` は意味を失う。設定していれば外してよい。

### Requirement: slug と title
**Reason**: journalのファイルが無くなり、改名するCLIも削除する。
**Migration**: 不要。
