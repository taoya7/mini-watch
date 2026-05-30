import type { BaseInfo } from '@client/types/base-info'
import type { PageInfo, WsStatus } from '@client/types/ws'
import { useConsoleStore } from './console'

// ─── 模块级单例（连接本身不进 store state，避免 HMR 重建丢失） ───
let ws: WebSocket | null = null
let reconnectTimer: ReturnType<typeof setTimeout> | null = null
let pingTimer: ReturnType<typeof setInterval> | null = null
let started = false

const PING_MS = 25_000
const RECONNECT_MS = 3_000

export const useWsStore = defineStore('ws', () => {
  const consoleStore = useConsoleStore()

  const status = ref<WsStatus>('closed')
  const onlineCount = ref(0)
  const currentPage = ref<PageInfo | null>(null)
  const currentThemeId = ref<string>('amber')
  const baseInfo = ref<BaseInfo | null>(null)
  const brightness = ref<number>(80)
  const volume = ref<number>(50)

  function _connect() {
    const proto = location.protocol === 'https:' ? 'wss' : 'ws'
    const url = `${proto}://${location.host}/api/ws`
    status.value = 'connecting'
    ws = new WebSocket(url)

    ws.onopen = () => {
      status.value = 'open'
      consoleStore.push('[open] connected')
      if (pingTimer) clearInterval(pingTimer)
      pingTimer = setInterval(() => {
        if (ws?.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({ type: 'ping', ts: Date.now() }))
        }
      }, PING_MS)
    }

    ws.onclose = () => {
      status.value = 'closed'
      consoleStore.push('[close] disconnected, retry in 3s')
      if (pingTimer) { clearInterval(pingTimer); pingTimer = null }
      if (reconnectTimer) clearTimeout(reconnectTimer)
      reconnectTimer = setTimeout(_connect, RECONNECT_MS)
    }

    ws.onerror = () => consoleStore.push('[error] socket error')

    ws.onmessage = (e) => {
      consoleStore.push(String(e.data))
      try {
        const msg = JSON.parse(e.data)
        switch (msg.type) {
          case 'page_change':
            if (msg.page) currentPage.value = msg.page as PageInfo
            break
          case 'online':
            onlineCount.value = msg.count ?? 0
            break
          case 'theme_change':
            if (typeof msg.theme_id === 'string') currentThemeId.value = msg.theme_id
            break
          case 'base_info':
            if (msg.data) baseInfo.value = msg.data as BaseInfo
            break
          case 'brightness_change':
            if (typeof msg.value === 'number') brightness.value = msg.value
            break
          case 'volume_change':
            if (typeof msg.value === 'number') volume.value = msg.value
            break
        }
      }
      catch {}
    }
  }

  /** 第一次调用时启动连接，重复调用幂等 */
  function init() {
    if (started) return
    started = true
    _connect()
  }

  function send(payload: Record<string, unknown>) {
    if (status.value !== 'open' || !ws) return
    ws.send(JSON.stringify({ ...payload, ts: payload.ts ?? Date.now() }))
  }

  return {
    status,
    onlineCount,
    currentPage,
    currentThemeId,
    baseInfo,
    brightness,
    volume,
    init,
    send,
  }
})

// HMR：1. 用 acceptHMRUpdate 让 Pinia 处理 store 替换
//      2. 用 dispose 把旧 ws/timer 主动清掉，避免服务端 peers 累加
if (import.meta.hot) {
  import.meta.hot.accept(acceptHMRUpdate(useWsStore, import.meta.hot))
  import.meta.hot.dispose(() => {
    if (reconnectTimer) { clearTimeout(reconnectTimer); reconnectTimer = null }
    if (pingTimer) { clearInterval(pingTimer); pingTimer = null }
    if (ws) {
      ws.onopen = null
      ws.onclose = null
      ws.onerror = null
      ws.onmessage = null
      if (ws.readyState === WebSocket.OPEN
        || ws.readyState === WebSocket.CONNECTING) {
        ws.close(1000, 'hmr')
      }
      ws = null
    }
    started = false
  })
}
