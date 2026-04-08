---
name: ts-patterns
description: Idiomatic TypeScript patterns — strict type system, discriminated unions, generic inference, `satisfies`, branded types, errors as values, ESM/CJS modules with `exports` maps, Promise combinators and AbortController, iterators and higher-order functions, runtime selection across Node/Deno/Bun/browser/edge, and the Vite + Vitest toolchain stack. Use when the user is writing new TypeScript, reviewing TS code, refactoring, designing libraries for npm, tuning `tsconfig` strict mode, asks about generics/conditional types/discriminated unions/branded types/`satisfies`, asks about ESM/CJS dual publishing and `exports` maps, asks about Promise combinators/AbortController/async iterators, asks about Vite config or `vite build --lib`, chooses between Node/Deno/Bun/browser/edge runtimes, or wants TypeScript idioms and anti-patterns.
---

# TypeScript Development Patterns

Idiomatic TypeScript patterns for building safe, maintainable, inference-friendly
applications and libraries. TypeScript is JavaScript with a layered type system;
this skill covers language-level idioms, the type system, modules, async,
cross-runtime concerns, and the Vite + Vitest toolchain stack. Framework-agnostic —
for Next.js, React components, or Node backend architecture, defer to
`ycc:nextjs-ux-ui-expert`, `ycc:frontend-ui-developer`, or `ycc:nodejs-backend-architect`.

## When to Use

- Writing new TypeScript code
- Reviewing TypeScript code
- Refactoring existing TypeScript
- Designing libraries for npm (dual ESM/CJS publishing)
- Tuning `tsconfig.json` for strict mode
- Choosing a runtime (Node / Deno / Bun / browser / edge)
- Configuring Vite for apps or libraries

## How It Works

This skill enforces idiomatic TypeScript across seven key areas: a strict,
type-driven design that encodes invariants into the compiler; generic APIs where
inference flows naturally so callers don't annotate; discriminated unions with
`never` exhaustiveness to make illegal states unrepresentable; errors as values
with `unknown` in `catch` and typed boundaries; ESM-first modules with dual-publish
`exports` maps for libraries; `Promise`/`AbortController`-based async with Web
standards preferred over Node-only APIs; and a Vite + Vitest toolchain on a Node
host with clean paths to Deno, Bun, browser, and edge deploys.

## Core Principles

1. **Strict by default** — `"strict": true`, `noUncheckedIndexedAccess`, `exactOptionalPropertyTypes`
2. **Inference over annotation** — design APIs so callers don't pass type arguments
3. **Errors as values** — `Result<T, E>` at expected-failure boundaries; narrow `unknown` in `catch`
4. **Type-driven design** — encode invariants in types, not comments
5. **Zero-`any`** — except at clearly documented external boundaries
6. **Cross-runtime aware** — Web standards first; `node:` prefix when Node-only

## Type System

### Discriminated Unions with Exhaustiveness

```ts
// Good: Impossible states unrepresentable; compiler enforces exhaustive handling
type ConnectionState =
  | { kind: 'disconnected' }
  | { kind: 'connecting'; attempt: number }
  | { kind: 'connected'; sessionId: string }
  | { kind: 'failed'; reason: string; retries: number };

function handle(state: ConnectionState): void {
  switch (state.kind) {
    case 'disconnected':
      return connect();
    case 'connecting':
      return state.attempt > 3 ? abort() : wait();
    case 'connected':
      return useSession(state.sessionId);
    case 'failed':
      return state.retries < 5 ? retry() : logFailure(state.reason);
    default: {
      // Adding a new variant forces handling here — `never` check
      const _exhaustive: never = state;
      throw new Error(`unhandled state: ${String(_exhaustive)}`);
    }
  }
}

// Bad: Optional fields create 2^N invalid combinations
interface BadState {
  disconnected?: boolean;
  connecting?: boolean;
  sessionId?: string;
  reason?: string;
}
```

### Generic Inference Flow

```ts
// Good: caller doesn't pass type arguments — inference does the work
function first<T>(items: readonly T[]): T | undefined {
  return items[0];
}
const n = first([1, 2, 3]); // n: number | undefined

// Good: `const` type parameter preserves literal types
function tuple<const T extends readonly unknown[]>(...items: T): T {
  return items;
}
const t = tuple('a', 1, true); // t: readonly ['a', 1, true]

// Good: `NoInfer` blocks inference from a specific position
function fill<T>(length: number, value: NoInfer<T>): T[] {
  return Array.from({ length }, () => value);
}

// Bad: type parameter never flows — always requires annotation
function first_bad<T>(): T {
  return null as T; // useless generic
}
```

### `satisfies` for Literal Preservation

```ts
// Good: type-checks against a wider shape but keeps literal types at use sites
const routes = {
  home: { path: '/', method: 'GET' },
  users: { path: '/users', method: 'GET' },
  createUser: { path: '/users', method: 'POST' },
} as const satisfies Record<string, { path: string; method: 'GET' | 'POST' }>;

// routes.home.method is still the literal 'GET', not string
type HomeMethod = typeof routes.home.method; // 'GET'

// Bad: annotation widens literals
const routesBad: Record<string, { path: string; method: string }> = {
  home: { path: '/', method: 'GET' },
};
type HomeMethodBad = (typeof routesBad)['home']['method']; // string — too wide
```

### Branded Types for Nominal Safety

```ts
// Good: Distinct nominal types prevent mixing up arguments
declare const UserIdBrand: unique symbol;
declare const OrderIdBrand: unique symbol;
type UserId = string & { readonly [UserIdBrand]: true };
type OrderId = string & { readonly [OrderIdBrand]: true };

function getOrder(user: UserId, order: OrderId): Promise<Order> {
  return db.orders.find({ user, id: order });
}

const u = 'u_123' as UserId;
const o = 'o_456' as OrderId;
getOrder(u, o); // ok
// getOrder(o, u); // ERROR — arguments swapped, compiler catches it

// Bad: naked primitives — swap compiles silently
function getOrderBad(userId: string, orderId: string): Promise<Order> {
  return db.orders.find({ userId, id: orderId });
}
```

### Conditional and Mapped Types

```ts
// Good: key remapping to build typed variants
type Getters<T> = {
  [K in keyof T as `get${Capitalize<K & string>}`]: () => T[K];
};

interface User {
  id: string;
  name: string;
}
type UserGetters = Getters<User>;
// { getId: () => string; getName: () => string }

// Good: conditional distribution over unions
type NonNull<T> = T extends null | undefined ? never : T;
type A = NonNull<string | null | number>; // string | number

// Bad: returning `any` from a conditional defeats the purpose
type BadReturn<T> = T extends string ? any : number; // `any` leaks to callers
```

### Narrowing with Type Guards and Assertion Functions

```ts
// Good: user-defined type guard
function isStringArray(value: unknown): value is string[] {
  return Array.isArray(value) && value.every((v) => typeof v === 'string');
}

function join(value: unknown): string {
  if (isStringArray(value)) {
    return value.join(','); // value narrowed to string[]
  }
  throw new TypeError('expected string[]');
}

// Good: assertion function narrows after the call
function assertDefined<T>(value: T | null | undefined, msg: string): asserts value is T {
  if (value === null || value === undefined) throw new Error(msg);
}

const user = findUser(id);
assertDefined(user, `user ${id} not found`);
// user is now T, not T | null | undefined

// Bad: `as` cast hides runtime errors
function process(value: unknown) {
  const arr = value as string[]; // crashes if not actually string[]
  return arr.join(',');
}
```

## Error Handling

### `unknown` in `catch` — Narrow Explicitly

```ts
// Good: `useUnknownInCatchVariables` (strict) forces narrowing
try {
  await fetchUser(id);
} catch (err: unknown) {
  if (err instanceof FetchError) {
    logger.warn(err.message, { code: err.code });
  } else if (err instanceof Error) {
    logger.error(err.message, { stack: err.stack });
  } else {
    logger.error('non-Error thrown', { raw: String(err) });
  }
}

// Bad: assuming `err` is `Error` (only works without strict settings)
try {
  await fetchUser(id);
} catch (err) {
  console.log((err as Error).message); // runtime crash if err is a string
}
```

### Typed Error Classes for Boundaries

```ts
// Good: domain-specific errors carry structured data
class ValidationError extends Error {
  override readonly name = 'ValidationError';
  constructor(
    readonly field: string,
    message: string
  ) {
    super(`${field}: ${message}`);
  }
}

class NotFoundError extends Error {
  override readonly name = 'NotFoundError';
  constructor(
    readonly resource: string,
    readonly id: string
  ) {
    super(`${resource} ${id} not found`);
  }
}

function handleApiError(err: unknown): Response {
  if (err instanceof ValidationError) {
    return Response.json({ field: err.field, message: err.message }, { status: 400 });
  }
  if (err instanceof NotFoundError) {
    return new Response(null, { status: 404 });
  }
  logger.error('unhandled', { err });
  return new Response('Internal error', { status: 500 });
}
```

### `Result<T, E>` for Expected Failures

```ts
// Good: errors as values when failure is part of the contract
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };

function ok<T>(value: T): Result<T, never> {
  return { ok: true, value };
}
function err<E>(error: E): Result<never, E> {
  return { ok: false, error };
}

async function parseConfig(text: string): Promise<Result<Config, string>> {
  try {
    const data: unknown = JSON.parse(text);
    if (typeof data !== 'object' || data === null) return err('config must be an object');
    if (!('port' in data) || typeof data.port !== 'number') {
      return err('port must be a number');
    }
    return ok(data as Config);
  } catch (e) {
    return err(e instanceof Error ? e.message : String(e));
  }
}

const result = await parseConfig(text);
if (!result.ok) {
  console.error(result.error);
  return;
}
useConfig(result.value); // narrowed to Config
```

**When to throw vs return a `Result`:**

- **Throw** for truly exceptional/unexpected failures (programmer bugs, invariant violations, corrupted state).
- **Return** `Result`, `null`, or `undefined` for expected/handled failures (validation, missing resources, cache misses).
- At module boundaries, throw typed errors so callers can `instanceof`-narrow them.

## Modules and Packaging

### ESM-First with Dual-Publish `exports` Map

```jsonc
// package.json for a dual-publish library
{
  "name": "my-lib",
  "type": "module",
  "main": "./dist/index.cjs",
  "module": "./dist/index.mjs",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "types": "./dist/index.d.ts",
      "import": "./dist/index.mjs",
      "require": "./dist/index.cjs",
      "default": "./dist/index.mjs",
    },
    "./utils": {
      "types": "./dist/utils.d.ts",
      "import": "./dist/utils.mjs",
      "require": "./dist/utils.cjs",
    },
    "./package.json": "./package.json",
  },
  "files": ["dist"],
  "sideEffects": false,
}
```

### Module Augmentation

```ts
// Good: extend a third-party type without forking
import 'express';

declare module 'express' {
  interface Request {
    user?: { id: string; email: string };
  }
}

// Now `req.user` is typed across every handler
```

### `import.meta` and Top-Level Await

```ts
// Good: ESM-only `import.meta.url` for resolving sibling files
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const configPath = join(__dirname, 'config.json');

// Good at entry points: top-level await is fine in the root module
const config = await loadConfig();
startServer(config);

// Bad: top-level await inside a library module — forces every consumer to
// become async and blocks the module graph. Export an `init()` function instead.
```

## Async and Concurrency

### Promise Combinators

```ts
// Good: parallel fetches, fail fast on any rejection
const [user, orders, prefs] = await Promise.all([fetchUser(id), fetchOrders(id), fetchPrefs(id)]);

// Good: collect all results including failures
const results = await Promise.allSettled([task1(), task2(), task3()]);
for (const r of results) {
  if (r.status === 'fulfilled') handle(r.value);
  else logError(r.reason);
}

// Good: race with timeout
await Promise.race([
  longRunningTask(),
  new Promise((_, reject) => setTimeout(() => reject(new Error('timeout')), 5000)),
]);

// Good: `Promise.any` — first success wins, all failures aggregate
const fastest = await Promise.any([
  fetch('https://mirror1.example.com/data'),
  fetch('https://mirror2.example.com/data'),
  fetch('https://mirror3.example.com/data'),
]);

// Bad: sequential awaits when parallel is possible
const userBad = await fetchUser(id);
const ordersBad = await fetchOrders(id); // waits unnecessarily
const prefsBad = await fetchPrefs(id);
```

### `AbortController` for Cancellation

```ts
// Good: cancellable fetch with timeout
async function fetchWithTimeout(url: string, ms: number): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);
  try {
    return await fetch(url, { signal: controller.signal });
  } finally {
    clearTimeout(timer);
  }
}

// Good: thread an external signal through every async boundary
async function fetchUsers(signal?: AbortSignal): Promise<User[]> {
  const res = await fetch('/api/users', { signal });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return res.json();
}

// Good: combine signals with `AbortSignal.any` (modern)
const combined = AbortSignal.any([userSignal, timeoutSignal]);
await fetchUsers(combined);
```

### Async Iterators for Streaming

```ts
// Good: stream large datasets without buffering everything in memory
async function* paginate<T>(
  fetchPage: (cursor: string | null) => Promise<{ items: T[]; next: string | null }>
): AsyncGenerator<T> {
  let cursor: string | null = null;
  do {
    const { items, next } = await fetchPage(cursor);
    for (const item of items) yield item;
    cursor = next;
  } while (cursor !== null);
}

// Usage
for await (const user of paginate(fetchUserPage)) {
  process(user);
  if (shouldStop()) break; // iterator cleans up automatically
}
```

## Iterators and Higher-Order Functions

### Prefer `map` / `filter` / `reduce` Over Imperative Loops

```ts
// Good: declarative and composable
const activeEmails = users.filter((u) => u.isActive).map((u) => u.email);

// Good: reduce for aggregation with explicit accumulator type
const byId = users.reduce<Record<string, User>>((acc, u) => {
  acc[u.id] = u;
  return acc;
}, {});

// Good: `Object.groupBy` (ES2024) for grouping
const byRole = Object.groupBy(users, (u) => u.role);

// Bad: mutable accumulator with an imperative loop
const activeEmailsBad: string[] = [];
for (const u of users) {
  if (u.isActive) activeEmailsBad.push(u.email);
}
```

### Generators for Lazy Iteration

```ts
// Good: lazy range without allocating an array
function* range(start: number, end: number, step = 1): Generator<number> {
  for (let i = start; i < end; i += step) yield i;
}

for (const n of range(0, 1_000_000)) {
  if (n > 100) break; // only 101 numbers produced
}
```

### Immutability by Default

```ts
// Good: `readonly` signals intent and prevents accidental mutation
function total(items: readonly { price: number }[]): number {
  return items.reduce((sum, item) => sum + item.price, 0);
}

// Good: return new objects rather than mutating
function addItem(cart: readonly Item[], item: Item): readonly Item[] {
  return [...cart, item];
}

// Good: use `Readonly<T>` and `ReadonlyArray<T>` at API boundaries
function render(props: Readonly<{ name: string; items: ReadonlyArray<Item> }>): void {
  /* can't mutate props.items */
}
```

## Runtimes

TypeScript runs on many runtimes; pick based on deployment model, cold-start
tolerance, API surface needs, and operational complexity.

### Node (primary)

```ts
// Primary tooling host — Vite, Vitest, tsc, ESLint all run on Node
// Primary deploy target for servers, CLIs, scripts, build tools
// Use `node:` prefix for built-ins — forces Node resolver, avoids shadowing
import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { setTimeout } from 'node:timers/promises';

await setTimeout(100);
const data = await readFile('config.json', 'utf8');
const hash = createHash('sha256').update(data).digest('hex');
```

### Deno

```ts
// Secure by default — explicit permissions at run time
// $ deno run --allow-read --allow-net script.ts
// Single-file tooling: deno fmt, deno lint, deno test, deno bundle
// npm compat: `import pkg from 'npm:pkg@1.0.0'`

const data = await Deno.readTextFile('config.json');
```

### Bun

```ts
// Fast install + run; Jest-compatible test runner; native bundler
// Drop-in Node compatibility for most packages
// $ bun install && bun run dev
// $ bun test

import { file } from 'bun';
const text = await file('config.json').text();
```

### Browser

```ts
// Use Web standards only — no Node built-ins
// Bundle for target browsers via Vite (`vite build`)
const res = await fetch('/api/config');
const config = await res.json();
```

### Edge (Cloudflare Workers, Vercel Edge, Deno Deploy)

```ts
// V8 isolates — cold starts measured in milliseconds
// Web standard APIs only; no `fs`, no long-lived processes
// Rely on fetch, URL, Request/Response, crypto.subtle, streams

export default {
  async fetch(request: Request): Promise<Response> {
    const url = new URL(request.url);
    return new Response(`hello from ${url.pathname}`);
  },
};
```

## Tooling (Vite + Vitest Stack)

### Strict `tsconfig` Baseline

```jsonc
// tsconfig.json — recommended strict baseline
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "isolatedModules": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "verbatimModuleSyntax": true,
    "noEmit": true,
  },
  "include": ["src/**/*", "tests/**/*"],
  "exclude": ["dist", "node_modules"],
}
```

### Vite for Apps

```ts
// vite.config.ts — dev server + production bundle
import { defineConfig } from 'vite';
import { resolve } from 'node:path';

export default defineConfig({
  build: {
    target: 'es2022',
    sourcemap: true,
    rollupOptions: {
      input: { main: resolve(__dirname, 'index.html') },
    },
  },
  server: { port: 5173 },
});
```

### Vite for Libraries (`vite build --lib`)

```ts
// vite.config.ts — dual-publish library build
import { defineConfig } from 'vite';
import dts from 'vite-plugin-dts';
import { resolve } from 'node:path';

export default defineConfig({
  plugins: [dts({ rollupTypes: true })],
  build: {
    lib: {
      entry: resolve(__dirname, 'src/index.ts'),
      formats: ['es', 'cjs'],
      fileName: (format) => `index.${format === 'es' ? 'mjs' : 'cjs'}`,
    },
    rollupOptions: {
      // Don't bundle peer dependencies
      external: ['react', 'react-dom'],
    },
    sourcemap: true,
    minify: false, // let downstream bundlers minify
  },
});
```

### `vitest.config.ts` Sharing Vite's Pipeline

```ts
// vitest.config.ts — reuse dev/build transform pipeline for tests
import { defineConfig, mergeConfig } from 'vitest/config';
import viteConfig from './vite.config';

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      globals: false,
      environment: 'node',
      coverage: {
        provider: 'v8',
        reporter: ['text', 'html', 'lcov'],
      },
    },
  })
);
```

### pnpm Workspaces for Monorepos

```yaml
# pnpm-workspace.yaml
packages:
  - 'packages/*'
  - 'apps/*'
```

```jsonc
// turbo.json — coordinate builds across workspaces
{
  "pipeline": {
    "build": { "dependsOn": ["^build"], "outputs": ["dist/**"] },
    "test": { "dependsOn": ["build"] },
    "lint": {},
  },
}
```

### Linting and Formatting

```jsonc
// biome.json — all-in-one formatter + linter (fastest option in 2026)
{
  "linter": {
    "enabled": true,
    "rules": { "recommended": true },
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
  },
}
```

### When to Reach for Something Other Than Vite

- **tsup** — Node libraries with dozens of entry points; tsup's multi-entry support
  is simpler than Vite's lib mode for this shape.
- **esbuild directly** — custom build scripts where raw bundle speed matters and
  you want minimal config.
- **Rollup directly** — maximum control over output; Vite already uses Rollup for
  production builds, so you can drop into config-level Rollup when needed.
- **webpack** — legacy projects with loaders that haven't been ported to Vite.

## Quick Reference: TypeScript Idioms

| Idiom                       | Description                                                                        |
| --------------------------- | ---------------------------------------------------------------------------------- |
| Strict by default           | `"strict": true` + `noUncheckedIndexedAccess` + `exactOptionalPropertyTypes`       |
| Discriminated unions        | Model states as `\| { kind: 'a'; … } \| { kind: 'b'; … }` + `never` exhaustiveness |
| `satisfies` over annotation | Preserves literal types while type-checking against a wider shape                  |
| `unknown` in `catch`        | Narrow explicitly; never assume `Error`                                            |
| Errors as values            | `Result<T, E>` for expected failures; throw for bugs                               |
| Inference-first APIs        | Design so callers don't pass type arguments                                        |
| Branded types               | `T & { readonly [brand]: true }` prevents primitive mixups                         |
| ESM-first + `exports` map   | Dual-publish with conditional exports; `sideEffects: false`                        |
| `AbortController`           | Thread `signal` through every async boundary                                       |
| Web standards first         | Prefer `fetch` / `URL` / `crypto.subtle` over Node-only when portable              |
| `readonly` at boundaries    | Signal intent; prevent accidental mutation                                         |
| Union over `enum`           | `const` object + `keyof typeof` instead of `enum`                                  |

## Anti-Patterns to Avoid

```ts
// Bad: `any` leaks type errors everywhere
function process(data: any) {
  return data.items.map((x: any) => x.name); // zero type safety
}

// Bad: double-cast bypasses the type system
const user = json as unknown as User; // use zod/valibot to parse+validate instead

// Bad: non-null assertion `!` in production code
const el = document.getElementById('root')!.innerHTML; // crashes if null

// Bad: `namespace` (legacy; use modules)
namespace MyLib {
  export function foo() {}
}

// Bad: `enum` (generates runtime code, weird semantics)
enum Status {
  Active = 'active',
  Inactive = 'inactive',
}
// Better: const object + union type
const Status = { Active: 'active', Inactive: 'inactive' } as const;
type Status = (typeof Status)[keyof typeof Status];

// Bad: `Function` / `Object` / `{}` (no safety)
function run(cb: Function) {
  cb();
}
// Better: explicit signature
function runGood(cb: () => void) {
  cb();
}

// Bad: throwing from a library where failure is part of the contract
export function parseConfig(text: string): Config {
  const data = JSON.parse(text); // throws — caller may not expect
  return data;
}
// Better: return a Result or throw a typed error

// Bad: blocking in async context
async function badAsync() {
  const buf = fs.readFileSync('file.txt'); // blocks the event loop
}
// Better:
import { readFile } from 'node:fs/promises';
async function goodAsync() {
  const buf = await readFile('file.txt');
}

// Bad: fire-and-forget await
async function saveUser(user: User): Promise<void> {
  /* … */
}
saveUser(user); // errors swallowed silently
// Enable `@typescript-eslint/no-floating-promises` to catch this

// Bad: `as` cast instead of narrowing
function handle(value: unknown) {
  const str = value as string;
  return str.toUpperCase(); // crashes if value is not a string
}
// Better: type guard
function handleGood(value: unknown) {
  if (typeof value !== 'string') throw new TypeError('expected string');
  return value.toUpperCase();
}
```

**Remember**: Great TypeScript is invisible. Let the type system encode invariants,
let inference do the work, and reach for `any` only at clearly documented boundaries.
If the compiler can't catch it, the runtime will — and by then it's too late.
