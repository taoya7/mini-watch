import { logger as baseLogger } from './winston'

/**
 * 创建一个带有 service 标识的子 logger
 */
export function createLogger(service: string) {
  return baseLogger.child(service)
}

/**
 * 日志级别类型
 */
export type LogLevel = 'error' | 'warn' | 'info' | 'http' | 'verbose' | 'debug' | 'silly'

/**
 * 日志元数据类型
 */
export interface LogMeta {
  [key: string]: any
}

export { logger } from './winston'
