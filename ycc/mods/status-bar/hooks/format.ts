import type { BarSegment, CallStatus, ContextSlice, ToolCallRecord, ToolTally } from '../types'

type Args = Record<string, unknown>

const str = (input: Args, key: string): string | undefined => {
  const value = input[key]
  return typeof value === 'string' && value.length > 0 ? value : undefined
}

const oneLine = (text: string): string => text.replace(/\s+/g, ' ').trim()

/** `mcp__github__get_me` → `github:get_me`; built-ins pass through. */
export const toolLabel = (tool: string): string => {
  const mcp = /^mcp__(.+?)__(.+)$/.exec(tool)
  if (mcp === null) return tool
  const server = (mcp[1] ?? '').replace(/^plugin_[^_]+_/, '')
  return `${server}:${mcp[2] ?? ''}`
}

/** The one-line gist of a call's arguments, per tool. */
export const summarize = (tool: string, input: Args): string => {
  const path = str(input, 'file_path') ?? str(input, 'notebook_path') ?? str(input, 'path')
  switch (tool) {
    case 'Bash':
      return oneLine(str(input, 'command') ?? '')
    case 'Read':
    case 'Write':
    case 'Edit':
    case 'NotebookEdit':
      return path ?? ''
    case 'Grep':
      return oneLine(`/${str(input, 'pattern') ?? ''}/ ${path ?? ''}`)
    case 'Glob':
      return oneLine(`${str(input, 'pattern') ?? ''} ${path ?? ''}`)
    case 'WebFetch':
      return str(input, 'url') ?? ''
    case 'WebSearch':
      return str(input, 'query') ?? ''
    case 'Agent':
    case 'Task':
      return oneLine(`${str(input, 'subagent_type') ?? 'agent'}: ${str(input, 'description') ?? ''}`)
    case 'Skill':
      return oneLine(`${str(input, 'skill') ?? ''} ${str(input, 'args') ?? ''}`)
    case 'TodoWrite':
      return Array.isArray(input.todos) ? `${input.todos.length} todos` : ''
  }
  for (const value of Object.values(input)) {
    if (typeof value === 'string' && value.length > 0) return oneLine(value)
  }
  return ''
}

export const fmtMs = (ms: number): string => {
  if (ms < 1000) return `${Math.round(ms)}ms`
  const s = ms / 1000
  if (s < 60) return `${s.toFixed(s < 10 ? 1 : 0)}s`
  const m = Math.floor(s / 60)
  if (m < 60) return `${m}m${Math.round(s % 60)}s`
  return `${Math.floor(m / 60)}h${m % 60}m`
}

export const fmtTokens = (n: number): string => {
  if (n < 1000) return String(n)
  if (n < 1_000_000) return `${(n / 1000).toFixed(n < 10_000 ? 1 : 0)}k`
  return `${(n / 1_000_000).toFixed(2)}M`
}

export const fmtUsd = (usd: number): string => `$${usd.toFixed(usd < 10 ? 2 : 1)}`

export const fmtClock = (ms: number): string => {
  const d = new Date(ms)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`
}

/** `five_hour` → `5h`, `seven_day` → `7d`. */
export const limitLabel = (kind: string): string =>
  ({ five_hour: '5h', seven_day: '7d', spend_limit: 'spend' })[kind] ?? kind

const SLICE_GLYPH: Record<ContextSlice['kind'], string> = { used: '█', buffer: '▒', free: '░' }

/**
 * The context window as one row of `width` cells, a run per /context category
 * in its own color. Cells go by largest remainder so the row is always `width`
 * wide; a category too small for a cell shows only in the legend.
 */
export const stackedBar = (slices: readonly ContextSlice[], window: number, width: number): BarSegment[] => {
  const shown = slices.filter(s => s.tokens > 0)
  const total = Math.max(window, shown.reduce((n, s) => n + s.tokens, 0), 1)
  const exact = shown.map(s => (s.tokens / total) * width)
  const cells = exact.map(Math.floor)
  const byRemainder = exact.map((x, i) => ({ i, r: x - Math.floor(x) })).sort((a, b) => b.r - a.r)
  for (let left = width - cells.reduce((n, c) => n + c, 0), k = 0; left > 0; left--, k++) {
    const pick = byRemainder[k % byRemainder.length]
    if (pick === undefined) break
    cells[pick.i] = (cells[pick.i] ?? 0) + 1
  }
  return shown.flatMap((s, i) => {
    const n = cells[i] ?? 0
    return n > 0 ? [{ color: s.color, text: SLICE_GLYPH[s.kind].repeat(n) }] : []
  })
}

/** The largest used categories, then free space: what the legend names. */
export const legendSlices = (slices: readonly ContextSlice[], max: number): ContextSlice[] => [
  ...slices
    .filter(s => s.kind === 'used' && s.tokens > 0)
    .sort((a, b) => b.tokens - a.tokens)
    .slice(0, max),
  ...slices.filter(s => s.kind === 'free'),
]

export const sliceGlyph = (kind: ContextSlice['kind']): string => (kind === 'used' ? '■' : SLICE_GLYPH[kind])

/** `▲ 12k` / `▼ 80k`; empty when nothing changed. */
export const fmtDelta = (delta: number | undefined): string =>
  delta === undefined || delta === 0 ? '' : `${delta > 0 ? '▲' : '▼'} ${fmtTokens(Math.abs(delta))}`

/** Green under 50%, yellow under 80%, red above. */
export const heat = (percent: number): string =>
  percent >= 80 ? 'red' : percent >= 50 ? 'yellow' : 'green'

export const STATUS_GLYPH: Record<CallStatus, string> = {
  running: '▶',
  ok: '✓',
  error: '✗',
  denied: '⊘',
  lost: '?',
}

export const STATUS_COLOR: Record<CallStatus, string> = {
  running: 'cyan',
  ok: 'green',
  error: 'red',
  denied: 'yellow',
  lost: 'gray',
}

export const tallyCall = (tallies: readonly ToolTally[], call: ToolCallRecord): ToolTally[] => {
  const tool = toolLabel(call.tool)
  const prior = tallies.find(t => t.tool === tool) ?? { tool, count: 0, errors: 0, denied: 0, totalMs: 0 }
  const next: ToolTally = {
    tool,
    count: prior.count + 1,
    errors: prior.errors + (call.status === 'error' ? 1 : 0),
    denied: prior.denied + (call.status === 'denied' ? 1 : 0),
    totalMs: prior.totalMs + (call.durationMs ?? 0),
  }
  return [...tallies.filter(t => t.tool !== tool), next].sort((a, b) => b.count - a.count)
}

export const totals = (tallies: readonly ToolTally[]) =>
  tallies.reduce(
    (sum, t) => ({
      count: sum.count + t.count,
      errors: sum.errors + t.errors,
      denied: sum.denied + t.denied,
      totalMs: sum.totalMs + t.totalMs,
    }),
    { count: 0, errors: 0, denied: 0, totalMs: 0 },
  )
