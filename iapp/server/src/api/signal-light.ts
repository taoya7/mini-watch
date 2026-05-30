import { describeRoute } from 'hono-openapi'
import { createRouter } from '@/lib/create-app'
import { storage } from '@/lib/cache'
import { logger } from '@/lib/logger'
import { broadcastToAll } from './websocket'

const log = logger.child('signal-light')
const router = createRouter()

const KEY_SESSIONS = 'signal_light:sessions'
const SESSION_TTL_MS = 24 * 60 * 60 * 1000 // 24h

// ─── 灯语聚合规则
// 红：权限/阻塞/失败（卡住流程，需立即处理）
// 黄：纯通知，等你看一眼但不阻塞
const RED = new Set(['blocked', 'permission'])
const YELLOW = new Set(['attention', 'done'])
const WORKING = new Set(['thinking', 'working', 'tool_done'])
const END = new Set(['session_end', 'turn_end'])
const CLEAR = new Set(['off'])

interface SessionEntry {
  signal: string
  updated_at: number
}
type Sessions = Record<string, SessionEntry>

function aggregate(sessions: Sessions): string {
  const vals = Object.values(sessions).map(s => s.signal)
  if (vals.some(v => RED.has(v))) return 'blocked'
  if (vals.some(v => YELLOW.has(v))) return 'attention'
  if (vals.some(v => WORKING.has(v))) return 'working'
  return 'idle'
}

function prune(sessions: Sessions, now: number): Sessions {
  const out: Sessions = {}
  for (const [k, v] of Object.entries(sessions)) {
    if (now - v.updated_at < SESSION_TTL_MS) out[k] = v
  }
  return out
}

router.post(
  '/api/signal-light/state',
  describeRoute({
    description: 'AI Agent 灯语事件上报（Claude Code hook 调用）',
    tags: ['Signal Light'],
  }),
  async c => {
    let body: any
    try { body = await c.req.json() }
    catch { return c.json({ error: 'invalid_json' }, 400) }

    const signalName = String(body?.signal ?? '').trim()
    const sessionId = String(body?.session_id ?? 'global').trim()
    if (!signalName) return c.json({ error: 'missing_signal' }, 400)

    const now = Date.now()
    let sessions = await storage.getItem<Sessions>(KEY_SESSIONS) ?? {}
    sessions = prune(sessions, now)

    if (END.has(signalName) || CLEAR.has(signalName)) {
      delete sessions[sessionId]
    }
    else {
      sessions[sessionId] = { signal: signalName, updated_at: now }
    }

    const agg = aggregate(sessions)
    await storage.setItem(KEY_SESSIONS, sessions)

    log.info(`session=${sessionId} signal=${signalName} aggregate=${agg} active=${Object.keys(sessions).length}`)

    // 推 ws：手机 / web 都收到
    broadcastToAll({
      type: 'signal_light',
      aggregate: agg,
      session_id: sessionId,
      signal: signalName,
      active_sessions: Object.keys(sessions).length,
      ts: now,
    })

    return c.json({ aggregate: agg, active_sessions: Object.keys(sessions).length })
  },
)

router.get(
  '/api/signal-light/state',
  describeRoute({
    description: '查询当前聚合灯语状态',
    tags: ['Signal Light'],
  }),
  async c => {
    const sessions = await storage.getItem<Sessions>(KEY_SESSIONS) ?? {}
    const agg = aggregate(prune(sessions, Date.now()))
    return c.json({
      aggregate: agg,
      sessions,
    })
  },
)

export default router
