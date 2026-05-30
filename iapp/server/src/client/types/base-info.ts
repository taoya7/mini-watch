/**
 * 主机基础信息 — 与 server/src/lib/base-info.ts 对应
 */
export interface BaseInfo {
  hostname: string
  username: string
  platform: string
  arch: string
  osName: string
  osVersion: string
  model: string | null
  chip: string
  cpuCores: number
  memoryGB: number
  /** OS 启动时间戳 ms */
  bootTime: number
  /** OS 已运行 ms */
  uptimeMs: number
  /** 本服务启动时间戳 ms */
  serverStartedAt: number
}
