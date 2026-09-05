---
name: ja-writing
description: Japanese prose rules and the textlint check for anything a person reads in Japanese - commit messages, pull requests, OpenSpec artifacts, ADRs, docs, UI copy. Use before writing Japanese, and when the textlint hook or `make verify` reports problems in a Markdown file.
allowed-tools: Bash(textlint:*), Read, Edit, Write, Grep, Glob
---

# ja-writing: Japanese prose for people

The sensor for this guide is textlint with `preset-ja-technical-writing` and `@textlint-ja/preset-ai-writing`.
The PostToolUse hook `textlint-check` runs it after every Markdown write that contains Japanese, and `make verify`
in the harness repository runs it over README, ADRs, main specs, and active changes. A finding is fixed by
rewriting the sentence, never by loosening the rule.

## Baseline (provisional)

Provisional: the owner's style baseline is settled in a short grilling (ADR-0001 §11), not yet held. Until then,
write the way the existing corpus (ADRs, main specs, README) does:

- Register follows the artifact. 常体（だ・である、体言止め可）for specs, ADRs, design notes, table cells, and commit
  subjects. 敬体（です・ます）for chat replies, pull request text, UI copy, and anything addressed to a reader.
- One sentence, one point, under 100 characters. Split at 「〜し、」「〜が、」「〜ので、」 instead of chaining.
- State the fact or the decision. Hedges（〜と思われる、〜かもしれない）and flourishes（劇的に、革新的な）drop out.
- Half-width space between Japanese and ASCII words（`textlint の設定`）, none before punctuation. Full-width
  punctuation 「。」「、」 in Japanese sentences.
- A bullet carries one item, said in words. Labels are plain（`hook: 役割`）, never bold or emoji.
- One spelling per term across the document（ハーネス / hook / スキル）; identifiers stay in English.

## Voice samples

`~/.local/share/uskn-harness/assets/voice/ja/` may hold samples of the owner's writing. When it has files, read
them first and match their sentence length, vocabulary, and register. When it is empty, write from the baseline and
carry on; do not stop to ask for samples.

## Check

```bash
textlint --config ~/.local/share/uskn-harness/skills/ja-writing/textlintrc.json --format compact <file.md>
```

- A repository with its own `.textlintrc*` at the root uses that instead: run `textlint <file.md>` from the root.
- Prose that is not a file (a commit message, a PR body): write it to a scratch `.md`, lint that, then use it.
- Done when the command prints no problems.

## Fixing findings

| Rule | Fix |
|---|---|
| `sentence-length` (max 100) | Split the sentence. A subordinate clause becomes its own sentence; a list inside a sentence becomes bullets. |
| `sentence-length` from one long path or identifier | Lift it out into a sentence of its own（`置き場は \`<path>\`。`）rather than shortening the prose around it. |
| `no-doubled-joshi`（同じ助詞が 2 回） | Reorder, split, or replace one of the 「と」「も」「に」 with a different construction. |
| `ja-no-redundant-expression`（〜を行う、〜することができる） | Use the verb directly（判定を行う → 判定する、確認を行う → 確認する）. |
| `max-ten` / `max-comma` | Too many 、or , in one sentence: split it. |
| `ja-no-mixed-period` | Every sentence ends with 。, including the last one in a paragraph or a table cell. |
| `no-exclamation-question-mark` | State it as a sentence. |
| `ai-writing/no-ai-list-formatting` | Drop the bold label or emoji at the start of the item; say the item in words. |
| `ai-writing/no-ai-colon-continuation` | A sentence ending in 「:」 that continues below: end it with 。, or write 「次のとおり。」 and start the list. |
| `ai-writing/no-ai-hype-expressions`, `ai-tech-writing-guideline` | Replace the flourish with the fact it stands for. |

`textlint-disable` / `textlint-enable` comments are for quoted text and generated tables textlint cannot skip on
its own, not for prose you would rather not rewrite.

## Worked example

Before (three findings: length, doubled 「も」, redundant 「記録を行う」):

> SessionStart hook は hosting とブランチモデルを判定して注入し、journal の直近要約も注入し、作業ツリーの指紋の記録も行う。

After:

> SessionStart hook は hosting とブランチモデルを判定して注入する。journal の直近要約も注入する。作業ツリーの指紋は別のスクリプトが記録する。
