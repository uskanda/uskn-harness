---
name: sandbox-exclude
description: Run a well-known tool outside the Claude Code sandbox on this machine, after the user asked for it. Also lists or removes the patterns this machine added.
argument-hint: "<tool or pattern> | --list | --remove <pattern>"
disable-model-invocation: true
allowed-tools: Bash
---

# sandbox-exclude: take a tool out of the sandbox on this machine

The Claude Code sandbox keeps execution whose effect cannot be read beforehand (scripts, builds, tests) inside, and
lets well-known tools whose effect the command shows run outside: bash-guard and the auto mode classifier judge those.
The outside list is `sandbox.excludedCommands`. The harness ships the defaults; this skill adds a pattern for this
machine only, through `uskn-harness sandbox-exclude`, which writes `~/.config/uskn-harness/settings.json` and applies
the user settings. The user typed `/sandbox-exclude`; taking a command out of the sandbox loosens a guard, so it is
the user's call.

## Steps

### 1. Read the argument

- `--list`: run `uskn-harness sandbox-exclude --list` and show it. Done.
- `--remove <pattern>`: run `uskn-harness sandbox-exclude --remove '<pattern>'`. A default pattern exits 2 and says a
  pull request to the harness is needed: report that. Then go to step 4.
- A tool name (`terraform`): the pattern is `<tool> *`, here `terraform *`.
- A pattern already (it holds a space and `*`, such as `kubectl apply *`): use it as given.
- Empty: ask which tool, and wait.

### 2. Keep execution whose effect cannot be read beforehand inside

Interpreters, build tools, and script runners decide at run time what they write, so they stay in the sandbox:
`npm`, `pnpm`, `npx`, `make`, `python`, `node`, `bash`, `sh`, and the like. When the pattern starts with one of
them, say why it stays inside and that a failure inside the sandbox is still retried outside after a permission
check. Go on only when the user asks again.

### 3. Add the pattern

Run the command on its own, never after `cd` or before a pipe: `excludedCommands` only matches the start of the
whole command, and `uskn-harness` itself runs outside the sandbox only when it comes first.

```bash
uskn-harness sandbox-exclude 'terraform *'
```

Exit 2 means the pattern was refused (empty or a bare `*`): report the message.

### 4. Report

Run `uskn-harness sandbox-exclude --list` and show the lines marked `machine`. Say that the change applies to new
sessions, and that a pattern every machine needs goes into `templates/user/settings.json` through a pull request to
the harness.

## Example

`terraform plan` failed in the sandbox with `Read-only file system` under `~/.terraform.d`, and you suggested
`/sandbox-exclude terraform`. The user types `/sandbox-exclude terraform`. The pattern is `terraform *`; terraform is
not a script runner, so step 2 passes. You run `uskn-harness sandbox-exclude 'terraform *'` on its own, then
`--list`, and report: "`terraform *` now runs outside the sandbox on this machine (machine). New sessions use it."
