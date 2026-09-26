---
name: test-driven-development
description: Use when implementing any feature or bugfix, before writing implementation code
license: MIT
---

# Test-Driven Development (TDD)

> Forked from [obra/superpowers](https://github.com/obra/superpowers) v6.3.0 (MIT, see `LICENSE`), pinned in
> `deps.json` under `forks`. Harness changes: skill references renamed; the prose rewritten for Opus 5.x as positive
> instructions, without the absolute rules, the excuse table, the warning list, or the completion checklist; a
> Harness notes section. The fork has diverged from upstream and is not re-vendored.

## Overview

Write the test first. Watch it fail. Write the least code that makes it pass. A test you watched fail for the
expected reason can catch the break it names; a test written after the code has never shown that it can fail.

## When to Use

New features, bug fixes, refactoring, and behavior changes. Throwaway prototypes, generated code, and
configuration files are the exceptions; agree them with the user.

Code that already exists without its test (an exploration, a spike) is a sketch. Set it aside, write the test, watch
it fail, then implement from the test. The sketch is a source of ideas, and the test decides what ships.

## Red-Green-Refactor

1. **RED**: write one failing test.
2. **Verify RED**: run it and see it fail for the expected reason. A wrong failure sends you back to step 1.
3. **GREEN**: write the least code that passes.
4. **Verify GREEN**: run it and see it pass, with the other tests still passing.
5. **REFACTOR**: clean up while staying green, then start the next behavior at step 1.

### RED - Write Failing Test

Write one minimal test showing what should happen.

<Good>
```typescript
test('retries failed operations 3 times', async () => {
  let attempts = 0;
  const operation = () => {
    attempts++;
    if (attempts < 3) throw new Error('fail');
    return 'success';
  };

  const result = await retryOperation(operation);

  expect(result).toBe('success');
  expect(attempts).toBe(3);
});
```
Clear name, tests real behavior, one thing
</Good>

<Bad>
```typescript
test('retry works', async () => {
  const mock = jest.fn()
    .mockRejectedValueOnce(new Error())
    .mockRejectedValueOnce(new Error())
    .mockResolvedValueOnce('success');
  await retryOperation(mock);
  expect(mock).toHaveBeenCalledTimes(3);
});
```
Vague name, tests mock not code
</Bad>

The test covers one behavior, its name says which, and it runs real code (a mock only where the real dependency is
slow or external).

### Verify RED - Watch It Fail

```bash
npm test path/to/test.test.ts
```

The test fails rather than errors, the failure message is the one you expect, and it fails because the feature is
missing rather than because of a typo.

- The test passes already: it tests existing behavior. Change the test until it pins the new behavior.
- The test errors: fix the error and run it again until it fails for the right reason.

### GREEN - Minimal Code

Write the simplest code that passes the test.

<Good>
```typescript
async function retryOperation<T>(fn: () => Promise<T>): Promise<T> {
  for (let i = 0; i < 3; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i === 2) throw e;
    }
  }
  throw new Error('unreachable');
}
```
Just enough to pass
</Good>

<Bad>
```typescript
async function retryOperation<T>(
  fn: () => Promise<T>,
  options?: {
    maxRetries?: number;
    backoff?: 'linear' | 'exponential';
    onRetry?: (attempt: number) => void;
  }
): Promise<T> {
  // YAGNI
}
```
Over-engineered
</Bad>

Features the test does not ask for, refactors of other code, and improvements each wait for their own test.

### Verify GREEN - Watch It Pass

Run the test file again: the new test passes, the tests around it still pass, and the output is clean (no errors or
warnings).

- The new test fails: change the code, and keep the test as written.
- Other tests fail: fix them now, while the change is small.

### REFACTOR - Clean Up

Once green: remove duplication, improve names, extract helpers. Behavior stays the same and the tests stay green.
The next behavior starts with its own failing test.

## Good Tests

| Quality | Good | Bad |
|---------|------|-----|
| **Minimal** | One thing. "and" in name? Split it. | `test('validates email and domain and whitespace')` |
| **Clear** | Name describes behavior | `test('test1')` |
| **Shows intent** | Demonstrates desired API | Obscures what code should do |
| **Complete** | Edge cases and error paths have their own tests | Only the happy path |

When writing or changing any test, read [writing-good-tests.md](writing-good-tests.md) for the rules that keep tests honest:
- Name the production change that would make the test fail — before writing it
- Assert on real behavior, never on mock behavior
- Keep test-only code in test utilities, out of production classes
- Understand a dependency's side effects before mocking it

## Example: Bug Fix

**Bug:** Empty email accepted

**RED**
```typescript
test('rejects empty email', async () => {
  const result = await submitForm({ email: '' });
  expect(result.error).toBe('Email required');
});
```

**Verify RED**: `npm test` prints `FAIL: expected 'Email required', got undefined`.

**GREEN**
```typescript
function submitForm(data: FormData) {
  if (!data.email?.trim()) {
    return { error: 'Email required' };
  }
  // ...
}
```

**Verify GREEN**: `npm test` prints `PASS`.

**REFACTOR**: extract validation for multiple fields if needed.

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write wished-for API. Write assertion first. Ask the user. |
| Test too complicated | Design too complicated. Simplify interface. |
| Must mock everything | Code too coupled. Use dependency injection. |
| Test setup huge | Extract helpers. Still complex? Simplify design. |
| Tempted to test after | Write the test now against the unchanged code and watch it fail first. |

## Debugging Integration

A bug fix starts with a failing test that reproduces the bug. The passing test then proves the fix and keeps the
bug from coming back. A bug whose cause is still unclear goes through `systematic-debugging` first.

## Harness Notes

- The user layer asks for the failing test first for any new behaviour in scripts or code; this skill is the
  procedure behind that line.
- Verify GREEN runs the test file and its neighbours. The repository's verify convention (`make verify`
  when the Makefile has a verify target, else `pnpm run verify` / `npm run verify`) is the full run; the Stop hook
  `verify-gate` runs it when a turn that changed files ends, and the `verify` skill runs it on demand.
- Hook scripts in the harness are tested with bats: the test file under `hooks/tests/` is the RED step.
