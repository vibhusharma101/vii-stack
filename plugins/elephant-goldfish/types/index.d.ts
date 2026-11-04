/** Running totals for the main loop (the elephant). */
export type Elephant = {
  startedAt: number
  prompts: number
  compactions: number
  reads: number
  writes: number
  searches: number
}

/** One write to, or recall from, memory that outlives the session. */
export type MemoryEvent = {
  kind: 'stored' | 'recalled'
  where: string
  by: 'elephant' | 'goldfish'
  at: number
}

/** One subagent. A fork inherits the parent's context, so it is no goldfish. */
export type Goldfish = {
  agentId: string
  toolUseId: string
  type: string
  description: string
  isFork: boolean
  brief: string
  briefChars: number
  status: 'running' | 'done' | 'failed'
  tools: number
  reads: string[]
  returnedChars: number
  startedAt: number
  endedAt?: number
}

export type ActivityKind =
  | 'prompt' | 'read' | 'write' | 'search' | 'tool'
  | 'spawn' | 'return' | 'store' | 'recall' | 'compact'

/** One recorded event: the pane's feed and the replay's frames. */
export type Activity = {
  at: number
  lane: 'elephant' | 'goldfish'
  kind: ActivityKind
  text: string
  agentId?: string
}

declare module 'claude-code' {
  interface PluginState {
    'elephant-goldfish': {
      elephant: Shaped<Elephant>
      memory: Shaped<MemoryEvent[]>
      goldfish: Shaped<Goldfish[]>
      activity: Shaped<Activity[]>
    }
  }
}
