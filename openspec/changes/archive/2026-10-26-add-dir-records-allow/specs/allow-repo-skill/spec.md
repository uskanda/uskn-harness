## REMOVED Requirements

### Requirement: セッション限定の追記
**Reason**: ユーザーが `/add-dir` を実行すると、`DirectoryAdded` のhookがセッションの許可ファイルに記録する。`/allow-repo` を別に打つ必要が無くなった。
**Migration**: ルートの外で作業するときは、ユーザーが `/add-dir <path>` を実行する。許可の一覧は `allow-repo.sh --list` で読める。

### Requirement: /add-dir の案内
**Reason**: `/add-dir` が許可ファイルへの記録も行うため、`/allow-repo` から `/add-dir` へ案内する必要が無くなった。
**Migration**: ユーザーは `/add-dir <path>` だけを実行する。
