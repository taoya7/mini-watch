import { createPinia } from 'pinia'

import { useAppStore } from './app'
import { useConsoleStore } from './console'
import { useWsStore } from './ws'

export const pinia = createPinia()

export { useAppStore, useConsoleStore, useWsStore }

/**
 * 获取所有 store
 */
export function useStore() {
  const app = useAppStore()
  const ws = useWsStore()
  const consoleStore = useConsoleStore()
  return {
    app,
    ws,
    console: consoleStore,
  }
}
