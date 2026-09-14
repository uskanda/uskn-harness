---
name: ok
description: Approve the proposal in your previous reply and go on to the next input it named. Arguments - optional overrides such as `q2はB` or free text, applied to that point only.
disable-model-invocation: true
---

# ok: the user approves your previous reply

The user typed `/ok` after reading your previous reply. Treat it as their answer to that reply: approve what you
proposed, apply the overrides in the arguments, and take the next input you named as if they had typed it.

## Steps

### 1. Read your previous reply

Find the two things it may hold:

- **Proposals**: every recommendation or proposed choice put to the user. A grilling round's recommended answers, OpenSpec artifacts presented for review, a plan or a direction.
- **Next input**: a command or reply you asked the user to enter ("実装は `/opsx:apply add-x` で始めます", "問題なければ `/push` と入力してください").

Neither present (the reply only reported results): say there is nothing to approve and stop.

### 2. Apply the overrides

Each argument overrides one point; everything else stands as recommended.

- A number and an option (`q2はB`, `Q3: A`) settles that question.
- Free text settles the one point it clearly speaks to.
- Text that fits two points, or none: ask which point it means, and wait. Approve the rest only after the answer.

A grilling round answered this way is a complete round: recompute the frontier and continue. When the reply asked
whether shared understanding is reached, `/ok` confirms it.

### 3. Take the next input

- Exactly one next input named: run it, after the approval in step 2. Its own confirmations still apply (for example `push` asking before it creates a branch). Run only that input.
- Several candidates ("`/spec` か `/no-grilling` で"): ask which one.
- The input is a skill the agent cannot invoke (it has `disable-model-invocation`, such as `allow-repo` or `ok` itself): ask the user to type it, and stop.

With no next input, the step is done once the approval is reflected in the work: the next round asked, the artifacts
kept, the plan carried out.

## Examples

Grilling round with recommendations Q1 A, Q2 A, Q3 A; the user types `/ok q2はB`:
answer Q1 A, Q2 B, Q3 A, and ask the next round.

Artifacts presented, reply ending "実装は `/opsx:apply add-ok-skill` で始めます"; the user types `/ok`:
run `/opsx:apply add-ok-skill`.

Reply reporting `make verify` results with no question and no command; the user types `/ok`:
reply that there is nothing to approve.
