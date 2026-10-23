---
name: cc-catchup
description: Check whether the current Claude Code now covers a harness feature, or calls for a change to one, and propose each finding as a GitHub issue labelled cc-catchup. Run by uskn-cc-catchup monthly, or by hand.
disable-model-invocation: true
---

# cc-catchup: find what Claude Code now covers

The harness exists to fill gaps in Claude Code. Claude Code ships often, so a gap the harness fills by hand may
have closed, or a new Claude Code feature may make a harness implementation or guide the wrong shape. This skill
finds those cases and proposes what to do, one GitHub issue per finding, labelled `cc-catchup`.

Two ways in:

- `uskn-cc-catchup run` (monthly, from cron) passes this file as the system prompt and runs in a fresh clone with
  read-only tools. The prompt names the installed Claude Code version, the previous run that succeeded, and the
  path of `issues.json`: every `cc-catchup` issue of every state, with its comments. Answer with the structured
  output below; the script files the issues.
- By hand (`/cc-catchup`) in the harness repository: list the issues yourself with
  `gh issue list --label cc-catchup --state all --limit 500 --json number,title,state,stateReason,body,comments`,
  show the proposals to the user, and file only the ones they approve, with
  `gh issue create --label cc-catchup --title <title> --body-file <file>`.

## Procedure

1. Map the harness. Read `AGENTS.md`, the 機能 table in `README.md`, every ADR under `docs/adr/`,
   `plugins/uskn-harness/hooks/hooks.json` and the scripts it names, the skills under `skills/`, `bin/`,
   `templates/user/settings.json`, and `deps.json`. For each feature note what it does and which Claude Code gap
   it fills; the ADRs usually say why it exists.
2. Learn the current Claude Code. Read the changelog at
   `https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md`: every entry since the previous
   run's version first (all of it when there was no previous run), then older entries when a feature needs them.
   The newest entries come first, and the file is long enough that one fetch shows only its beginning; ask for the
   versions you need by number. The installed version can lag behind the changelog; judge by the changelog.
   Read the documentation pages at `https://code.claude.com/docs/en/` that touch a harness feature: hooks, skills,
   slash commands, settings, memory, plugins, subagents, headless mode, permissions, and status line.
3. Match each harness feature against what Claude Code does now. A finding is one of two kinds:
   - `retire`: Claude Code now does the job itself, well enough that the harness copy only adds upkeep or
     conflicts with it. Example: a hook that injects something Claude Code now injects.
   - `change`: the feature still earns its place, but Claude Code changed under it. A new hook event, setting,
     frontmatter field, or command would do it more simply; it relies on behavior Claude Code deprecated or
     changed; or a guide tells agents to do what Claude Code now does or forbids.
4. Drop every finding without evidence on both sides: the Claude Code version and changelog line, or the
   documentation URL, that shows the change; and the harness paths it affects. A guess is not a finding.
5. Drop every finding that an existing `cc-catchup` issue already covers. Equivalent means the same harness feature
   with the same direction (retire it, or change it the same way), however the title is worded.
   - Closed as `NOT_PLANNED`, or any issue whose comments decline it: the decision stands. Do not propose it again,
     even with new evidence.
   - Open, or closed as `COMPLETED`: it is already tracked or done.
   Name the issues you skipped for this reason in the summary.
6. Write what is left. Fewer, well-founded proposals beat many thin ones, and none is a fine result. One proposal
   per harness feature; fold related evidence into it.

## Output

The structured output has two fields:

- `summary`: Japanese, a few sentences. What you checked, the Claude Code versions the evidence covers, and the
  issues you skipped as already decided (`#12` and so on).
- `proposals`: a list, possibly empty. Each item has:
  - `title`: Japanese, under 60 characters, naming the feature and the direction.
  - `kind`: `retire` or `change`, as in step 3.
  - `body`: the issue body, Japanese Markdown in the polite style (です・ます) that pull requests use, following
    the ja-writing rules. Sections, in this order:
    - `## 概要`: the proposal in one or two sentences.
    - `## 理由`: what changed in Claude Code, with the version, the changelog line or documentation URL, and a
      short quote. Then why the harness feature is now unnecessary or wrong.
    - `## ハーネスの現状`: the files and the behavior today, as paths (`plugins/uskn-harness/hooks/scripts/...`).
    - `## 推奨する実装`: concrete steps. Files to delete or change, the setting or frontmatter to use instead, the
      tests and sensors to remove or adjust, and whether an ADR or an OpenSpec change should record it.
    - `## 影響と移行`: what users of the harness and the product repositories notice, and the order of the work.

## Worked example

The harness had a SessionStart hook that printed the repository context because Claude Code could not. Suppose
the changelog for 2.1.300 says "SessionStart now includes the git remote, default branch, and host in the context".
The hook also detects the branch model from `AGENTS.md`, which Claude Code does not. That is a `change`, not a
`retire`:

```json
{
  "summary": "Claude Code 2.1.290〜2.1.310 の変更履歴と hooks、settings のドキュメントを確認しました。…",
  "proposals": [{
    "title": "repo-context から Claude Code が注入するリモート情報を外す",
    "kind": "change",
    "body": "## 概要\n\nSessionStart hook の repo-context のうち、…\n\n## 理由\n\n2.1.300 の変更履歴に …"
  }]
}
```

Had a closed `NOT_PLANNED` issue titled 「repo-context を縮める」 declined the same trim, the proposal would be
dropped and the summary would name that issue.
