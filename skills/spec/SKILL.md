---
name: spec
description: Turn an idea into an OpenSpec change the harness way - run the grilling interview first, record it as grilling.md, then generate proposal, specs, design, and tasks. Use whenever the user wants to plan, spec, or propose a change, or to continue an unfinished change. Arguments - a change name or a description, optionally --step to confirm each artifact.
allowed-tools: Bash(openspec:*), Bash(git:*), Read, Write, Edit, Glob, Grep, Skill, AskUserQuestion
---

# spec: from idea to OpenSpec artifacts, interview first

Planning only. This skill never edits project code. It ends with the artifacts and a pointer to `/opsx:apply`.
The `grilling-guard` hook denies writes to proposal / design / tasks / specs of a change that has no `grilling.md`,
so the order below is not optional.

## Arguments

- empty: ask, open-ended, what the user wants to build or fix.
- a kebab-case name, or a description: derive an ASCII kebab-case name from a description (`ユーザー認証を追加` → `add-user-auth`).
- `--step`: confirm with the user after each artifact instead of generating all at once.
- the name of an existing directory under `openspec/changes/`: continue mode. Skip to step 4 and finish what `openspec status` reports as missing (if `grilling.md` is missing there too, do step 2 first).

## Steps

### 1. Ground yourself (read-only)

- `openspec list --specs` and skim the capabilities that the idea touches; read `AGENTS.md`.
- Confirm the repository uses the harness schema: `openspec status --change <any existing change> --json` lists a `grilling` artifact, or `openspec/config.yaml` says `schema: uskn`. If not, stop and tell the user to run `uskn-harness sync` and set `schema: uskn`.

### 2. Interview

Run the Skill tool with `grilling` about the idea. Facts (what the code does today, what the specs already require) are yours to look up between rounds; decisions are the user's. Keep going until the frontier is empty and the user confirms shared understanding.

Do not run `openspec new change` before that confirmation.

### 3. Create the change and record the interview

```bash
openspec new change "<name>"
openspec instructions grilling --change "<name>" --json   # template + resolvedOutputPath
```

Write `grilling.md` from the interview that actually happened: one table row per question asked (the decision, the option chosen, `round N Qn`), the items deliberately deferred, and the state line with today's date. Never invent rows; if the interview showed there was nothing to decide, say so in the table with the questions that established it.

### 4. Generate the remaining artifacts

Loop until `openspec status --change "<name>" --json` reports every artifact in the required set done or skipped:

1. Pick a `ready` artifact. `openspec instructions <id> --change "<name>" --json` gives `context` and `rules` (constraints for you, never copied into the file), `template`, `instruction`, `resolvedOutputPath`, and completed dependencies to re-read from disk.
2. Inspect the relevant code and existing specs before writing; ground scope and tasks in what you find.
3. Write the file. Specs: one per capability from the proposal, delta format, `## Purpose` only for new capabilities. `design.md` is conditional per its instruction; specs are only skipped when status says `skipped`.
4. Base every artifact on `grilling.md`; do not reopen settled questions. Anything the interview did not cover and that would change scope goes back to the user before writing.
5. With `--step`: after each artifact, summarize it in a few lines and ask with `AskUserQuestion` whether to continue. Stop on decline.

### 5. Finish

`openspec validate "<name>" --strict`, then `openspec status --change "<name>"`. Report the artifacts created (and any conditional one skipped, with the reason) and end with: implementation starts with `/opsx:apply <name>`.

## Language

Artifacts follow the project's OpenSpec config (Japanese in these repositories); your replies follow the user instructions.
