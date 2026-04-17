---
name: ts-testing
description: TypeScript testing patterns using Vitest as the primary runner — TDD
  workflow, unit tests, integration tests, async tests with fake timers, parameterized
  tests via `test.each`, property-based testing with fast-check, mocking with `vi.mock`
  / `vi.fn` / `vi.spyOn`, type-level testing with `expectTypeOf` / `expect-type` /
  `tsd`, benchmarks with `vitest bench`, and v8 coverage. Follows TDD methodology.
  Use when the user is writing TypeScript tests, adding test coverage to TypeScript
  code, asks about Vitest, `describe` / `it` / `expect`, `vi.useFakeTimers`, `test.each`,
  fast-check, `expectTypeOf` or `tsd`, `vitest bench`, coverage targets, or wants
  TDD guidance for a TypeScript project.
---

# TypeScript Testing Patterns

Comprehensive TypeScript testing patterns for writing reliable, maintainable tests
using **Vitest** as the primary runner, following TDD methodology. Vitest pairs with
Vite (same team, shared config) so the transform pipeline used in development is the
same one used in tests — no duplicated build configuration.

## When to Use

- Writing new TypeScript functions, classes, or modules
- Adding test coverage to existing TypeScript code
- Creating benchmarks for performance-sensitive code
- Implementing property-based tests for input validation
- Writing type-level tests for library APIs
- Following TDD workflow in a TypeScript project

## How It Works

1. **Identify target code** — find the function, class, or module to test.
2. **Write a test** — use `describe` / `it` / `expect` in a colocated `*.test.ts`
   file (or `tests/` dir for integration tests).
3. **Mock external dependencies** — prefer dependency injection; fall back to
   `vi.mock()` for modules you can't control.
4. **Run tests (RED)** — confirm the test fails for the expected reason.
5. **Implement (GREEN)** — write the minimum code needed to pass.
6. **Refactor** — clean up while keeping tests green.
7. **Check coverage** — `vitest --coverage`, target 80%+.

## TDD Workflow for TypeScript

### The RED-GREEN-REFACTOR Cycle

```
RED      → Write a failing test first
GREEN    → Write minimal code to pass the test
REFACTOR → Improve code while keeping tests green
REPEAT   → Continue with next requirement
```

### Step-by-Step TDD in TypeScript

```ts
// calculator.ts — RED: stub with a placeholder that throws
export function add(a: number, b: number): number {
  throw new Error('not yet implemented');
}
```

```ts
// calculator.test.ts — write the test first
import { describe, it, expect } from 'vitest';
import { add } from './calculator';

describe('add', () => {
  it('sums two numbers', () => {
    expect(add(2, 3)).toBe(5);
  });
});

// $ vitest
// FAIL  calculator.test.ts > add > sums two numbers
//   Error: not yet implemented
```

```ts
// GREEN: minimal implementation
export function add(a: number, b: number): number {
  return a + b;
}
// $ vitest → PASS, then REFACTOR while tests stay green
```

## Unit Tests

### Colocated Unit Tests

```ts
// src/user.ts
export class User {
  constructor(
    public readonly name: string,
    public readonly email: string
  ) {
    if (!email.includes('@')) {
      throw new Error(`invalid email: ${email}`);
    }
  }

  get displayName(): string {
    return this.name;
  }
}
```

```ts
// src/user.test.ts — colocated with the source
import { describe, it, expect } from 'vitest';
import { User } from './user';

describe('User', () => {
  it('creates a user with a valid email', () => {
    const user = new User('Alice', 'alice@example.com');
    expect(user.displayName).toBe('Alice');
    expect(user.email).toBe('alice@example.com');
  });

  it('rejects invalid emails', () => {
    expect(() => new User('Bob', 'not-an-email')).toThrow('invalid email');
  });
});
```

**File conventions:**

- `.test.ts` or `.spec.ts` are picked up by Vitest by default.
- Colocation (`src/user.ts` + `src/user.test.ts`) or a `__tests__/` directory both
  work — colocation is more common and easier to navigate.
- Configure via `test.include` in `vitest.config.ts`.

## Assertions

```ts
import { expect } from 'vitest';

expect(2 + 2).toBe(4); // strict equality
expect({ a: 1 }).toEqual({ a: 1 }); // deep equality
expect([1, 2, 3]).toContain(2); // array contains
expect('hello world').toMatch(/world/); // regex match
expect(value).toBeDefined(); // not undefined
expect(value).toBeNull(); // strict null
expect(value).toBeTruthy(); // JS truthy
expect(0.1 + 0.2).toBeCloseTo(0.3); // float compare
expect({ a: 1, b: 2, c: 3 }).toMatchObject({ a: 1 }); // partial deep equal
expect(fn).toHaveBeenCalledWith('expected-arg'); // spy assertion

// Snapshots
expect(result).toMatchInlineSnapshot(`
  {
    "items": [1, 2, 3],
    "status": "ok",
  }
`);
```

### Custom Matchers

```ts
import { expect } from 'vitest';

expect.extend({
  toBeValidEmail(received: string) {
    const pass = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(received);
    return {
      pass,
      message: () => `expected ${received} ${pass ? 'not ' : ''}to be a valid email`,
    };
  },
});

// Extend Vitest's type surface
declare module 'vitest' {
  interface Assertion<T = unknown> {
    toBeValidEmail(): T;
  }
}

expect('alice@example.com').toBeValidEmail();
```

## Error and Rejection Testing

```ts
import { describe, it, expect } from 'vitest';

describe('parseConfig', () => {
  it('throws on invalid input', () => {
    expect(() => parseConfig('}{invalid')).toThrow();
    expect(() => parseConfig('}{invalid')).toThrow(/invalid JSON/);
    expect(() => parseConfig('}{invalid')).toThrow(SyntaxError);
  });
});

describe('fetchUser', () => {
  it('rejects for missing users', async () => {
    await expect(fetchUser('missing')).rejects.toThrow('not found');
    await expect(fetchUser('missing')).rejects.toBeInstanceOf(NotFoundError);
  });

  it('resolves for valid users', async () => {
    await expect(fetchUser('alice')).resolves.toMatchObject({ name: 'Alice' });
  });
});
```

## Integration Tests

### File Layout

```text
my-pkg/
├── src/
│   ├── app.ts
│   └── app.test.ts        # unit tests colocated
├── tests/                 # integration tests
│   ├── api.test.ts
│   ├── helpers.ts
│   └── setup.ts           # global setup/teardown
├── vitest.config.ts
```

### Global Setup and Teardown

```ts
// tests/setup.ts
import { afterAll, beforeAll } from 'vitest';
import { startTestServer, stopTestServer } from './helpers';

beforeAll(async () => {
  await startTestServer();
});

afterAll(async () => {
  await stopTestServer();
});
```

```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    setupFiles: ['./tests/setup.ts'],
    include: ['src/**/*.test.ts', 'tests/**/*.test.ts'],
  },
});
```

### Writing an Integration Test

```ts
// tests/api.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { App, Config } from '../src/app';

describe('full request lifecycle', () => {
  let app: App;

  beforeEach(() => {
    app = new App(Config.testDefault());
  });

  it('handles /health', async () => {
    const res = await app.handleRequest('/health');
    expect(res.status).toBe(200);
    expect(await res.text()).toBe('OK');
  });

  it('returns 404 for unknown paths', async () => {
    const res = await app.handleRequest('/nope');
    expect(res.status).toBe(404);
  });
});
```

## Async Tests and Fake Timers

### Native Async Tests

```ts
import { describe, it, expect } from 'vitest';

describe('async operations', () => {
  it('resolves after fetching', async () => {
    const data = await fetchData('/api');
    expect(data.items).toHaveLength(3);
  });

  it('races against a timeout', async () => {
    await expect(
      Promise.race([slowOp(), new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 100))])
    ).rejects.toThrow('timeout');
  });
});
```

### Fake Timers

```ts
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';

describe('debounce', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('delays execution by the wait period', () => {
    const cb = vi.fn();
    const debounced = debounce(cb, 1000);

    debounced();
    expect(cb).not.toHaveBeenCalled();

    vi.advanceTimersByTime(1000);
    expect(cb).toHaveBeenCalledTimes(1);
  });

  it('advances all pending timers', async () => {
    const spy = vi.fn();
    setTimeout(spy, 5000);
    await vi.runAllTimersAsync();
    expect(spy).toHaveBeenCalled();
  });
});
```

## Parameterized Tests with `test.each`

### Table of Cases

```ts
import { describe, it, expect } from 'vitest';

describe('add', () => {
  it.each([
    { a: 2, b: 3, expected: 5 },
    { a: -1, b: -2, expected: -3 },
    { a: 0, b: 0, expected: 0 },
    { a: -1, b: 1, expected: 0 },
    { a: 1_000_000, b: 2_000_000, expected: 3_000_000 },
  ])('add($a, $b) → $expected', ({ a, b, expected }) => {
    expect(add(a, b)).toBe(expected);
  });
});
```

### Running a Whole Suite Against Multiple Configs

```ts
import { describe, it, expect, beforeEach } from 'vitest';

describe.each([{ db: 'postgres' as const }, { db: 'sqlite' as const }])('storage with $db', ({ db }) => {
  let store: Store;

  beforeEach(() => {
    store = makeStore(db);
  });

  it('writes and reads', async () => {
    await store.set('key', 'value');
    expect(await store.get('key')).toBe('value');
  });

  it('enforces constraints', async () => {
    await expect(store.set('', 'value')).rejects.toThrow();
  });
});
```

## Property-Based Testing with fast-check

### Basic Properties

```ts
import { describe } from 'vitest';
import { fc, test } from '@fast-check/vitest';
import { encode, decode } from './codec';

describe('codec', () => {
  test.prop([fc.string()])('encode then decode returns input', (input) => {
    const encoded = encode(input);
    const decoded = decode(encoded);
    return decoded === input;
  });

  test.prop([fc.array(fc.integer(), { maxLength: 100 })])('sort preserves length and is ordered', (arr) => {
    const sorted = [...arr].sort((a, b) => a - b);
    if (sorted.length !== arr.length) return false;
    for (let i = 1; i < sorted.length; i++) {
      if (sorted[i - 1]! > sorted[i]!) return false;
    }
    return true;
  });
});
```

### Custom Arbitraries

```ts
import { fc, test } from '@fast-check/vitest';
import { expect } from 'vitest';
import { User } from './user';

const validEmail = fc
  .tuple(fc.stringMatching(/^[a-z]{1,10}$/), fc.stringMatching(/^[a-z]{1,5}$/))
  .map(([user, domain]) => `${user}@${domain}.com`);

test.prop([validEmail])('accepts valid emails', (email) => {
  expect(() => new User('Test', email)).not.toThrow();
});
```

## Mocking

### `vi.fn()` — a Fresh Spy

```ts
import { describe, it, expect, vi } from 'vitest';

describe('processItems', () => {
  it('invokes the callback for each item', () => {
    const cb = vi.fn();
    processItems([1, 2, 3], cb);
    expect(cb).toHaveBeenCalledTimes(3);
    expect(cb).toHaveBeenNthCalledWith(1, 1);
    expect(cb).toHaveBeenLastCalledWith(3);
  });

  it('returns configured values on sequential calls', async () => {
    const loader = vi.fn<(id: string) => Promise<User>>();
    loader
      .mockResolvedValueOnce({ id: '1', name: 'Alice', email: 'a@x.com' })
      .mockRejectedValueOnce(new Error('not found'));

    await expect(loader('1')).resolves.toMatchObject({ name: 'Alice' });
    await expect(loader('2')).rejects.toThrow('not found');
  });
});
```

### `vi.spyOn()` — Wrap an Existing Method

```ts
import { describe, it, expect, vi, afterEach } from 'vitest';
import { UserService } from './user-service';

describe('UserService.saveUser', () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('logs before saving', async () => {
    const logger = { info: vi.fn(), error: vi.fn() };
    const service = new UserService({ logger });
    const saveSpy = vi.spyOn(service, 'save');

    await service.saveUser({ id: '1', name: 'Alice', email: 'a@x.com' });

    expect(logger.info).toHaveBeenCalledWith(expect.stringContaining('saving user'));
    expect(saveSpy).toHaveBeenCalled();
  });
});
```

### `vi.mock()` — Module-Level Mock

```ts
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { sendEmail } from './mailer';
import { registerUser } from './auth';

vi.mock('./mailer', () => ({
  sendEmail: vi.fn().mockResolvedValue({ id: 'msg_1' }),
}));

describe('registerUser', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('sends a welcome email on success', async () => {
    await registerUser({ name: 'Alice', email: 'alice@example.com' });
    expect(sendEmail).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'alice@example.com',
        subject: expect.stringMatching(/welcome/i),
      })
    );
  });
});
```

### Dependency Injection > Module Mocks

```ts
// Good: inject an interface — no vi.mock() needed, fully type-checked
interface UserRepository {
  findById(id: string): Promise<User | null>;
  save(user: User): Promise<void>;
}

class UserService {
  constructor(private readonly repo: UserRepository) {}

  async getUser(id: string): Promise<User> {
    const user = await this.repo.findById(id);
    if (!user) throw new NotFoundError('user', id);
    return user;
  }
}

// Test with a plain fake — type-checked, no runner magic
it('throws when user is missing', async () => {
  const fakeRepo: UserRepository = {
    findById: async () => null,
    save: async () => {},
  };
  const service = new UserService(fakeRepo);
  await expect(service.getUser('missing')).rejects.toThrow(NotFoundError);
});
```

## Type-Level Testing

### `expectTypeOf` (Built Into Vitest)

```ts
import { describe, it, expectTypeOf } from 'vitest';
import { parseJSON, type JsonValue } from './json';

describe('parseJSON types', () => {
  it('returns JsonValue', () => {
    expectTypeOf(parseJSON).returns.toEqualTypeOf<JsonValue>();
  });

  it('accepts string input', () => {
    expectTypeOf(parseJSON).parameter(0).toEqualTypeOf<string>();
  });
});
```

### `expect-type` (Standalone Library)

```ts
import { expectTypeOf } from 'expect-type';
import type { User } from './user';

expectTypeOf<User>().toHaveProperty('email').toEqualTypeOf<string>();
expectTypeOf<User>().toHaveProperty('name').toEqualTypeOf<string>();
```

### `tsd` (Separate Type-Only Test Suite)

```ts
// test-d/user.test-d.ts
import { expectType, expectError } from 'tsd';
import { makeUser } from '..';

expectType<{ id: string; name: string }>(makeUser('alice'));
expectError(makeUser(42)); // should fail type check
```

**When to test types vs runtime:**

- Test **types** when authoring a library whose public API makes type-level
  guarantees (inference, conditional return types, branded outputs).
- Test **runtime** for everything else — types catch compile-time bugs; runtime
  tests catch the rest.

## Benchmarks

```ts
// src/join.bench.ts
import { bench, describe } from 'vitest';

const parts = ['hello', 'world', 'foo', 'bar', 'baz'];

describe('string join', () => {
  bench('plus operator', () => {
    let s = '';
    for (const p of parts) s += p;
  });

  bench('Array.join', () => {
    const _ = parts.join('');
  });

  bench('template literal', () => {
    const _ = `${parts[0]}${parts[1]}${parts[2]}${parts[3]}${parts[4]}`;
  });
});

// $ vitest bench
// BenchmarkJoin
//   plus operator      12,345,678 ops/sec
//   Array.join         18,765,432 ops/sec
//   template literal   22,109,876 ops/sec
```

For heavier, standalone benchmarks (stats, multiple runs, comparison reports),
reach for `tinybench` or `mitata` directly.

## Test Coverage

### Running Coverage

```bash
# Vitest's v8 provider is built in — no extra deps
vitest run --coverage
```

```ts
// vitest.config.ts — coverage config
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 75,
        statements: 80,
      },
      exclude: ['**/*.d.ts', '**/*.config.ts', 'tests/**', 'dist/**', 'src/**/*.bench.ts'],
    },
  },
});
```

### Coverage Targets

| Code type                | Target  |
| ------------------------ | ------- |
| Critical business logic  | 100%    |
| Public library API       | 90%+    |
| General application code | 80%+    |
| Generated / binding code | Exclude |

## Testing Commands

```bash
# Watch mode (default when running vitest interactively)
vitest

# Run once and exit (use in CI)
vitest run

# Run files/tests matching a pattern
vitest user                  # files matching "user"
vitest -t "valid email"      # test names matching "valid email"

# Coverage
vitest run --coverage

# Change the reporter
vitest run --reporter=verbose
vitest run --reporter=dot

# Benchmark mode
vitest bench

# Browser-based UI explorer
vitest --ui

# Type-check tests alongside runtime tests
vitest --typecheck

# Force single-thread (useful for debugging shared state)
vitest --poolOptions.threads.singleThread=true

# Run only changed files
vitest --changed
```

## Best Practices

**DO:**

- Write tests FIRST (TDD)
- Colocate unit tests with source (`foo.ts` + `foo.test.ts`)
- Keep integration tests in `tests/` with a `setupFiles` entry
- Test behavior, not implementation detail
- Use `describe` to group related tests; `it` / `test` for individual cases
- Prefer `toEqual` for objects and arrays, `toBe` for primitives
- Use `test.each` to eliminate duplication across input sets
- Inject dependencies so tests don't need `vi.mock()`
- Reset mocks between tests (`beforeEach(() => vi.clearAllMocks())`)
- Run tests under the same `tsconfig` strict settings as source

**DON'T:**

- Use `any` in test code — strict-mode rules still apply
- Use real `setTimeout` in tests — use `vi.useFakeTimers()`
- Reach for `vi.mock()` when dependency injection would work
- Test third-party libraries (trust their tests; test your integration with them)
- Ignore flaky tests — fix them or quarantine with `it.skip` and a tracking comment
- Share mutable state between tests — each test must be independent

## CI Integration

```yaml
# .github/workflows/test.yml
name: test
on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
        with: { version: 10 }
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'pnpm'

      - run: pnpm install --frozen-lockfile

      - name: Type check
        run: pnpm exec tsc --noEmit

      - name: Lint
        run: pnpm exec biome ci .

      - name: Run tests with coverage
        run: pnpm exec vitest run --coverage

      - uses: codecov/codecov-action@v4
        with:
          files: ./coverage/lcov.info
```

## Alternatives to Vitest

The ecosystem has several other runners; reach for them when the constraints fit.

- **Jest** — legacy-common, large plugin ecosystem. Vitest's `describe` / `it` /
  `expect` / `vi.fn` / `vi.mock` surface is intentionally Jest-compatible, so
  migration usually means aliasing imports and adjusting config. Prefer Vitest for
  new projects — it's faster, has native ESM/TS, and shares config with Vite.
- **`node:test`** — Node's built-in test runner (Node 18+). Zero dependencies.
  Good fit for small libraries or when avoiding bundler/transform deps. Lacks
  Vitest's mocking ergonomics, snapshot polish, and watch-mode UI.
- **`bun test`** — Bun's built-in runner, Jest-compatible API, very fast
  install-plus-run cycle. Good on Bun-first projects; some Vitest plugins don't
  have Bun equivalents.
- **`deno test`** — Deno's built-in runner using the standard `@std/assert`
  module. Good for Deno-native code. Permissions model means integration tests
  need explicit flags.
- **Playwright** — end-to-end browser testing. _Complements_ Vitest rather than
  replacing it — use Vitest for unit and integration, Playwright for real-browser
  e2e flows.

**Remember**: Tests are documentation. They show how your code is meant to be used.
Keep them clear, fast, and strict-mode-compliant. The best test is one that fails
loudly when the behavior it describes breaks — and stays silent the rest of the time.
