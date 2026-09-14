---
name: no-grilling
description: Skip the grilling interview for a simple change on the user's instruction, record the skip in grilling.md, then generate proposal, specs, design, and tasks. Use when the user says to skip grilling, or when a change looks simple enough (typo, wording, a small fix inside existing requirements) that the interview would have nothing to decide - ask first. Arguments - a change name or a description, optionally --step.
allowed-tools: Bash(openspec:*), Bash(git:*), Read, Write, Edit, Glob, Grep, Skill, AskUserQuestion
---

# no-grilling: an OpenSpec change without the interview

Planning only, like `spec`: this skill never edits project code and ends with a pointer to `/opsx:apply`. It replaces
exactly one step of `spec` (the interview) with a recorded skip. The skip record satisfies the `grilling-guard` hook,
and the archive keeps it, so a skipped change stays findable.

## Arguments

Same as `spec`: a kebab-case name or a description (derive an ASCII kebab-case name), `--step` to confirm after each
artifact, or the name of an existing change to continue.

## Steps

### 1. Get the user's instruction

- The user typed `/no-grilling`, or wrote in this conversation that grilling should be skipped: that is the instruction. Go on.
- You are the one who thinks the change is simple: ask with `AskUserQuestion` whether to skip grilling for this change, stating the change in one line and why nothing is left to decide. Options: skip (no-grilling) and interview (`spec`). On "interview", run the Skill tool with `spec` and stop here.

Simple means the interview would have no decision to put to the user: a typo, wording, a small fix that stays inside
existing requirements. A change that adds a capability or reshapes behaviour belongs to `spec`; say so when you ask.

The step is done when the user's instruction exists in this conversation. Get a one-line reason for the skip from
the request itself, or ask for it along with the question.

### 2. Ground yourself

Do `spec` step 1 (read-only): relevant specs, `AGENTS.md`, and the `uskn` schema check.

### 3. Create the change and record the skip

```bash
openspec new change "<name>"          # skip when the change already exists
openspec instructions grilling --change "<name>" --json   # template + resolvedOutputPath
```

If the change already has `grilling.md`, leave it exactly as it is: that is an interview record. Go to step 4.

Otherwise write `grilling.md` from the template, headings and table columns unchanged. The table has one row, the
source is the user's instruction, and the state line uses the fixed wording, which is what a search of the archive
greps for. Example, for a change `fix-readme-typo` skipped on 2026-09-14:

```markdown
# grilling 記録: fix-readme-typo

## 決定

| 決定 | 選択 | 出典 |
|---|---|---|
| grillingの省略 | 省略する。理由：READMEのtypo修正のみで、決める論点が無い | ユーザーの指示（会話中に確認） |

## 後回しにしたもの

- なし

## 状態

grillingは省略した。ユーザーの指示を2026-09-14に確認済み。
```

### 4. Generate the remaining artifacts and finish

Do `spec` steps 4 and 5, including `--step`. With no interview behind the artifacts, a question that would change the
scope goes to the user before you write; a change that turns out not to be simple goes back to the user with the
option to run `spec` instead. The skill ends on the `/opsx:apply <name>` pointer.

## Language

Artifacts follow the project's OpenSpec config (Japanese in these repositories); your replies follow the user instructions.
