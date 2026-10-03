export type CallStatus = 'running' | 'ok' | 'error' | 'denied' | 'lost'

export type ToolCallRecord = {
  id: string
  tool: string
  summary: string
  startedAt: number
  durationMs?: number
  status: CallStatus
  agentId?: string
  isReadOnly?: boolean
  resultChars?: number
}

export type ToolTally = {
  tool: string
  count: number
  errors: number
  denied: number
  totalMs: number
}

/** One /context category, as the stacked bar draws it. */
export type ContextSlice = {
  name: string
  tokens: number
  /** Theme key /context draws the category in. */
  color: string
  kind: 'used' | 'free' | 'buffer'
}

/** A run of same-category cells in the stacked bar. */
export type BarSegment = { color: string; text: string }

export type RateLimitReading = { kind: string; percentUsed: number; resetsAt?: string }

export type UsageSnapshot = {
  model: string
  tokens?: number
  window: number
  percent?: number
  /** /context's categories, measured against `sliceWindow` (the compaction window). */
  slices: ContextSlice[]
  sliceWindow: number
  /** Context tokens the last main-loop turn added (negative after a compaction). */
  deltaTokens?: number
  costUsd?: number
  rateLimits: RateLimitReading[]
  startedAt: number
  turns: number
}

export type TurnInfo = {
  durationMs: number
  tools: number
  reason: string
  model?: string
  inputTokens: number
  outputTokens: number
  cacheReadTokens: number
  cacheWriteTokens: number
}

export type BarView = 'full' | 'compact' | 'hidden'

declare module 'claude-code' {
  interface PluginState {
    'status-bar': {
      calls: ToolCallRecord[]
      tallies: ToolTally[]
      usage: UsageSnapshot | null
      lastTurn: TurnInfo | null
      turnTools: number
      tick: number
      view: BarView
    }
  }
}
