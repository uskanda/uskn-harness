#!/usr/bin/env bash
# Host operations for bin/uskn-loop: the only file that calls gh or glab (openspec: loop-run; ADR-0006).
# Sourced, not executed. host_detect sets the globals the other functions read.
# shellcheck disable=SC2034  # HOST_KIND, HOST_NAME, REPO_PATH, and REPO_URL are read by the other files

# host_detect <top>: read origin's configured URL (before any insteadOf rewriting) and set HOST_KIND (github or
# gitlab), HOST_NAME, REPO_PATH (owner/repo, or group/.../project), and REPO_URL. A host whose name does not tell is
# asked of session-start.sh, which also knows the hosts registered in gh and glab. Fails for any other host.
host_detect() {
  local top="$1" url rest
  url="$(git -C "$top" config --get remote.origin.url 2>/dev/null)" || return 1
  case "$url" in
    *://*) rest="${url#*://}"; rest="${rest#*@}"; HOST_NAME="${rest%%/*}"; REPO_PATH="${rest#*/}" ;;
    *@*:*) rest="${url#*@}"; HOST_NAME="${rest%%:*}"; REPO_PATH="${rest#*:}" ;;
    *) return 1 ;;
  esac
  HOST_NAME="${HOST_NAME%%:*}"
  REPO_PATH="${REPO_PATH%/}"
  REPO_PATH="${REPO_PATH%.git}"
  case "$HOST_NAME" in
    ssh.github.com) HOST_NAME=github.com ;;
    altssh.gitlab.com) HOST_NAME=gitlab.com ;;
  esac
  case "$HOST_NAME" in
    *github*) HOST_KIND=github ;;
    *gitlab*) HOST_KIND=gitlab ;;
    *) HOST_KIND="$("$HOOKS/session-start.sh" --plain hosting "$top" 2>/dev/null)" ;;
  esac
  case "$HOST_KIND" in github | gitlab) ;; *) return 1 ;; esac
  [ -n "$REPO_PATH" ] || return 1
  REPO_URL="https://$HOST_NAME/$REPO_PATH"
}

_project() { jq -rn --arg p "$REPO_PATH" '$p | @uri'; }
_gh_api() { gh api --hostname "$HOST_NAME" "$@"; }
_glab_api() { glab api --hostname "$HOST_NAME" "$@"; }

# host_user: the login of the user gh or glab is signed in as.
host_user() {
  case "$HOST_KIND" in
    github) _gh_api user | jq -r '.login // empty' ;;
    gitlab) _glab_api user | jq -r '.username // empty' ;;
  esac
}

# host_pr <number>: the PR or MR as one JSON line: {state, draft, fork, author, head, base, conflict, url}, where
# state is open, closed, or merged.
host_pr() {
  case "$HOST_KIND" in
    github)
      gh pr view "$1" --repo "$HOST_NAME/$REPO_PATH" \
        --json state,isDraft,isCrossRepository,author,headRefName,baseRefName,mergeable,url |
        jq -c '{state: (.state | ascii_downcase), draft: .isDraft, fork: .isCrossRepository, author: .author.login,
                head: .headRefName, base: .baseRefName, conflict: (.mergeable == "CONFLICTING"), url}' ;;
    gitlab)
      _glab_api "projects/$(_project)/merge_requests/$1" |
        jq -c '{state: (if .state == "opened" then "open" else .state end), draft: (.draft // .work_in_progress // false),
                fork: (.source_project_id != .target_project_id), author: .author.username, head: .source_branch,
                base: .target_branch, conflict: (.has_conflicts // false), url: .web_url}' ;;
  esac
}

# host_comment_create <number> <body file>: post a comment on the PR or MR; prints its id.
host_comment_create() {
  case "$HOST_KIND" in
    github) _gh_api -X POST "repos/$REPO_PATH/issues/$1/comments" -F "body=@$2" | jq -r '.id // empty' ;;
    gitlab) _glab_api -X POST "projects/$(_project)/merge_requests/$1/notes" -F "body=@$2" | jq -r '.id // empty' ;;
  esac
}

# host_comment_update <number> <id> <body file>: replace the body of an existing comment.
host_comment_update() {
  case "$HOST_KIND" in
    github) _gh_api -X PATCH "repos/$REPO_PATH/issues/comments/$2" -F "body=@$3" >/dev/null ;;
    gitlab) _glab_api -X PUT "projects/$(_project)/merge_requests/$1/notes/$2" -F "body=@$3" >/dev/null ;;
  esac
}

# host_comment_find <number> <marker> <user>: the id of the first comment by <user> whose body holds <marker>.
host_comment_find() {
  case "$HOST_KIND" in
    github)
      _gh_api --paginate "repos/$REPO_PATH/issues/$1/comments" |
        jq -r --arg m "$2" --arg u "$3" '.[] | select(.user.login == $u and (.body | contains($m))) | .id' | head -n 1 ;;
    gitlab)
      _glab_api --paginate "projects/$(_project)/merge_requests/$1/notes" |
        jq -r --arg m "$2" --arg u "$3" '.[] | select(.author.username == $u and (.body | contains($m))) | .id' |
        head -n 1 ;;
  esac
}

# host_ready <number>: take the PR or MR out of draft.
host_ready() {
  case "$HOST_KIND" in
    github) gh pr ready "$1" --repo "$HOST_NAME/$REPO_PATH" >/dev/null ;;
    gitlab) glab mr update "$1" --ready -R "$REPO_URL" >/dev/null ;;
  esac
}
