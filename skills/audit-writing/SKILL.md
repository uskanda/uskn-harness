---
name: audit-writing
description: Audit and repair the terminology and prose of an existing repository in one pass - inventory the vocabulary, build the glossary with the user, then fix and verify. Use when a repository has never had a glossary, when its documents mix names for the same thing, or when the terms check reports many findings.
allowed-tools: Bash, Read, Edit, Write, Grep, Glob, AskUserQuestion, Skill
---

# audit-writing: bring an existing repository's prose under the guides

Four stages, in order: inventory, glossary, repair, verify. The order matters. Running the checks first and
fixing what they report leaves a repository with no glossary exactly where it started, because the terms check
can only compare against a glossary that does not exist yet.

Never invent a definition. A term whose meaning you cannot establish from the code or the documents is a
question for the user, not a gap to fill.

## 1. Inventory (read only)

Nothing is written in this stage. Collect four things and keep them in one scratch file.

```bash
R=$(git rev-parse --show-toplevel); H=${USKN_HARNESS_DIR:-$HOME/.local/share/uskn-harness}
mapfile -t DOCS < <(git -C "$R" ls-files '*.md' | grep -v -E '/(archive|node_modules)/')
# a. vocabulary: katakana runs and 「quoted」 terms in prose, by frequency
python3 - "$R" "${DOCS[@]}" <<'PY'
import re,sys,os,collections
root,*docs=sys.argv[1:]
c=collections.Counter(); q=collections.Counter()
for d in docs:
    t=open(os.path.join(root,d),encoding="utf-8",errors="ignore").read()
    t=re.sub(r"^```.*?^```","",t,flags=re.S|re.M); t=re.sub(r"`[^`\n]*`","",t)
    c.update(re.findall(r"[ァ-ヶー]{3,}",t)); q.update(re.findall(r"「([^」\n]{3,20})」",t))
for w,n in c.most_common(60): print(f"{n:4}  {w}")
print("---- quoted ----")
for w,n in q.most_common(30): print(f"{n:4}  {w}")
PY
# b. names that do not exist, and terms already known
"$H/plugins/uskn-harness/hooks/scripts/terms-check.sh" "${DOCS[@]}"
# c. the prose checks, if the repository has them
textlint --config "$H/skills/ja-writing/textlintrc.json" --format compact "${DOCS[@]}" | tail -40
```

Then read the top of the frequency list yourself and mark the candidates:

- **Two words, one concept.** The same thing called `repo` in one document and リポジトリ in another.
- **One word, two concepts.** A word whose meaning changes between documents.
- **Vague or coined.** A word that carries weight in the prose but has no definition anywhere, and that a
  newcomer to the project would not know.

Report the inventory in a few lines: how many documents, how many distinct terms, how many candidates, how many
non-existent names. Do not propose fixes yet.

## 2. Glossary, with the user

Read `openspec/glossary.yml` first when it exists; append, never overwrite.

Work in rounds of at most ten candidates. For each candidate ask, with `AskUserQuestion` where the choice is
closed and in prose where it is open:

1. the spelling to use,
2. one sentence saying what it is (not what it does),
3. the spellings to avoid.

Take the definition from the user or from the code. When neither settles it, leave the term out of the glossary
and list it as unresolved; a wrong definition is worse than a missing one.

Write each confirmed round to `openspec/glossary.yml` before starting the next, in the format the
`terminology-guard` spec sets. Stop when the candidates are exhausted or the user says enough.

## 3. Repair

Only terms that reached the glossary are rewritten.

1. Aliases → the spelling to use. Rewrite by hand or with a scripted replacement, then read the diff. A
   substitution inside an identifier, a path, or a code block is a mistake; revert it.
2. `textlint --fix` for notation, then the findings that need a human sentence.
3. Non-existent names: correct them to the real name, turn them into `<placeholder>` form, or add them to
   `openspec/known-names.txt` when they are real but live in another system.
4. Records stay as written: `openspec/changes/archive/`, and any document the repository keeps as history.

## 4. Verify and report

Run the repository's verify convention (`make verify`, else `pnpm run verify` / `npm run verify`). When it has
none, run the checks from stage 1 again.

Report four numbers and one list: documents touched, terms added to the glossary, findings fixed, findings that
remain, and the terms left unresolved with the question that blocks each one.

## Notes

- The glossary lives at `openspec/glossary.yml` in every repository, harness included.
- A repository with its own `.textlintrc*` uses that; do not replace it.
- This skill edits only the repository it runs in. Another repository's changes go through a pull request or a
  handoff document.
