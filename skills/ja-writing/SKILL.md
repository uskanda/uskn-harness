---
name: ja-writing
description: Japanese prose rules and the textlint check for anything a person reads in Japanese - commit messages, pull requests, OpenSpec artifacts, ADRs, docs, UI copy. Use before writing Japanese, and when the textlint hook or `make verify` reports problems in a Markdown file.
allowed-tools: Bash(textlint:*), Read, Edit, Write, Grep, Glob
---

# ja-writing: Japanese prose for people

The sensor for this guide is textlint with three presets and a terminology dictionary: `preset-ja-technical-writing`
(sentence quality), `@textlint-ja/preset-ai-writing` (patterns that read as machine-written), `preset-jtf-style`
(JTF 日本語標準スタイルガイド: notation), and `prh` with `prh.yml`. The PostToolUse hook `textlint-check` runs after
every Markdown write that contains Japanese; `make verify` runs the same config over the repository's live Japanese
documents. A finding is fixed by rewriting the sentence, never by loosening the rule.

## Register

Follows the artifact, and only one of the two appears in a document.

| Artifact | Register |
|---|---|
| Specs, ADRs, design notes, tasks, commit messages, table cells | 常体（〜する。〜しない。だ・である、体言止め可） |
| Pull request text, chat replies, UI copy, error messages | 敬体（です・ます） |

The linted corpus is all 常体, so `no-mix-dearu-desumasu` is set to `である` for both body and list items.
Mixing the two inside one document is the error the rule catches.

## Sentences

- One sentence, one point, under 100 characters. Split at 「〜し、」「〜が、」「〜ので、」 instead of chaining.
- State the fact or the decision. Hedges（〜と思われる、〜かもしれない）and flourishes（劇的に、革新的な）drop out.
- The same particle twice in one sentence is a finding: reorder, split, or reword.
- A bullet carries one item, said in words. Labels are plain（`hook: 役割`）, never bold or emoji.
- Requirements in an OpenSpec spec follow the EARS clause order; the templates live in the `uskn` schema's
  specs instruction, not here.

## Notation (JTF)

- **No space between full-width and half-width characters**: 「textlintの設定」, not 「textlint の設定」. The rule
  reads body text only, so headings and table cells keep whatever spacing they have.
- A space stays around inline code and links: 「`baseline` が無いとき」. The rule does not reach inside them.
- Full-width 「。」「、」「：」「（）」「［］」 in Japanese sentences. A full-width colon takes no space after it.
- One spelling per term, enforced by `prh.yml`（リポジトリ、ハーネス、ユーザー、サーバー）. Identifiers keep their
  English spelling: `uskn-harness`, `cross-repo`, `~/repos` are excluded by the dictionary's patterns.

## Names and terms

Four rules, the same in every language the harness writes. The sensor is `terms-check.sh`, run by a PostToolUse
hook and by `make verify`.

1. A name has one of three sources: an identifier that exists in the code or the paths, a term in
   `openspec/glossary.yml`, or a term from a document you actually consulted.
2. A new term needs a glossary entry first: the spelling, one sentence saying what it is, and the spellings to
   avoid. Define it where it first appears. Do not present it as if it were already established, and do not coin
   an abbreviation.
3. One concept, one term. Alternatives belong in the glossary as spellings to avoid, not in the prose.
4. A backticked name must exist. A name that stands for something not yet built is written `<like this>`.

## Check

```bash
textlint --config ~/.local/share/uskn-harness/skills/ja-writing/textlintrc.json --format compact <file.md>
textlint --config ~/.local/share/uskn-harness/skills/ja-writing/textlintrc.json --fix <file.md>
```

- `--fix` handles notation (spacing, colons, brackets, dictionary terms). Read the diff before keeping it: a
  dictionary substitution can leave a space behind between two Japanese words.
- A repository with its own `.textlintrc*` at the root uses that instead: run `textlint <file.md>` from the root.
- Prose that is not a file (a commit message, a PR body): write it to a scratch `.md`, lint that, then use it.
  The `commit` and `pr` skills do this.
- Done when the command prints no problems.

## Fixing findings

| Rule | Fix |
|---|---|
| `sentence-length` (max 100) | Split the sentence. A subordinate clause becomes its own sentence; a list inside a sentence becomes bullets. |
| `sentence-length` from one long path or identifier | Lift it out into a sentence of its own（`置き場は \`<path>\`。`）rather than shortening the prose around it. |
| `no-doubled-joshi`（同じ助詞が 2 回） | Reorder, split, or replace one of the 「と」「も」「に」 with a different construction. |
| `no-mix-dearu-desumasu` | The document is mixing registers. Pick the one its artifact calls for and convert the outliers. |
| `ja-no-redundant-expression`（〜を行う、〜することができる） | Use the verb directly（判定を行う → 判定する）. |
| `max-ten` / `max-comma` | Too many 、or , in one sentence: split it. |
| `ja-no-mixed-period` | Every sentence ends with 。, including the last one in a paragraph or a table cell. |
| `no-exclamation-question-mark` | State it as a sentence. |
| `no-unmatched-pair` | A half-width bracket paired with a full-width one. Make both full-width. |
| `jtf-style/3.1.1` | Remove the space between the Japanese and the ASCII word. `--fix` does it. |
| `jtf-style/4.2.7`, `4.3.2` | Colon and brackets become full-width. `--fix` does it. |
| `prh` | Use the dictionary's spelling. `--fix` does it; check that no stray space is left behind. |
| `ai-writing/no-ai-list-formatting` | Drop the bold label or emoji at the start of the item; say the item in words. |
| `ai-writing/no-ai-colon-continuation` | A sentence ending in 「:」 that continues below: end it with 。, or write 「次のとおり。」 and start the list. |
| `ai-writing/no-ai-hype-expressions`, `ai-tech-writing-guideline` | Replace the flourish with the fact it stands for. |

`textlint-disable` / `textlint-enable` comments are for quoted text and generated tables textlint cannot skip on
its own, not for prose you would rather not rewrite.

## Worked example

Before (four findings: length, doubled 「も」, redundant 「記録を行う」, space before 「は」):

> SessionStart hook は hosting とブランチモデルを判定して注入し、journal の直近要約も注入し、作業ツリーの指紋の記録も行う。

After:

> SessionStart hookはhostingとブランチモデルを判定して注入する。journalの直近要約も注入する。作業ツリーの指紋は別のスクリプトが記録する。
