---
name: ui-guidelines
description: Entry point for building, changing, or reviewing a user interface (web, React Native / Expo), and for DESIGN.md or PRODUCT.md. Use before writing UI code or critiquing screens.
allowed-tools: Bash(designmd:*), Bash(npx:*), Bash(git status:*), Bash(git restore:*), Read, Write, Edit, Glob, Grep, Skill
---

# ui-guidelines: DESIGN.md and PRODUCT.md first

## Sources of truth

- `DESIGN.md` at the repository root, in the Google DESIGN.md format: design tokens in YAML front matter (normative
  values for colors, typography, spacing, rounded, components) and `##` sections of prose (why the values are what
  they are, how to apply them). `designmd spec` prints the format.
- `PRODUCT.md` at the root: platform, users, purpose, positioning, brand commitments, accessibility baseline. Its
  section names are what Impeccable reads.
- Missing either file: copy `~/.local/share/uskn-harness/templates/repo/DESIGN.md` / `PRODUCT.md`, fill them from
  what the repository already shows (theme files, CSS variables, `app.json`, existing screens), then ask the user to
  confirm palette, type, and shape before writing UI. Brand facts are the owner's; leave a placeholder rather than
  invent one.
- Every DESIGN.md edit ends with `designmd lint DESIGN.md`: 0 errors, and each warning read (broken token
  reference, missing primary, contrast below WCAG AA). `designmd export --format css-tailwind DESIGN.md` when the
  project consumes tokens through Tailwind v4; `dtcg` for a tokens.json.

## Working on a surface

1. Read DESIGN.md and PRODUCT.md. Values in the UI come from the tokens; a value not in DESIGN.md is added there
   first, with its reason in the prose.
2. Impeccable reviews and refines. `/impeccable audit <target>` (a11y, performance, responsive), `critique`
   (hierarchy, clarity), `polish` before shipping, `harden` (errors, i18n, overflow), `adapt` (devices),
   `clarify` (copy), `layout`, `typeset`, `bolder` / `quieter`. Its `context` step reads PRODUCT.md and
   DESIGN.md. The commands that write those files in Impeccable's own format stay unused: `init`, `document`,
   `extract`, `doctor`. What Impeccable writes anyway is undone (next section).
3. React Native / Expo (`app.json` with `expo`): the Expo official skills are installed per project
   (`npx skills add expo/skills -y` from the repository root; look for `skills-lock.json` or `.claude/skills/`).
   Native specifics (safe areas, platform type scales, haptics, navigation idioms) live in DESIGN.md prose; the
   Impeccable native variants of `audit` and `adapt` apply.
4. A new web surface with no DESIGN.md yet, where the user wants a visual direction explored: run the Skill tool
   with `frontend-design`, then record the choices it made as DESIGN.md tokens and prose before continuing.

## What Impeccable writes on its own

Impeccable's build of a new surface (skill 4.2.3 and later) ends with its documenter, which writes DESIGN.md in
Impeccable's schema plus a sidecar, `.impeccable/design.json`. Neither is adopted: the repository's DESIGN.md stays
the source of truth.

1. After every Impeccable command, run `git status --short -- DESIGN.md .impeccable`.
2. Undo Impeccable's writes. A tracked DESIGN.md: `git restore DESIGN.md`. A DESIGN.md it created: delete it and
   start from the template (Sources of truth). Delete `.impeccable/design.json`.
3. A decision worth keeping goes into DESIGN.md by hand, as tokens and prose in the Google format, then
   `designmd lint DESIGN.md`.

Its staleness check ("DESIGN.md is stale", "sidecar missing") is switched off by `IMPECCABLE_NO_STALENESS_CHECK=1`
in the `env` of the user's `~/.claude/settings.json`, which the dotfiles manage; `uskn-harness doctor` warns while it
is unset. Never add `.impeccable/config.json` to a product repository to silence it. Where the variable is unset,
note the warning in the report and go on; do not run `/impeccable doctor` or `document` over it.

Example: an Impeccable build of a new settings screen, in a repository whose DESIGN.md is tracked. `git status` shows
` M DESIGN.md` and `?? .impeccable/`. Run `git restore DESIGN.md`, delete `.impeccable/design.json`, add the one new
spacing token the screen needed to DESIGN.md with a sentence of prose, and lint.

## Done when

- `designmd lint DESIGN.md` has 0 errors and the touched UI uses tokens, not literals.
- `git status --short -- DESIGN.md .impeccable` shows nothing Impeccable wrote.
- For a surface that ships: `/impeccable audit` run on it, findings fixed or listed in the report.
- PRODUCT.md still describes the product; a change of platform or audience updates it in the same change.
