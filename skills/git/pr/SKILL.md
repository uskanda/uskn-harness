---
name: pr
description: Create a pull request (GitHub) or merge request (GitLab) from the repository's branch model. No argument targets the integration branch with auto-merge; the default branch as argument makes a release PR from the integration branch; the qa branch as argument makes a QA PR that keeps its source branch. Use for any "open a PR / MR" request.
allowed-tools: Bash, Read, Grep, Glob
---

# Create a pull request or merge request

## Context

Use the `<repo-context>` block injected at session start: platform (github / gitlab), CLI, and the default / integration / qa branches. If it is absent, run
`"${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}/plugins/uskn-harness/hooks/scripts/session-start.sh" --json`
and use its values. Run only the section for the detected platform; do not re-detect. Language of title and body: follow the user or repository instructions; default to Japanese.

## Choose the mode from `$ARGUMENTS`

| `$ARGUMENTS` | Mode | Source → target | Auto-merge | Title |
|---|---|---|---|---|
| empty | **integration** | current branch → integration | yes | see below |
| equals default, and integration ≠ default | **release** | integration → default | yes | `<default> YYYYMMDD HH:MM` (JST) |
| equals qa | **qa** | current branch → qa | yes, **source branch kept** | `<qa> YYYYMMDD HH:MM` (JST) |
| any other branch name | **custom** | current branch → that branch | yes | see below |

If the argument is the qa branch but the context has no qa branch (`qa: (none)`), do not create anything: report that this repository has no QA branch. If the argument equals default and integration equals default, treat it as the integration mode.

## Title and body (integration and custom modes)

- Commits to summarize: `git log --oneline origin/<target>..HEAD` (fetch first: `git fetch -q origin <target>`).
- Title: one line. If the branch is named `feature/<number>-<slug>`, or commit messages carry a `#<number>` prefix, prefix the title with `#<number>` (several: ascending order).
- Body: up to 10 markdown list lines with the purpose and the main changes.

## Title and body (release and qa modes)

- Timestamp: `TZ=Asia/Tokyo date '+%Y%m%d %H:%M'`.
- Release: list every change between the target and the source (`git log --oneline origin/<default>..origin/<integration>`), grouped by feature, not only the latest work.
- QA: list every change in `git log --oneline origin/<qa>..HEAD`.

## Safety rules for auto-merge

Auto-merge must wait for CI. Both hosts merge immediately when there is nothing to wait for, so:

1. After creating the PR / MR, poll for up to 3 minutes until a pipeline (GitLab `head_pipeline`) or at least one check (GitHub `gh pr checks`) exists.
2. If none appears, **do not enable auto-merge**. Report the URL and that CI never registered, and stop. The user decides about a manual merge.
3. After enabling auto-merge, re-read the state. If it already says merged, say so explicitly: the change bypassed the CI gate.

## GitHub

`gh pr create` needs the branch on the remote. Push first when the source is the current branch.

```bash
git push -u origin HEAD                      # integration / qa / custom modes only
gh pr create --base <target> --head <source> --title "<title>" --body "<body>"
```

If a PR for this branch already exists, do not create another; report `gh pr view --json url -q .url`.

```bash
N=<pr number>
for i in $(seq 1 18); do CHECKS=$(gh pr checks "$N" 2>/dev/null | wc -l); [ "$CHECKS" -gt 0 ] && break; sleep 10; done
echo "checks=$CHECKS"
```

`checks=0` after the loop: stop as described above. Otherwise:

```bash
gh pr merge "$N" --auto --merge              # qa mode: never add --delete-branch
gh pr view "$N" --json state,autoMergeRequest -q '.state, (.autoMergeRequest != null)'
```

If the repository has auto-merge disabled the merge command fails; report that a manual merge is needed. `MERGED` right away means it skipped CI; report it.

## GitLab

```bash
glab mr create --source-branch <source> --target-branch <target> --title "<title>" --description "<body>" --yes
PROJ=$(git remote get-url origin | sed -E 's#^(https?://[^/]+/|git@[^:]+:|ssh://git@[^/]+/)##; s#\.git$##' | sed 's#/#%2F#g')
ID=<mr id from the URL>
```

Wait for the MR pipeline; a fixed sleep is not enough:

```bash
for i in $(seq 1 18); do
  PSTATUS=$(glab api "projects/$PROJ/merge_requests/$ID" 2>/dev/null | jq -r '.head_pipeline.status // "none"')
  case "$PSTATUS" in none|"") sleep 10 ;; *) break ;; esac
done
echo "head_pipeline=$PSTATUS"
```

- `created` / `waiting_for_resource` / `preparing` / `pending` / `running`: continue.
- `success` / `failed` / `canceled` / `skipped` / `none`: stop without merging and report (auto-merge would merge immediately).

**QA mode only**: some projects delete the source branch on merge by default, and `glab mr update --remove-source-branch=false` is not reliably applied. Set it through the API and verify before merging:

```bash
glab api --method PUT "projects/$PROJ/merge_requests/$ID" -f remove_source_branch=false
glab api "projects/$PROJ/merge_requests/$ID" | jq -r .force_remove_source_branch   # must print false
```

If it does not print `false`, stop without merging and report. Then, for every mode:

```bash
glab mr merge "$ID" --auto-merge --yes       # never pass --remove-source-branch
glab mr view "$ID" 2>&1 | grep -E '^state:'  # opened = auto-merge set; merged = merged immediately, report it
```

QA mode: after the merge, confirm the source branch still exists with `git ls-remote --heads origin <source>`.

## Done

Report the PR / MR URL, the mode used, and the auto-merge outcome.
