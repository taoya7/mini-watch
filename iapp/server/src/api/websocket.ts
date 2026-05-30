import type { Hono } from 'hono'
import type { WSContext } from 'hono/ws'
import type { AppBindings } from '@/lib/create-app'
import { createNodeWebSocket } from '@hono/node-ws'
import { describeRoute } from 'hono-openapi'
import { logger } from '@/lib/logger'
import { storage } from '@/lib/cache'
import { getBaseInfo } from '@/lib/base-info'
import {
  collectSystemStats,
  getHistory,
  startStatsPump,
  stopStatsPump,
} from '@/lib/system-stats'

const STATS_INTERVAL_MS = 5000
// 哪些 page_id 需要打开 stats 泵
const STATS_PAGES = new Set<string>(['home'])

// 暴露给其他模块（HTTP 路由）的广播入口
let _wsBroadcast: ((p: Record<string, unknown>) => void) | null = null
export function broadcastToAll(payload: Record<string, unknown>) {
  _wsBroadcast?.(payload)
}

// 缓存 key 常量
const KEY_CURRENT_PAGE = 'mobile:current_page'
const KEY_CURRENT_THEME = 'mobile:current_theme'
const KEY_CURRENT_BRIGHTNESS = 'mobile:current_brightness'
const KEY_CURRENT_VOLUME = 'mobile:current_volume'

export function attachWebSocket(app: Hono<AppBindings>) {
  const log = logger.child('ws')
  const { injectWebSocket, upgradeWebSocket } = createNodeWebSocket({ app })

  // 在线连接池 + 最近活跃时间戳
  const peers = new Map<WSContext, number>()
  // 每个 peer 当前所在 page，用来决定是否打开 stats 泵
  const peerPages = new Map<WSContext, string>()
  const STALE_MS = 90_000

  function broadcast(payload: Record<string, unknown>) {
    const str = JSON.stringify(payload)
    for (const peer of peers.keys()) peer.send(str)
  }
  _wsBroadcast = broadcast

  function broadcastOnline() {
    broadcast({ type: 'online', count: peers.size, ts: Date.now() })
  }

  function touch(ws: WSContext) {
    peers.set(ws, Date.now())
  }

  // 任何 peer 处在需要 stats 的 page 时，泵开
  function anyOnStatsPage(): boolean {
    for (const p of peerPages.values()) if (STATS_PAGES.has(p)) return true
    return false
  }

  function evaluatePump() {
    if (anyOnStatsPage()) {
      startStatsPump(
        STATS_INTERVAL_MS,
        stats => broadcast({ type: 'system_stats', data: stats, ts: Date.now() }),
        anyOnStatsPage,
      )
    }
    else {
      stopStatsPump()
    }
  }

  // 僵尸连接清扫
  const sweepTimer = setInterval(() => {
    const now = Date.now()
    let removed = 0
    for (const [peer, last] of peers) {
      if (now - last > STALE_MS) {
        try { peer.close() }
        catch {}
        peers.delete(peer)
        peerPages.delete(peer)
        removed += 1
      }
    }
    if (removed > 0) {
      log.info(`swept ${removed} stale peer(s), total=${peers.size}`)
      broadcastOnline()
      evaluatePump()
    }
  }, 30_000)
  sweepTimer.unref?.()

  app.get(
    '/api/ws',
    describeRoute({
      description: 'WebSocket 长连接入口（升级协议）',
      tags: ['系统'],
    }),
    upgradeWebSocket(_c => ({
      async onOpen(_evt, ws) {
        touch(ws)
        log.info(`connected, total=${peers.size}`)
        // 1. 握手
        ws.send(JSON.stringify({ type: 'hello', ts: Date.now() }))
        // 2. 主机基础信息
        const base = await getBaseInfo()
        if (base) {
          ws.send(JSON.stringify({
            type: 'base_info',
            data: base,
            ts: Date.now(),
          }))
        }
        // 3. 历史 stats（持久化到磁盘，断线重连后画 chart 不再空白）
        const history = getHistory()
        if (history.length > 0) {
          ws.send(JSON.stringify({
            type: 'stats_history',
            data: history,
            ts: Date.now(),
          }))
        }
        // 4. 同步当前 page / theme
        const current = await storage.getItem(KEY_CURRENT_PAGE)
        if (current) {
          ws.send(JSON.stringify({
            type: 'page_change',
            page: current,
            ts: Date.now(),
          }))
        }
        const theme = await storage.getItem<string>(KEY_CURRENT_THEME)
        if (theme) {
          ws.send(JSON.stringify({
            type: 'theme_change',
            theme_id: theme,
            ts: Date.now(),
          }))
        }
        const brightness = await storage.getItem<number>(KEY_CURRENT_BRIGHTNESS)
        if (typeof brightness === 'number') {
          ws.send(JSON.stringify({
            type: 'brightness_change',
            value: brightness,
            ts: Date.now(),
          }))
        }
        const volume = await storage.getItem<number>(KEY_CURRENT_VOLUME)
        if (typeof volume === 'number') {
          ws.send(JSON.stringify({
            type: 'volume_change',
            value: volume,
            ts: Date.now(),
          }))
        }
        // 5. 通知在线数
        broadcastOnline()
      },
      async onMessage(evt, ws) {
        touch(ws)
        const raw = String(evt.data ?? '')
        log.info(`recv: ${raw.slice(0, 200)}`)
        let msg: any
        try { msg = JSON.parse(raw) }
        catch {
          ws.send(JSON.stringify({ type: 'error', error: 'invalid_json' }))
          return
        }
        if (msg?.type === 'ping') {
          ws.send(JSON.stringify({ type: 'pong', ts: Date.now() }))
          return
        }
        if (msg?.type === 'getBaseInfo') {
          const base = await getBaseInfo()
          ws.send(JSON.stringify({
            type: 'base_info',
            data: base,
            ts: Date.now(),
          }))
          return
        }
        // ─── 页面切换：缓存 + 广播 + 调整 pump ─────
        if (msg?.type === 'page_change' && msg?.page) {
          const pageId = msg.page.id
          if (typeof pageId === 'string') peerPages.set(ws, pageId)
          await storage.setItem(KEY_CURRENT_PAGE, msg.page)
          broadcast({
            type: 'page_change',
            page: msg.page,
            ts: Date.now(),
          })
          // 进入 home 时立刻给该 peer 推一帧最新 stats（避免等 5s）
          if (STATS_PAGES.has(pageId)) {
            collectSystemStats()
              .then(s => ws.send(JSON.stringify({
                type: 'system_stats',
                data: s,
                ts: Date.now(),
              })))
              .catch(() => {})
          }
          evaluatePump()
          return
        }
        if (msg?.type === 'theme_change' && typeof msg?.theme_id === 'string') {
          await storage.setItem(KEY_CURRENT_THEME, msg.theme_id)
          broadcast({
            type: 'theme_change',
            theme_id: msg.theme_id,
            ts: Date.now(),
          })
          return
        }
        // ─── 屏幕亮度（0..100，整数）─────────────
        if (msg?.type === 'brightness_change' && typeof msg?.value === 'number') {
          const v = Math.max(0, Math.min(100, Math.round(msg.value)))
          await storage.setItem(KEY_CURRENT_BRIGHTNESS, v)
          broadcast({
            type: 'brightness_change',
            value: v,
            ts: Date.now(),
          })
          return
        }
        // ─── 音量（0..100，整数）─────────────────
        if (msg?.type === 'volume_change' && typeof msg?.value === 'number') {
          const v = Math.max(0, Math.min(100, Math.round(msg.value)))
          await storage.setItem(KEY_CURRENT_VOLUME, v)
          broadcast({
            type: 'volume_change',
            value: v,
            ts: Date.now(),
          })
          return
        }
        if (msg?.type === 'goto_page' && typeof msg?.page_id === 'string') {
          broadcast({
            type: 'goto_page',
            page_id: msg.page_id,
            ts: Date.now(),
          })
          return
        }
        broadcast({ type: 'broadcast', data: msg, ts: Date.now() })
      },
      onClose(_evt, ws) {
        peers.delete(ws)
        peerPages.delete(ws)
        log.info(`closed, total=${peers.size}`)
        broadcastOnline()
        evaluatePump()
      },
      onError(evt, ws) {
        peers.delete(ws)
        peerPages.delete(ws)
        log.warn(`error: ${String(evt)}`)
        broadcastOnline()
        evaluatePump()
      },
    })),
  )

  return injectWebSocket
}
