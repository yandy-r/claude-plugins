import type { ContextCategory, ContextCategoryKind, On, RenderElement, SessionContextBreakdown } from 'claude-code'
import { expect, mock, test } from 'claude-code/testing'

import { fmtDelta, legendSlices, stackedBar, summarize, tallyCall, toolLabel } from '../hooks/format'

const BAND = {
  component: 'AbovePrompt',
  props: {
    hasSurvey: false,
    isWorking: true,
    maxRows: 20,
    bodyColumns: 120,
    scroll: { offset: 0, bodyRows: 19 },
    view: {},
  },
} as const

const category = (name: string, tokens: number, color: string, kind: ContextCategoryKind): ContextCategory => ({
  name,
  tokens,
  color,
  kind,
  isDeferred: kind === 'deferred',
})

const BREAKDOWN: SessionContextBreakdown = {
  categories: [
    category('System prompt', 4_000, 'promptBorder', 'used'),
    category('Messages', 80_000, 'permission', 'used'),
    category('MCP tools', 30_000, 'inactive', 'deferred'),
    category('Autocompact buffer', 16_000, 'inactive', 'buffer'),
    category('Free space', 100_000, 'inactive', 'free'),
  ],
  totalTokens: 84_000,
  maxTokens: 200_000,
  rawMaxTokens: 200_000,
  percentage: 42,
  model: 'claude-opus-5-5',
  autocompactSource: 'model-default',
  gridRows: [],
  memoryFiles: [],
  mcpTools: [],
  agents: [],
  isAutoCompactEnabled: true,
  apiUsage: null,
}

const world = (on: On) => {
  mock.store(on)
  mock.clock(on, { now: 1_700_000_000_000 })
  on('session.start', (_$, e) => ({ cwd: e.cwd }))
  on('session.model', () => ({ value: 'claude-opus-5-5' }))
  on('session.turns', () => ({ value: 3 }))
  on('session.usage', () => ({
    value: {
      startedAt: 1_700_000_000_000,
      context: { tokens: 84_000, window: 200_000, percent: 42, breakdown: BREAKDOWN },
      rateLimits: [{ kind: 'five_hour', percentUsed: 23.5 }],
      cost: { usd: 1.23 },
    },
  }))
  on('command.register', (_$, e) => ({ value: { command: e.name } }))
  on('ui.status', () => ({ value: undefined }))
}

test('summaries and labels', async () => {
  expect(summarize('Bash', { command: 'npm   test\n --watch' })).toBe('npm test --watch')
  expect(summarize('Read', { file_path: '/a/b.ts' })).toBe('/a/b.ts')
  expect(summarize('Agent', { subagent_type: 'Explore', description: 'find x' })).toBe('Explore: find x')
  expect(toolLabel('mcp__plugin_github_github__get_me')).toBe('github:get_me')
  const t = tallyCall([], { id: '1', tool: 'Bash', summary: '', startedAt: 0, durationMs: 5, status: 'error' })
  expect(t[0]).toEqual({ tool: 'Bash', count: 1, errors: 1, denied: 0, totalMs: 5 })
  expect(fmtDelta(12_300)).toBe('▲ 12k')
  expect(fmtDelta(0)).toBe('')
})

test('stacked bar fills exactly its width, a run per category', async () => {
  const slices = [
    { name: 'System prompt', tokens: 4_000, color: 'promptBorder', kind: 'used' as const },
    { name: 'Messages', tokens: 80_000, color: 'permission', kind: 'used' as const },
    { name: 'Free space', tokens: 116_000, color: 'inactive', kind: 'free' as const },
  ]
  for (const width of [10, 16, 24]) {
    const segs = stackedBar(slices, 200_000, width)
    expect(segs.map(s => s.text).join('').length).toBe(width)
  }
  const segs = stackedBar(slices, 200_000, 20)
  // System prompt is 0.4 of a cell: too small to draw, so only the legend names it.
  expect(segs.map(s => s.color)).toEqual(['permission', 'inactive'])
  expect(segs[0]?.text).toBe('████████')
  expect(segs[1]?.text).toBe('░'.repeat(12))
  expect(stackedBar(slices, 200_000, 100).map(s => s.color)).toEqual(['promptBorder', 'permission', 'inactive'])
  expect(legendSlices(slices, 1).map(s => s.name)).toEqual(['Messages', 'Free space'])
})

test('band shows tool calls, tallies and errors on every surface', async ($, on) => {
  world(on)
  on('tool.call', { tool: 'Bash' }, ($, e) =>
    e.command === 'false'
      ? { isError: true, result: 'exit 1', text: 'exit 1' }
      : { result: 'ok', text: 'ok' },
  )
  await $.session.start({ cwd: '/tmp', surface: 'terminal', isInteractive: true })
  await $.tool.call({ tool: 'Bash', command: 'echo hello' })
  await $.tool.call({ tool: 'Bash', command: 'false' })

  for (const surface of ['terminal', 'desktop'] as const) {
    const ui = await $.ui.mount({ plugin: 'status-bar', surface, ...BAND })
    expect(await ui.find({ type: 'Text', text: 'echo hello' })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /⚒ 2 ✗1/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /Messages 80k/ })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: /MCP tools/ })).toBeUndefined()
    expect(await ui.find({ type: 'Text', text: '42%' })).toBeDefined()
    expect(await ui.find({ type: 'Text', text: '$1.23' })).toBeDefined()

    await ui.press({ key: 'mode' })
    expect(await ui.find({ type: 'Text', text: 'echo hello' })).toBeUndefined()
    await ui.press({ key: 'mode' })
    await ui.unmount()
  }
})

test('/status-bar prints a summary and toggles the view', async ($, on) => {
  world(on)
  on('ui.render', { component: 'AbovePrompt' }, ($, e) => {
    const { Text } = $.ui.resolve(e)
    return h(Text, { key: 'engine' }, 'engine band') as RenderElement
  })
  await $.session.start({ cwd: '/tmp', surface: 'terminal', isInteractive: true })
  const presentation = { isFullscreen: false, columns: 120 }
  const summary = await $.command.run({ command: 'status-bar', args: '', presentation } as never)
  expect(JSON.stringify(summary)).toContain('| Tool | Calls |')
  await $.command.run({ command: 'status-bar', args: 'hide', presentation } as never)
  const ui = await $.ui.mount({ plugin: 'status-bar', surface: 'terminal', ...BAND })
  expect(await ui.find({ key: 'mode' })).toBeUndefined()
  expect(await ui.find({ text: 'engine band' })).toBeDefined()
})
