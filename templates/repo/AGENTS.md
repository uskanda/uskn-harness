# <project name>

<!-- Entry point for coding agents. Keep it short: a table of contents plus the rules an agent
     cannot infer from the code. Product repositories may write the prose in Japanese. -->

## What this is

<One or two sentences: what the product does and who it is for.>

## Where things are

| Path | What lives there |
|---|---|
| `openspec/` | Specs and changes. Read `openspec/specs/` before changing behavior |
| `docs/` | <design notes, runbooks> |
| `<src dir>` | <one line per major area> |

## How to work here

- Spec decisions go through the grilling interview before any OpenSpec proposal.
- Verification: `make verify` (or `pnpm run verify` / `npm run verify`). It must pass before a change is done.
- <build / run commands only if they are not discoverable from package.json, Makefile, or README>

## Branch model

<!-- Optional. The harness detects default (origin/HEAD), integration (`develop` if it exists, else default)
     and qa (`qa` if it exists) on its own. Add this block only to override. `qa: none` disables the QA
     branch. release_tag: calver means vYY.MM.X. -->

```yaml
default: main
integration: develop
qa: none
release_tag: calver
```

## Rules that are not in the code

- <"never do X" items, with the reason>
- <conventions a linter cannot enforce>
