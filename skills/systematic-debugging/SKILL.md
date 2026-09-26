---
name: systematic-debugging
description: Root-cause investigation before a fix. Use when a bug, test failure, or unexpected behavior has a cause you cannot yet explain.
license: MIT
---

# Systematic Debugging

> Forked from [obra/superpowers](https://github.com/obra/superpowers) v6.3.0 (MIT, see `LICENSE`), pinned in
> `deps.json` under `forks`. Harness changes: references to `test-driven-development` and `verify` use the harness
> skill names; superpowers' skill-testing files are not vendored; the prose rewritten for Opus 5.x as positive
> instructions, without the absolute rules, the warning lists, or the excuse table. The fork has diverged from
> upstream and is not re-vendored.

## Overview

Find the root cause, then fix it there. A fix at the symptom moves the bug; a fix at the source removes it. The
four phases run in order, and each phase's result is the input to the next: the fix in Phase 4 targets the cause
that Phases 1 to 3 established.

## When to Use

A bug, test failure, build failure, performance problem, integration issue, or unexpected behavior whose cause you
cannot yet state. The process pays off most when a fix looks obvious, when time is short, and when an earlier fix
did not work. A failure whose cause you can already state, with the evidence for it, goes straight to Phase 4.

## The Four Phases

### Phase 1: Root Cause Investigation

1. **Read error messages completely**
   - Stack traces, line numbers, file paths, error codes, and the warnings around them
   - They often name the fix

2. **Reproduce consistently**
   - Find the exact steps that trigger it, and whether it happens every time
   - When it does not reproduce, gather more data until it does

3. **Check recent changes**
   - `git diff`, recent commits, new dependencies, config changes, environmental differences

4. **Gather evidence in multi-component systems**

   When the system has several components (CI → build → signing, API → service → database), add diagnostic
   instrumentation before proposing a fix:
   ```
   For each component boundary:
     - Log what data enters the component
     - Log what data exits the component
     - Check environment and config propagation
     - Check the state at each layer

   Run once to see WHERE it breaks, then investigate that component
   ```

   **Example (multi-layer system):**
   ```bash
   # Layer 1: Workflow
   echo "=== Secrets available in workflow: ==="
   echo "IDENTITY: ${IDENTITY:+SET}${IDENTITY:-UNSET}"

   # Layer 2: Build script
   echo "=== Env vars in build script: ==="
   env | grep IDENTITY || echo "IDENTITY not in environment"

   # Layer 3: Signing script
   echo "=== Keychain state: ==="
   security list-keychains
   security find-identity -v

   # Layer 4: Actual signing
   codesign --sign "$IDENTITY" --verbose=4 "$APP"
   ```

   **This reveals:** Which layer fails (secrets → workflow ✓, workflow → build ✗)

5. **Trace data flow**

   When the error is deep in the call stack, trace backward: where does the bad value originate, what called this
   with it, and what called that. Keep going up until you reach the source, and fix there.
   `root-cause-tracing.md` in this directory has the complete technique.

### Phase 2: Pattern Analysis

1. **Find working examples**: similar code in the same codebase that works.
2. **Compare against references**: when implementing a pattern, read the reference implementation in full before
   applying it.
3. **Identify differences**: list every difference between working and broken, however small.
4. **Understand dependencies**: the other components, settings, config, environment, and assumptions it needs.

### Phase 3: Hypothesis and Testing

1. **Form a single hypothesis**: "I think X is the root cause because Y". Write it down, specific enough to test.
2. **Test minimally**: the smallest change that tests the hypothesis, one variable at a time.
3. **Read the result**: confirmed → Phase 4. Refuted → form a new hypothesis from what you learned, starting from
   the original code rather than stacking another change on top.
4. **When you don't know**: say "I don't understand X", research more, and ask the user.

### Phase 4: Implementation

1. **Create a failing test case**
   - The simplest reproduction: an automated test, or a one-off script when there is no framework
   - Written before the fix, with the `test-driven-development` skill

2. **Implement a single fix**
   - Address the root cause identified
   - One change at a time; improvements and refactoring wait for their own change

3. **Confirm the fix**
   - The new test passes, the other tests still pass, and the original symptom is gone
   - The `verify` skill runs the repository's full check and reports it

4. **When the fix does not work**
   - Count the fixes tried so far
   - Fewer than three: return to Phase 1 with the new information
   - Three: question the architecture (step 5) before a fourth attempt

5. **After three failed fixes: question the architecture**

   Signs of an architectural problem:
   - Each fix reveals new shared state, coupling, or a problem in a different place
   - Fixes need "massive refactoring" to implement
   - Each fix creates new symptoms elsewhere

   Ask whether the pattern is fundamentally sound, and whether refactoring the architecture beats fixing symptoms.
   Discuss it with the user before attempting more fixes: this is a wrong architecture, not a failed hypothesis.

## Returning to Phase 1

Go back to Phase 1 when a fix did not work, when each fix reveals a new problem elsewhere, or when you notice
yourself proposing fixes before tracing the data flow. The user's redirections are the same signal: "Is that not
happening?" (an assumption you did not check), "Will it show us...?" (evidence you did not gather), "Stop guessing",
or a frustrated "We're stuck?".

## Quick Reference

| Phase | Key Activities | Success Criteria |
|-------|---------------|------------------|
| **1. Root Cause** | Read errors, reproduce, check changes, gather evidence | Understand WHAT and WHY |
| **2. Pattern** | Find working examples, compare | Identify differences |
| **3. Hypothesis** | Form theory, test minimally | Confirmed or new hypothesis |
| **4. Implementation** | Create test, fix, verify | Bug resolved, tests pass |

## When the Process Finds No Root Cause

When the investigation shows the issue is truly environmental, timing-dependent, or external:

1. Record what you investigated
2. Implement appropriate handling (retry, timeout, error message)
3. Add monitoring or logging for the next investigation

Most such results turn out to be an incomplete Phase 1, so name the evidence that rules out a cause in the code.

## Supporting Techniques

These techniques are part of systematic debugging and live in this directory:

- **`root-cause-tracing.md`** - Trace bugs backward through the call stack to find the original trigger
- **`defense-in-depth.md`** - Add validation at multiple layers after finding the root cause
- **`condition-based-waiting.md`** - Replace arbitrary timeouts with condition polling
- **`find-polluter.sh`** - Bisect which test creates an unwanted file or state
