---
name: ja-writing
description: Japanese prose rules and the textlint check for anything a person reads in Japanese (commits, pull requests, OpenSpec artifacts, docs). Use before writing Japanese and when textlint reports problems.
allowed-tools: Bash(textlint:*), Read, Edit, Write, Grep, Glob
---

# ja-writing: Japanese prose for people

The sensor for this guide is textlint with three presets, a terminology dictionary, and a pattern list:
`preset-ja-technical-writing` (sentence quality), `@textlint-ja/preset-ai-writing` (patterns that read as
machine-written), `preset-jtf-style` (JTF 日本語標準スタイルガイド: notation), `prh` with `prh.yml`, and
`@textlint-rule/pattern` (metaphor verbs; the list lives in `textlintrc.json`). The PostToolUse hook `textlint-check`
runs after every Markdown write that contains Japanese; `make verify` runs the same config over the repository's live
Japanese documents. A finding is fixed by rewriting the sentence, never by loosening the rule. What textlint cannot
see, the reread below catches.

## Register

Follows the artifact, and only one of the two appears in a document.

| Artifact | Register |
|---|---|
| Specs, ADRs, design notes, tasks, commit messages, table cells | 常体（〜する。〜しない。だ・である） |
| Pull request text, chat replies, UI copy, error messages | 敬体（です・ます） |

体言止め（ending on a noun）belongs to table cells, bullet items, headings, and a commit's summary line
（`archive-push` writes 「`<name>`をarchiveし、main specsに反映」）. A sentence in body text ends on its predicate.

The linted corpus is all 常体, so `no-mix-dearu-desumasu` is set to `である` for both body and list items.
Mixing the two inside one document is the error the rule catches.

## Sentences

These hold everywhere Japanese is written, chat replies included. Write *plain* sentences: a reader rebuilds who
does what to what, and under which condition, from the sentence alone.

- One sentence, one point, under 100 characters. Split at 「〜し、」「〜が、」「〜ので、」 when every resulting
  sentence keeps its subject, object, and condition. When a split would strip one of them, keep one sentence joined
  with 「〜ため、」; over 100 characters, rewrite it with the condition as the subject.
- Lead with the main clause: the fact or the decision comes first. Hedges（〜と思われる、〜かもしれない）and
  flourishes（劇的に、革新的な）drop out, and so does an opening contrast（〜ではなく）or denial that the main
  clause does not need. A short denial followed by a short assertion becomes one sentence naming the object, the
  condition, and the result (the example under Rereading).
- Name the operation and its object. A metaphor verb（`倒す`, `寄せる`, `効く`, `壊す`, `添える`, `回す`, `拾う`,
  `落とす`, `担保`; the full list is the pattern list in `textlintrc.json`）leaves the reader to guess what happens:
  `判断に迷うものは、残さない側に倒す` → `採否を判断できない項目は除外する`. A word whose referent sits outside the
  sentence（`片方`, `経路`）gets the referent written out: `片方だけを見て基準を作ると、もう片方が壊れる` →
  `開発速度だけを基準にすると、保守性の要件を満たせなくなる`.
- Say it once, in plain order. The content carries the weight, so an antithesis pair（`効いてから、身に付く。`）,
  a run of short sentences for rhythm, and a comma for emphasis after a particle（`前提を、経路が代わりに添える`）are
  rewritten as one statement with its subject: `運用者は問い合わせ先に応じた前提条件を参照する`.
- The same particle twice in one sentence is a finding: reorder, split, or reword.
- A bullet carries one item, said in words. Labels are bare text（`hook: 役割`）, never bold or emoji.
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

## Rereading

Prose that stays (a file, a commit message, a pull request body) gets one reread before the textlint check. Ask of
each sentence: from this sentence alone, can a reader say who does what to what, and under which condition? A
sentence that fails gets the missing subject, object, or condition written in, by the rules under Sentences. Chat
replies follow those rules without this separate pass.

> 依存構造は分割できない。動かしながら引き返す。

textlint passes it, and the reread fails it: what moves, when it goes back, and to which state are all left to the
reader.

> 依存関係を分離できないため、稼働中のシステムを変更し、問題が発生した場合は元の状態に戻す。

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
| `@textlint-rule/pattern`（比喩の動詞） | Write the operation and its object: what is done, to what（`拒否の側に倒す` → `拒否する`）. Another metaphor in its place（`倒す` → `寄せる`）is the same finding. A bad example you quote goes inside backticks or a block quote, which the rule skips. |

`textlint-disable` / `textlint-enable` comments are for quoted text and generated tables textlint cannot skip on
its own, not for prose you would rather not rewrite.

## When prose is called machine-written

A remark such as 「AI臭い」 or 「分かりにくい」 names no sentence and no rule. Turn it into both before rewriting:

1. Quote each sentence it applies to and name the rule under Sentences that the sentence breaks.
2. Where the meaning is yours to guess (a referent, a condition), ask the user what the sentence means.
3. Rewrite the quoted sentences, showing each rewrite beside its original. The rest of the text stays as it is.

Reviewing someone else's Japanese takes the same shape: quote the sentence, name the rule, and ask what it refers to
when you cannot tell. A single label gives the writer nothing to fix.

## Worked example

Before (four findings: length, doubled 「も」, redundant 「記録を行う」, space before 「は」):

> SessionStart hook は hosting とブランチモデルを判定して注入し、AGENTS.md の保護ブランチの宣言も注入し、作業ツリーの指紋の記録も行う。

After:

> SessionStart hookはhostingとブランチモデルを判定して注入する。AGENTS.mdの保護ブランチの宣言も注入する。作業ツリーの指紋は別のスクリプトが記録する。

Before (one `@textlint-rule/pattern` finding; 「拒否の側」 is a direction, and no operation is named):

> 判定できないときは拒否の側に倒す。

After:

> 判定できないときは拒否する。
