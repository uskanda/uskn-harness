---
name: spec-pr
description: Open a draft spec PR (GitHub) or MR (GitLab) for one OpenSpec change, from an existing change or a new idea. Use when the user asks to turn a change into a spec PR.
argument-hint: "[change-name | description]"
allowed-tools: Bash, Read, Glob, Grep, Skill, AskUserQuestion
---

# spec-pr: one OpenSpec change as a draft spec PR

A spec PR carries exactly one change directory, `openspec/changes/<name>/`, on the branch `change/<name>`, as a
draft PR (GitLab: draft MR) against the integration branch. It is the work order for implementing the change, by hand
with `/opsx:apply` or by the loop with `uskn-loop run`. It never gets auto-merge.

Every check runs before the branch exists, so a stop leaves nothing to undo. This skill runs git, `gh`, and `glab`
itself: the `pr` skill enables auto-merge in its integration mode, and the `push` skill commits every uncommitted
change first. The user's other uncommitted work stays exactly as it was.

## Context

Use the `<repo-context>` block injected at session start: platform (github / gitlab), CLI, and the integration
branch. If it is absent, run `uskn-repo-context --json` and use its values. Below, `<integration>` is that branch.

## Arguments

- The name of a directory under `openspec/changes/` (not under `archive/`): that change is the target.
- A description of an idea: run the Skill tool with `spec` and the description. When it has written the artifacts,
  the change it created is the target. If `spec` stops before its artifacts are complete, stop too.
- Empty: the only active change from `openspec list --json`. With several, ask which one with `AskUserQuestion`.

Announce the target change.

## Steps

### 1. Check (read-only)

Stop at the first failure and report it. Nothing has been created yet.

1. `git branch --show-current` names a branch. Remember it as `<orig>`. A detached HEAD: stop.
2. `openspec status --change "<name>" --json` reports every required artifact done or skipped. Otherwise stop and
   list the missing artifacts.
3. `openspec validate "<name>" --strict` passes. Otherwise stop with its output.
4. The change is unpublished:

   ```bash
   git fetch -q origin "<integration>"
   git cat-file -e "origin/<integration>:openspec/changes/<name>"                 # succeeds: already published
   git log --oneline "origin/<integration>..HEAD" -- "openspec/changes/<name>"    # any output: committed, unpushed
   ```

   Already published: stop and say the change is on `<integration>`. Committed but unpushed: stop and say so; the
   history stays as it is.
5. The branch name is free: both `git show-ref --verify --quiet "refs/heads/change/<name>"` and
   `git ls-remote --exit-code --heads origin "change/<name>"` fail. Otherwise stop and name the existing branch.

### 2. Branch and commit

```bash
git switch -c "change/<name>" "origin/<integration>"
```

The untracked change directory comes along, and so does any other uncommitted work. If git refuses because local
edits collide with `<integration>`, it creates no branch and stays on `<orig>`: report the colliding files and stop.

`commit` runs as a fork and sees only its argument. Run the Skill tool with `commit` and this Japanese argument:

```
openspec/changes/<name>/ だけを1つのコミットにする。要約行は「<name>の仕様を追加」。ほかの未コミットの変更は未コミットのまま残す。
```

Then `git diff --name-only "origin/<integration>..HEAD"` lists only paths under `openspec/changes/<name>/`. If it
lists anything else, stop before pushing: report the commit and the branch, and leave both for the user.

### 3. Push

```bash
git push -u origin "change/<name>"
```

A rejected push: stop and report; the branch stays local.

### 4. Title and body

The title is the point of `proposal.md` in one Japanese line. The body is Japanese in 敬体, with three sections:

```markdown
## 概要

<proposal.md の Why と What Changes を2〜4文で要約する>

## 成果物

- [grilling](<base>/blob/change/<name>/openspec/changes/<name>/grilling.md)
- [proposal](<base>/blob/change/<name>/openspec/changes/<name>/proposal.md)
- [specs](<base>/tree/change/<name>/openspec/changes/<name>/specs)
- [design](<base>/blob/change/<name>/openspec/changes/<name>/design.md)
- [tasks](<base>/blob/change/<name>/openspec/changes/<name>/tasks.md)

## 進め方

- ループで実装する：`uskn-loop run <このPRの番号>`
- 手元で実装する：`git switch change/<name>` のあと `/opsx:apply <name>`
- 確認のあと、このブランチで `/archive-push <name>` を実行してからマージする
```

- `<base>` is `gh repo view --json url -q .url` on GitHub. On GitLab it is the `web_url` of `glab repo view -F json`
  followed by `/-`, so the links read `<web_url>/-/blob/...` and `<web_url>/-/tree/...`.
- Drop the design line when the change has no `design.md`.
- The tasks stay in `tasks.md`; the body links to them and copies none.

Write the body to a file in a new `mktemp -d` directory, outside the repository. Lint a copy with the title as a
heading on top:

```bash
textlint --config ~/.local/share/uskn-harness/skills/ja-writing/textlintrc.json --format compact <copy>.md
```

Fix what it reports; the `ja-writing` skill has the rules. When textlint is not installed, skip the lint and say so.

### 5. Open the draft

GitHub:

```bash
gh pr create --draft --base "<integration>" --head "change/<name>" --title "<title>" --body-file <body>.md
```

GitLab:

```bash
glab mr create --draft --source-branch "change/<name>" --target-branch "<integration>" \
  --title "<title>" --description "$(cat <body>.md)" --yes
```

The draft is complete as created: it stays a draft with no auto-merge, for the implementation to fill.

### 6. Return and report

```bash
git switch "<orig>"
```

Report:

- the PR or MR URL, the branch `change/<name>`, and the commit
- that the change directory now lives on `change/<name>` and left the `<orig>` working tree, and that
  `git switch change/<name>` brings it back for local work
- the next step: `uskn-loop run <number>` for the loop, or `/opsx:apply <name>` on the branch by hand

## Examples

`/spec-pr add-x` on `main` right after `/spec add-x`, with an unrelated uncommitted edit to `README.md`: every check
passes. `change/add-x` starts from `origin/main` and gets one commit, `add-xの仕様を追加`, holding only
`openspec/changes/add-x/`. The push succeeds and draft PR #31 targets `main` with no auto-merge. The run switches back
to `main`, where the `README.md` edit is still uncommitted, and reports the URL and `git switch change/add-x`.

`/spec-pr add-y` where `openspec/changes/add-y/` is already on `origin/main`: step 1.4 stops with "already on
`main`". No branch, commit, push, or PR exists afterwards.
