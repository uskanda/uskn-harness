---
name: en-writing
description: English prose rules for text a person reads - README and docs of English projects, pull request text in English repositories, UI copy, error messages, release notes. Use before writing such English and to audit it with agent-style and humanizer. Agent-facing documents (SKILL.md, AGENTS.md, hook comments) follow writing-for-agents instead.
allowed-tools: Bash(agent-style:*), Read, Edit, Write, Skill
---

# en-writing: English prose for people

Two references and two passes. The rules are agent-style's 21 (12 from Strunk & White, Orwell, Pinker, Gopen &
Swan; 9 observed in LLM output); the sensor is `agent-style review`; the final pass is `humanizer`.

## Scope

- In: anything a person reads in English. README, docs, PR text and commit messages in English repositories, UI
  copy, error messages, changelogs, issue reports.
- Out: documents an agent consumes (SKILL.md, AGENTS.md, CLAUDE.md, hook comments). Those follow the
  `writing-for-agents` skill; its levers (pointers, leading words, pruning) conflict with several prose rules
  below, and the agent's behaviour is the test.
- Japanese text: `ja-writing`.

## Rules

`agent-style rules` prints the full reference (directive, 5+ BAD → GOOD pairs, rationale per rule);
`"$(agent-style path)/rule-pack-compact.md"` is the one-pair-per-rule version. Read the compact pack once per
session before writing. The rules that most often fire on agent output:

| Rule | Directive |
|---|---|
| RULE-A | Prose stays prose; bullets only for a genuine list |
| RULE-B | No em or en dashes as sentence punctuation; use a comma, colon, or a new sentence |
| RULE-C, RULE-D, RULE-E | Vary sentence openings; drop "Additionally / Furthermore"; no summary sentence closing every paragraph |
| RULE-H | Every factual claim carries evidence or a citation; unsupported ones are cut, not softened |
| RULE-08 | Claims match the evidence: neither "proves" nor "may perhaps" |
| RULE-03, RULE-04 | Concrete terms over category words; needless words out |
| RULE-12 | Sentences over 30 words are split |

RULE-G (Title Case headings) yields to the target repository's own heading convention.

## Voice samples

`~/.local/share/uskn-harness/assets/voice/en/` may hold samples of the owner's English. When it has files, read them
before writing and hand them to humanizer as the writing sample. When it is empty, write from the rules.

## Check

```bash
agent-style review --audit-only <file.md>     # deterministic audit, JSON: violations per rule with line numbers
```

Fix every mechanical violation (RULE-B, D, G, I, 12, 05, 06, A, C, E) by rewriting; for rules the audit marks
`skipped` (semantic ones: 01, 02, 03, 04, 07, 08, 11, F, H) judge the text yourself against the directive. Done
when the audit reports no mechanical violations, or each remaining one has a reason you can state.

## Final pass

Run the Skill tool with `humanizer` on the finished text, passing the voice sample when one exists. It removes AI
patterns without changing claims. Read its output against the audit once more; humanizer may reintroduce a dash
or a bullet.
