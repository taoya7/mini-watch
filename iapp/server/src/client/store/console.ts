import type { LogItem } from '@client/types/ws'

/**
 * 控制台日志 store：只负责存日志 + 清空
 */
const MAX_LOGS = 60

export const useConsoleStore = defineStore('console', () => {
  const logs = ref<LogItem[]>([])
  let seq = 0

  function push(raw: string) {
    seq += 1
    logs.value.unshift({
      id: seq,
      time: new Date().toLocaleTimeString('zh-CN', { hour12: false }),
      raw,
    })
    if (logs.value.length > MAX_LOGS) logs.value.length = MAX_LOGS
  }

  function clear() {
    logs.value = []
    seq = 0
  }

  return { logs, push, clear }
})

if (import.meta.hot)
  import.meta.hot.accept(acceptHMRUpdate(useConsoleStore, import.meta.hot))
