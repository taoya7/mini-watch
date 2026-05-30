/**
 * WebSocket 相关类型
 */

export type WsStatus = 'connecting' | 'open' | 'closed'

export interface PageInfo {
  id: string
  name: string
  path: string
  index?: number
}

export interface LogItem {
  id: number
  time: string
  raw: string
}
