import type { Logform } from 'winston'
import { format } from 'winston'

/**
 * 类似 Java 风格的 console 日志格式
 * 格式: [时间] [级别] [服务] - 消息
 */
export const consoleFormat: Logform.Format = format.combine(
  format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss',
  }),
  format.errors({ stack: true }),
  format.printf(info => {
    const {
      timestamp,
      level,
      message,
      service = 'App',
      stack,
      ...meta
    } = info

    // 颜色映射
    const colors: Record<string, string> = {
      error: '\x1B[31m', // 红色
      warn: '\x1B[33m', // 黄色
      info: '\x1B[32m', // 绿色
      http: '\x1B[36m', // 青色
      verbose: '\x1B[35m', // 紫色
      debug: '\x1B[34m', // 蓝色
      silly: '\x1B[37m', // 白色
    }
    const reset = '\x1B[0m'

    const color = colors[level] || reset
    const levelUpper = level.toUpperCase()

    // 基础日志格式
    let log = `[${timestamp}] ${color}[${levelUpper}]${reset} [${service}] - ${message}`

    // 添加额外的元数据
    if (Object.keys(meta).length > 0) {
      log += ` ${JSON.stringify(meta)}`
    }

    // 如果有错误栈，添加到下一行
    if (stack) {
      log += `\n${stack}`
    }

    return log
  }),
)

/**
 * JSON 格式用于文件存储
 */
export const fileFormat: Logform.Format = format.combine(
  format.timestamp({
    format: 'YYYY-MM-DD HH:mm:ss.SSS',
  }),
  format.errors({ stack: true }),
  format.json(),
)
