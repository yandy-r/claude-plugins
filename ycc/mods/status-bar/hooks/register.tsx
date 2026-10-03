import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { BarView, ContextSlice, ToolCallRecord, ToolTally, TurnInfo, UsageSnapshot } from '../types'
import {
  fmtClock,
  fmtDelta,
  fmtMs,
  fmtTokens,
  fmtUsd,
  heat,
  legendSlices,
  limitLabel,
  sliceGlyph,
  stackedBar,
  STATUS_COLOR,
  STATUS_GLYPH,
  summarize,
  tallyCall,
  toolLabel,
  totals,
} from './format'

const KEEP_CALLS = 200
const RECENT_CALLS = 3
const LEGEND_SLICES = 4
const VIEW_STORE_KEY = 'view'

const calls = atom({ plugin: 'status-bar', key: 'calls' } as const, [] as ToolCallRecord[])
const tallies = atom({ plugin: 'status-bar', key: 'tallies' } as const, [] as ToolTally[])
const usage = atom({ plugin: 'status-bar', key: 'usage' } as const, null as UsageSnapshot | null)
const lastTurn = atom({ plugin: 'status-bar', key: 'lastTurn' } as const, null as TurnInfo | null)
const turnTools = atom({ plugin: 'status-bar', key: 'turnTools' } as const, 0)
const tick = atom({ plugin: 'status-bar', key: 'tick' } as const, 0)
const view = atom({ plugin: 'status-bar', key: 'view' } as const, 'full' as BarView)

const VIEWS: readonly BarView[] = ['full', 'compact', 'hidden']

/**
 * Pulls the status line's figures, and /context's categories (a local
 * estimate, no token-count request), into state, and mirrors a one-liner to
 * the status line. `turnStartTokens` marks a turn's end: the delta is taken
 * against it, otherwise the last delta carries over.
 */
const refreshUsage = async ($: EngineInterface, turnStartTokens?: number): Promise<void> => {
  const [u, model, turns, prev] = await Promise.all([
    $.session.usage({ breakdown: 'summary' }),
    $.session.model(),
    $.session.turns(),
    read($, usage),
  ])
  const breakdown = u.context.breakdown
  const slices: ContextSlice[] = (breakdown?.categories ?? []).flatMap(c =>
    c.kind === 'deferred' ? [] : [{ name: c.name, tokens: c.tokens, color: c.color, kind: c.kind }],
  )
  const tokens = u.context.tokens
  const snapshot: UsageSnapshot = {
    model,
    tokens,
    window: u.context.window,
    percent: u.context.percent,
    slices,
    sliceWindow: breakdown?.rawMaxTokens ?? u.context.window,
    deltaTokens:
      turnStartTokens !== undefined && tokens !== undefined ? tokens - turnStartTokens : prev?.deltaTokens,
    costUsd: u.cost?.usd,
    rateLimits: u.rateLimits.map(r => ({ kind: r.kind, percentUsed: r.percentUsed, resetsAt: r.resetsAt })),
    startedAt: u.startedAt,
    turns,
  }
  await update($, usage, () => snapshot)

  const sum = totals(await read($, tallies))
  const parts = [
    `ctx ${snapshot.percent ?? 0}%`,
    snapshot.costUsd === undefined ? undefined : fmtUsd(snapshot.costUsd),
    `${sum.count} tools`,
    sum.errors > 0 ? `${sum.errors} err` : undefined,
  ]
  $.ui.status(parts.filter(Boolean).join(' · '))
}

const summaryMarkdown = (
  u: UsageSnapshot | null,
  t: TurnInfo | null,
  list: readonly ToolTally[],
  now: number,
): string => {
  const sum = totals(list)
  const lines = ['**Status bar**', '']
  if (u !== null) {
    lines.push(
      `- Model: ${u.model}`,
      `- Context: ${u.percent ?? 0}% (${fmtTokens(u.tokens ?? 0)} / ${fmtTokens(u.window)})`,
      `- Cost: ${u.costUsd === undefined ? 'n/a' : fmtUsd(u.costUsd)}`,
      `- Prompts: ${u.turns}`,
      `- Session: ${fmtMs(now - u.startedAt)}`,
      ...u.rateLimits.map(r => `- Limit ${limitLabel(r.kind)}: ${r.percentUsed}%${r.resetsAt ? ` (resets ${r.resetsAt})` : ''}`),
    )
    if (u.slices.length > 0) {
      lines.push('', `| Context (of ${fmtTokens(u.sliceWindow)}) | Tokens | Share |`, `| --- | ---: | ---: |`)
      for (const s of u.slices) {
        lines.push(`| ${s.name} | ${fmtTokens(s.tokens)} | ${Math.round((s.tokens / Math.max(1, u.sliceWindow)) * 100)}% |`)
      }
    }
  }
  if (t !== null) {
    lines.push(
      `- Last turn: ${fmtMs(t.durationMs)}, ${t.tools} tool calls, ${t.reason}` +
        ` (in ${fmtTokens(t.inputTokens)}, out ${fmtTokens(t.outputTokens)},` +
        ` cache r/w ${fmtTokens(t.cacheReadTokens)}/${fmtTokens(t.cacheWriteTokens)})`,
    )
  }
  lines.push('', `| Tool | Calls | Errors | Denied | Total time | Avg |`, `| --- | ---: | ---: | ---: | ---: | ---: |`)
  for (const row of list) {
    lines.push(`| ${row.tool} | ${row.count} | ${row.errors} | ${row.denied} | ${fmtMs(row.totalMs)} | ${fmtMs(row.totalMs / row.count)} |`)
  }
  lines.push(`| **all** | ${sum.count} | ${sum.errors} | ${sum.denied} | ${fmtMs(sum.totalMs)} | |`)
  return lines.join('\n')
}

export const register: Register = on => {
  let running = 0
  let turnStartTokens: number | undefined

  on('session.start', async ($, e, next) => {
    // A reload drops in-flight bookkeeping; anything still "running" is orphaned.
    await update($, calls, list => list.map(c => (c.status === 'running' ? { ...c, status: 'lost' as const } : c)))
    const saved = await $.store.get(VIEW_STORE_KEY)
    if (typeof saved === 'string' && (VIEWS as readonly string[]).includes(saved)) {
      await update($, view, () => saved as BarView)
    }
    await $.command.register({
      name: 'status-bar',
      description: 'Status bar: full | compact | hide | show | reset; no args prints a full summary',
    })
    $.clock.every(1000, () => {
      if (running > 0) void update($, tick, n => n + 1)
    })
    $.clock.every(15_000, () => void refreshUsage($))
    await refreshUsage($)

    return next(e)
  })

  on('command.run', { command: 'status-bar' }, async ($, e) => {
    const arg = e.args.trim().toLowerCase()
    const setView = async (v: BarView) => {
      await update($, view, () => v)
      await $.store.set(VIEW_STORE_KEY, v)
      return { text: `Status bar: ${v}.` }
    }
    if (arg === 'full' || arg === 'show') return setView('full')
    if (arg === 'compact') return setView('compact')
    if (arg === 'hide' || arg === 'hidden') return setView('hidden')
    if (arg === 'reset') {
      await update($, calls, () => [])
      await update($, tallies, () => [])
      return { text: 'Status bar counters reset.' }
    }
    await refreshUsage($)
    const [u, t, list, now] = await Promise.all([read($, usage), read($, lastTurn), read($, tallies), $.clock.now()])
    return { text: summaryMarkdown(u, t, list, now) }
  })

  on('prompt.submit', async ($, e, next) => {
    await update($, turnTools, () => 0)
    turnStartTokens = (await read($, usage))?.tokens ?? 0
    return next(e)
  })

  on('tool.call', async ($, e, next) => {
    const call: ToolCallRecord = {
      id: e.tool_use_id,
      tool: e.tool,
      summary: summarize(e.tool, e as unknown as Record<string, unknown>),
      startedAt: await $.clock.now(),
      status: 'running',
      agentId: e.agentId,
    }
    running += 1
    await update($, calls, list => [...list, call].slice(-KEEP_CALLS))

    try {
      const ran = await next(e)
      const done: ToolCallRecord = {
        ...call,
        durationMs: (await $.clock.now()) - call.startedAt,
        status: ran.deny !== undefined ? 'denied' : ran.isError === true ? 'error' : 'ok',
        isReadOnly: ran.isReadOnly,
        resultChars: ran.text?.length,
      }
      await update($, calls, list => list.map(c => (c.id === call.id ? done : c)))
      await update($, tallies, list => tallyCall(list, done))
      if (e.agentId === undefined) await update($, turnTools, n => n + 1)
      return ran
    } finally {
      running = Math.max(0, running - 1)
    }
  })

  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    if (e.agentId === undefined) {
      const u = e.usage
      const info: TurnInfo = {
        durationMs: e.durationMs,
        tools: await read($, turnTools),
        reason: e.reason,
        model: u?.model,
        inputTokens: u?.input_tokens ?? 0,
        outputTokens: u?.output_tokens ?? 0,
        cacheReadTokens: u?.cache_read_input_tokens ?? 0,
        cacheWriteTokens: u?.cache_creation_input_tokens ?? 0,
      }
      await update($, lastTurn, () => info)
      await refreshUsage($, turnStartTokens)
    }
    return result
  })

  on('ui.render', { component: 'AbovePrompt' }, async ($, e, next) => {
    const mode = await read($, view)
    if (e.props.hasSurvey || mode === 'hidden') return next(e)

    const { Box, Button, Text } = $.ui.resolve(e)
    await read($, tick) // subscribe: running timers redraw each second
    const [u, list, tally, now] = await Promise.all([read($, usage), read($, calls), read($, tallies), $.clock.now()])
    const cols = e.props.bodyColumns
    const sum = totals(tally)

    // Measure against what the bar draws: /context's categories when the
    // breakdown is in, else the status line's single figure.
    const slices: ContextSlice[] =
      u === null
        ? []
        : u.slices.length > 0
          ? u.slices
          : [{ name: 'Used', tokens: u.tokens ?? 0, color: heat(u.percent ?? 0), kind: 'used' }]
    const ctxWindow = u === null ? 0 : u.slices.length > 0 ? u.sliceWindow : u.window
    const ctxUsed = slices.filter(s => s.kind === 'used').reduce((n, s) => n + s.tokens, 0)
    const pct = ctxWindow > 0 ? Math.round((ctxUsed / ctxWindow) * 100) : 0
    const delta = fmtDelta(u?.deltaTokens)

    const header = (
      <Box flexDirection="row" gap={1}>
        <Text bold>{u?.model ?? '…'}</Text>
        <Box flexDirection="row">
          {stackedBar(slices, ctxWindow, cols >= 120 ? 24 : cols >= 90 ? 16 : 10).map(seg => (
            <Text color={seg.color}>{seg.text}</Text>
          ))}
        </Box>
        <Text color={heat(pct)} bold>{pct}%</Text>
        <Text dimColor>
          {fmtTokens(ctxUsed)}/{fmtTokens(ctxWindow)}
        </Text>
        {delta !== '' && <Text dimColor>{delta}</Text>}
        {u?.costUsd !== undefined && <Text color="green">{fmtUsd(u.costUsd)}</Text>}
        {(u?.rateLimits ?? []).map(r => (
          <Text color={heat(r.percentUsed)}>
            {limitLabel(r.kind)} {Math.round(r.percentUsed)}%
          </Text>
        ))}
        {sum.count > 0 && (
          <Text color={sum.errors > 0 ? 'red' : undefined} dimColor={sum.errors === 0}>
            ⚒ {sum.count}
            {sum.errors > 0 ? ` ✗${sum.errors}` : ''}
          </Text>
        )}
        <Button
          key="mode"
          plain
          label={mode === 'full' ? '▴' : '▾'}
          onPress={() => update($, view, v => (v === 'full' ? 'compact' : 'full'))}
        />
        <Button key="hide" plain label="×" onPress={() => update($, view, () => 'hidden')} />
      </Box>
    )
    if (mode === 'compact') return header

    const legend = cols >= 60 ? legendSlices(u?.slices ?? [], LEGEND_SLICES) : []
    const inFlight = list.filter(c => c.status === 'running')
    const recentRoom = Math.max(0, Math.min(RECENT_CALLS, e.props.maxRows - 2 - inFlight.length))
    const recent = recentRoom === 0 ? [] : list.filter(c => c.status !== 'running').slice(-recentRoom).reverse()
    const shownCalls = [...inFlight, ...recent]
    const toolCol = Math.min(18, Math.max(6, ...shownCalls.map(c => toolLabel(c.tool).length)))

    const row = (c: ToolCallRecord) => (
      <Box flexDirection="row" gap={1}>
        <Text dimColor>{fmtClock(c.startedAt)}</Text>
        <Text color={STATUS_COLOR[c.status]}>{STATUS_GLYPH[c.status]}</Text>
        <Text bold>{toolLabel(c.tool).padEnd(toolCol)}</Text>
        <Text dimColor>
          {fmtMs(c.status === 'running' ? now - c.startedAt : (c.durationMs ?? 0)).padStart(6)}
        </Text>
        {c.agentId !== undefined && <Text color="magenta">↳{c.agentId.slice(0, 6)}</Text>}
        <Text dimColor wrap="truncate-end">
          {c.summary}
        </Text>
      </Box>
    )

    return (
      <Box flexDirection="column">
        {header}
        {legend.length > 0 && (
          <Box flexDirection="row" gap={2}>
            {legend.map(s => (
              <Text wrap="truncate-end">
                <Text color={s.color}>{sliceGlyph(s.kind)}</Text>
                <Text dimColor>
                  {' '}
                  {s.name} {fmtTokens(s.tokens)}
                </Text>
              </Text>
            ))}
          </Box>
        )}
        {shownCalls.map(row)}
      </Box>
    )
  })
}
