import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { Activity, ActivityKind, Elephant, Goldfish, MemoryEvent } from '../types'

const PANE = 'elephant-goldfish'
const TITLE = 'Elephant & Goldfish'
const KEEP = 3000

// Bump a shape tag when that value's fields change: the old stored value is
// declined instead of read with the wrong fields.
const fresh = (): Elephant => ({ startedAt: Date.now(), prompts: 0, compactions: 0, reads: 0, writes: 0, searches: 0 })
const elephant = atom({ plugin: 'elephant-goldfish', key: 'elephant' } as const, fresh(), { shape: 'elephant-1' })
const memory = atom({ plugin: 'elephant-goldfish', key: 'memory' } as const, [] as MemoryEvent[], { shape: 'memory-1' })
const goldfish = atom({ plugin: 'elephant-goldfish', key: 'goldfish' } as const, [] as Goldfish[], { shape: 'goldfish-1' })
const activity = atom({ plugin: 'elephant-goldfish', key: 'activity' } as const, [] as Activity[], { shape: 'activity-1' })

/** A tool argument by name, whatever the tool. */
const arg = (e: unknown, key: string): string => {
  const v = (e as Record<string, unknown>)[key]
  return typeof v === 'string' ? v : ''
}
const clip = (s: string, n: number) => (s.length > n ? s.slice(0, n - 1) + '…' : s)
const short = (p: string) => p.replace(/\\/g, '/').split('/').slice(-2).join('/')

/** Paths and commands that touch memory meant to outlive the session. */
const isMemoryPath = (p: string) =>
  /[\\/]memory[\\/]/i.test(p) || /(^|[\\/])(CLAUDE|MEMORY)\.md$/i.test(p)
const brainOp = (cmd: string): 'stored' | 'recalled' | undefined => {
  if (!/vii-brain/.test(cmd)) return undefined
  if (/\b(add|learn|put|save)\b/.test(cmd)) return 'stored'
  if (/\b(search|list|query|get)\b/.test(cmd)) return 'recalled'
  return undefined
}

type Seen = { kind: ActivityKind; text: string; counter?: 'reads' | 'writes' | 'searches'; mem?: MemoryEvent['kind']; where?: string }

/** What a tool call means for the picture: a read, a write, a memory op... */
const classify = (e: { tool: string }): Seen => {
  const t = e.tool
  const file = arg(e, 'file_path') || arg(e, 'notebook_path')
  if (t === 'Read') {
    return isMemoryPath(file)
      ? { kind: 'recall', text: `recalled ${short(file)}`, counter: 'reads', mem: 'recalled', where: short(file) }
      : { kind: 'read', text: `read ${short(file)}`, counter: 'reads' }
  }
  if (t === 'Write' || t === 'Edit' || t === 'NotebookEdit') {
    return isMemoryPath(file)
      ? { kind: 'store', text: `stored ${short(file)}`, counter: 'writes', mem: 'stored', where: short(file) }
      : { kind: 'write', text: `${t === 'Write' ? 'wrote' : 'edited'} ${short(file)}`, counter: 'writes' }
  }
  if (t === 'Grep' || t === 'Glob') {
    return { kind: 'search', text: `${t.toLowerCase()} ${clip(arg(e, 'pattern'), 40)}`, counter: 'searches' }
  }
  if (t === 'WebFetch' || t === 'WebSearch') {
    return { kind: 'read', text: `${t} ${clip(arg(e, 'url') || arg(e, 'query'), 50)}`, counter: 'reads' }
  }
  if (t === 'Bash' || t === 'PowerShell') {
    const cmd = arg(e, 'command')
    const op = brainOp(cmd)
    if (op) return { kind: op === 'stored' ? 'store' : 'recall', text: `vii-brain ${op}`, mem: op, where: 'vii-brain' }
    return { kind: 'tool', text: `$ ${clip(cmd.split('\n')[0] ?? '', 50)}` }
  }
  return { kind: 'tool', text: t }
}

async function log($: EngineInterface, a: Omit<Activity, 'at'>): Promise<void> {
  await update($, activity, list => [...list, { ...a, at: Date.now() }].slice(-KEEP))
}

/** Pours the recording into the bundled player and opens it in the browser. */
async function writeReplay($: EngineInterface): Promise<string> {
  const [ele, mem, fish, acts] = await Promise.all([read($, elephant), read($, memory), read($, goldfish), read($, activity)])
  if (acts.length === 0) return 'Nothing recorded yet. Use the session a little, then run replay.'
  const cwd = await $.session.cwd()
  const data = { project: cwd.replace(/\\/g, '/').split('/').pop(), generatedAt: Date.now(), elephant: ele, memory: mem, goldfish: fish, activity: acts }
  const template = await $.fs.read(`${$.plugin.root}/assets/replay.html`)
  const html = String(template).replace('"__EG_DATA__"', () => JSON.stringify(data).replace(/</g, '\\u003c'))
  const stamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19)
  const dir = `${cwd}/.elephant-goldfish`
  const file = `${dir}/replay-${stamp}.html`
  await $.fs.write(file, html)
  if (!(await $.fs.exists(`${dir}/.gitignore`))) await $.fs.write(`${dir}/.gitignore`, '*\n')
  for (const argv of [['cmd', '/c', 'start', '', file], ['open', file], ['xdg-open', file]]) {
    try { if ((await $.process.run(argv, { timeoutMs: 5000 })).exitCode === 0) break } catch { /* try the next opener */ }
  }
  return `Replay written: ${file} (${acts.length} events, ${fish.length} goldfish)`
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'elephant-goldfish',
      description: 'Elephant & goldfish view of this session. Args: (none) open pane · replay · reset',
    })
    void $.ui.open({ id: PANE, title: TITLE })
    return next(e)
  })

  on('prompt.submit', async ($, e, next) => {
    await update($, elephant, s => ({ ...s, prompts: s.prompts + 1 }))
    await log($, { lane: 'elephant', kind: 'prompt', text: `you: ${clip(e.text.replace(/\s+/g, ' '), 80)}` })
    return next(e)
  })

  on('session.compact', async ($, e, next) => {
    if (!e.agentId) {
      await update($, elephant, s => ({ ...s, compactions: s.compactions + 1 }))
      await log($, { lane: 'elephant', kind: 'compact', text: 'context compacted: older turns summarized' })
    }
    return next(e)
  })

  // A goldfish is born: record exactly what it was told, since that is all it knows.
  on('agent.spawn', async ($, e, next) => {
    const r = await next(e)
    if ('agentId' in r && r.agentId) {
      const g: Goldfish = {
        agentId: r.agentId, toolUseId: e.tool_use_id, type: e.subagentType,
        description: e.description, isFork: e.fork, brief: clip(e.prompt, 600),
        briefChars: e.prompt.length, status: 'running', tools: 0, reads: [],
        returnedChars: 0, startedAt: Date.now(),
      }
      await update($, goldfish, list => [...list, g].slice(-100))
      await log($, {
        lane: 'goldfish', kind: 'spawn', agentId: g.agentId,
        text: `${g.isFork ? 'fork (inherits memory)' : 'goldfish'} ${g.type}: ${g.description} · given ${g.briefChars} chars`,
      })
    }
    return r
  })

  on('tool.call', async ($, e, next) => {
    const seen = classify(e)
    const fishId = e.agentId

    if (fishId) {
      await update($, goldfish, list => list.map(g => g.agentId !== fishId ? g : {
        ...g, tools: g.tools + 1,
        reads: seen.kind === 'read' || seen.kind === 'recall' ? [...g.reads, seen.text.replace(/^\w+ /, '')].slice(-20) : g.reads,
      }))
    } else if (seen.counter) {
      const c = seen.counter
      await update($, elephant, s => ({ ...s, [c]: s[c] + 1 }))
    }
    if (seen.mem && seen.where) {
      const m: MemoryEvent = { kind: seen.mem, where: seen.where, by: fishId ? 'goldfish' : 'elephant', at: Date.now() }
      await update($, memory, list => [...list, m].slice(-200))
    }
    if (e.tool !== 'Agent') {
      await log($, { lane: fishId ? 'goldfish' : 'elephant', kind: seen.kind, text: seen.text, agentId: fishId })
    }

    const ran = await next(e)

    // The Agent call returning is the goldfish handing its report back.
    if (e.tool === 'Agent' && e.tool_use_id) {
      const id = e.tool_use_id
      const failed = 'isError' in ran && !!ran.isError
      const chars = 'text' in ran && typeof ran.text === 'string' ? ran.text.length : 0
      let fish: Goldfish | undefined
      await update($, goldfish, list => list.map(g => {
        if (g.toolUseId !== id || g.status !== 'running') return g
        // A background spawn returns at once; only a real answer ends it.
        if (chars < 200 && !failed) return g
        fish = { ...g, status: failed ? 'failed' : 'done', returnedChars: chars, endedAt: Date.now() }
        return fish
      }))
      if (fish) {
        await log($, {
          lane: 'goldfish', kind: 'return', agentId: fish.agentId,
          text: `${fish.type} returned ${chars} chars, then forgot everything`,
        })
      }
    }
    return ran
  })

  on('command.run', { command: 'elephant-goldfish' }, async ($, e) => {
    const sub = e.args.trim().toLowerCase()
    if (sub === 'reset') {
      await update($, elephant, () => fresh())
      await update($, memory, () => [])
      await update($, goldfish, () => [])
      await update($, activity, () => [])
      return { text: 'Elephant & goldfish recording cleared.' }
    }
    if (sub === 'replay') return { text: await writeReplay($) }
    await $.ui.open({ id: PANE, title: TITLE })
    return { text: 'Pane opened. /elephant-goldfish replay builds an animated replay of this session.' }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const [ele, mem, fish, acts] = await Promise.all([read($, elephant), read($, memory), read($, goldfish), read($, activity)])
    const width = Math.max(20, (e.props.bodyColumns ?? e.viewport?.columns ?? 60) - 2)
    const rows = e.viewport?.rows ?? 30
    const running = fish.filter(g => g.status === 'running').length
    const mins = Math.max(1, Math.round((Date.now() - ele.startedAt) / 60000))
    const feed = acts.slice(-Math.max(3, rows - 22 - Math.min(fish.length, 6) * 2 - Math.min(mem.length, 4)))

    return (
      <Box flexDirection="column">
        <Text bold color="blue">🐘 ELEPHANT  main session · remembers everything</Text>
        <Text dimColor>{`${ele.prompts} prompts · ${mins} min · compacted ${ele.compactions}×`}</Text>
        <Text>{`working data: read ${ele.reads} · wrote ${ele.writes} · searched ${ele.searches}`}</Text>
        <Text bold>Long-term memory (outlives the session)</Text>
        {mem.length === 0 && <Text dimColor>  nothing stored or recalled yet</Text>}
        {mem.slice(-4).map(m => (
          <Text color={m.kind === 'stored' ? 'green' : undefined}>
            {clip(`  ${m.kind === 'stored' ? '✎ stored' : '↺ recalled'} ${m.where}${m.by === 'goldfish' ? ' (by goldfish)' : ''}`, width)}
          </Text>
        ))}
        <Text> </Text>
        <Text bold color="yellow">{`🐟 GOLDFISH  ${fish.length} spawned · ${running} running`}</Text>
        {fish.length === 0 && <Text dimColor>  no subagents yet: each starts with zero memory</Text>}
        {fish.slice(-6).map(g => (
          <Box flexDirection="column">
            <Text color={g.isFork ? 'red' : g.status === 'running' ? 'yellow' : undefined} dimColor={g.status === 'done'}>
              {clip(`  ${g.status === 'running' ? '●' : g.status === 'done' ? '✓' : '✗'} ${g.isFork ? 'FORK ' : ''}${g.type}: ${g.description}`, width)}
            </Text>
            <Text dimColor>
              {clip(`    knew ${g.briefChars} chars · ${g.tools} tools · read ${g.reads.length}${g.returnedChars ? ` · returned ${g.returnedChars}` : ''}`, width)}
            </Text>
          </Box>
        ))}
        <Text> </Text>
        <Text bold>Activity</Text>
        {feed.map(a => (
          <Text color={a.kind === 'store' ? 'green' : a.lane === 'goldfish' ? 'yellow' : undefined} dimColor={a.kind === 'read' || a.kind === 'search'}>
            {clip(`${a.lane === 'goldfish' ? '🐟' : '🐘'} ${a.text}`, width)}
          </Text>
        ))}
        <Text dimColor>/elephant-goldfish replay → animated replay</Text>
      </Box>
    )
  })
}
