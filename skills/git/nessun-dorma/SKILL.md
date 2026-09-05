---
name: nessun-dorma
description: Autonomous work mode for when the user will be away for hours. Proceed through the planned tasks without waiting for answers, record provisional decisions, and finish with a consolidated report. Use only when the user invokes it.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Agent, TodoWrite
disable-model-invocation: true
---

# Autonomous work mode

The user cannot answer for at least three hours. Work through the planned tasks on your own.

## Rules

1. Follow the existing plan and its priorities (OpenSpec tasks when the repository has them).
2. When a decision is needed, choose a reasonable provisional answer, note it, and keep going. Collect all of them for the final report.
3. Stay within the repository's constraints: the verify convention (`make verify` or `pnpm run verify`), no edits outside the working repository, no pushes or PRs unless the plan says so.
4. Run tests and builds as you go; on errors, try to fix them yourself before moving on.

## Loop

1. Confirm the task list and its order.
2. Implement each task in order, verifying as you finish it.
3. Log open questions and provisional decisions as you meet them.
4. Continue until the list is done or something genuinely blocks you.

## Final report (always)

### 1. Progress
- Tasks completed and what changed in each
- Tasks not completed, and why

### 2. Points for the user to confirm
- Provisional decisions taken
- Implementation choices that need sign-off
- Questions

### 3. Next actions
- Remaining tasks
- Items waiting on the user
