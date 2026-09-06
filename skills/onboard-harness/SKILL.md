---
name: onboard-harness
description: Bring a product repository onto the harness - decide what belongs there, place it, and deliver it as a draft pull request. Use when a repository should start using the harness, when its AGENTS.md or CLAUDE.md predates the harness, or when `uskn-harness onboard-check` reports missing items.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion
---

# onboard-harness: put a product repository on the harness

The harness supplies skills, hooks, and the installer from one place. A product repository carries only what is
specific to that product. This skill decides which of those files that repository needs, places the mechanical
ones, and leaves the judgement calls to a reviewed pull request.

## The rule about what goes in a repository

A product repository may carry `AGENTS.md`, `CLAUDE.md`, `openspec/`, `DESIGN.md`, `PRODUCT.md`, and a `verify`
target. That list is an **upper bound, not a checklist**:

| File | When it belongs |
|---|---|
| `AGENTS.md` | Always. The entry point: what the product is, where things are, the rules an agent cannot infer |
| `CLAUDE.md` | Always. `@AGENTS.md` plus Claude-specific lines, under 15 lines |
| `openspec/` | Always. `config.yaml` with `schema: uskn`, plus empty `specs/` and `changes/` |
| verify target | Always. Built from checks the repository already has; when it has none, say so rather than invent one |
| `DESIGN.md` | Only a repository with a user interface |
| `PRODUCT.md` | Only a repository with a user interface |

Everything else (skills, hooks, the git workflow, the writing and UI guidance) arrives through
`uskn-harness sync` and stays out of the product repository.

## Never edit the target working tree

The repository being onboarded is another project. Its live working tree stays untouched: the write guard denies
it, and the owner may be mid-task on a branch there. Work from a fresh clone in the scratchpad and deliver a
**draft** pull request, so the owner merges it when their own work allows.

## Steps

### 1. Look at the repository (read-only)

```bash
uskn-harness onboard-check <path-to-repo>
```

It reports what is missing without writing anything. Then read enough to write real content: `README`, the
existing `AGENTS.md` / `CLAUDE.md`, `package.json` scripts and dependencies, the test and lint setup, the
default branch, and (for a UI product) where colors and typography live today.

### 2. Decide what to place

Apply the table above. A repository with no UI gets four items, not six; say so in the report rather than
placing empty design files. If the repository has no deterministic check at all, the verify target says that,
and adding tests becomes its own change.

### 3. Place the mechanical parts

From `~/.local/share/uskn-harness/templates/repo/`, in the scratchpad clone:

- `openspec/config.yaml` with `schema: uskn`, and empty `openspec/specs/` and `openspec/changes/`
- `CLAUDE.md`, unless one already exists that is already short and points at `AGENTS.md`
- `Makefile` with the `verify` target, filled with the repository's real lint, type check, and test commands
- `AGENTS.md`: when the repository has none, start from the template. When it has one, add only the
  `## Branch model` block if the detected model needs an override
- `DESIGN.md` and `PRODUCT.md` for a UI product, with tokens read from the code that exists today

### 4. Leave the judgement calls to the pull request body

Some of onboarding is editing prose that belongs to the owner. Do not do it in the same commit; write it into
the pull request body as a checklist the reviewing session works through with the owner:

- Trimming an existing `AGENTS.md` down to product-specific facts. Command lists, general coding advice, and
  anything the harness skills already carry are candidates, quoted line by line
- Instructions that fight the harness, most often a Node version prefix from `nvm` where the harness uses mise
- `DESIGN.md` values the code cannot supply: typography, spacing, the reason behind a palette
- Project skills under `.claude/skills/` that shadow a user-layer skill

### 5. Open the draft pull request

```bash
cd "$SCRATCHPAD" && git clone --depth 1 <remote> <name> && cd <name>
git switch -c harness/onboard
# place the files, then:
git commit -q -F - <<'MSG'
ハーネスを導入する（機械的な部分）
...
MSG
git push -q -u origin harness/onboard
gh pr create --draft --base <default-branch> --title "..." --body-file <body.md>
```

The body carries the whole handoff: what the commit places, what still needs deciding, and how to verify. Write it
so it still reads on its own months later, because the pull request is the only copy.

### 6. Report

Say which items were placed, which were deliberately skipped and why, and the pull request URL.

## Worked example: a hardware documentation repository

`uskn75-kb` has no build, no tests, no CI, and no user interface. `onboard-check` reports four missing items.

- `DESIGN.md` and `PRODUCT.md`: skipped. There is no interface to design
- `AGENTS.md`: the repository's `CLAUDE.md` is the real entry point and holds design constraints that are the
  source of truth. Move it to `AGENTS.md` unedited; `CLAUDE.md` becomes `@AGENTS.md`. Compressing that prose is
  a separate decision for the owner
- verify: the repository already has a deterministic check. `tools/gen-layout.py` fails when the layout and the
  specification disagree, so `verify` runs it
- `openspec/`: placed, `schema: uskn`

The pull request body lists the one judgement call: whether `AGENTS.md` should later be split into an entry
point and a reference.
