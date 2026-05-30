import { createStream } from 'rotating-file-stream'
import winston from 'winston'

import { config } from '@/config'

import { consoleFormat, fileFormat } from './formats'

const { LOG_LEVEL, LOG_DIR, LOG_CONSOLE_ENABLED, LOG_FILE_ENABLED } = config

// rotating-file-stream 配置
const ROTATION_CONFIG = {
  interval: '1d' as const,
  maxFiles: 14,
  maxSize: '20M' as const,
  compress: 'gzip' as const,
}

/**
 * Winston Logger 实例
 */
class Logger {
  private logger: winston.Logger

  constructor() {
    const transports: winston.transport[] = []

    // Console 传输器
    if (LOG_CONSOLE_ENABLED) {
      transports.push(
        new winston.transports.Console({
          format: consoleFormat,
        }),
      )
    }

    // 文件传输器
    if (LOG_FILE_ENABLED) {
      const applicationStream = createStream('application.log', {
        ...ROTATION_CONFIG,
        path: LOG_DIR,
      })

      transports.push(
        new winston.transports.Stream({
          stream: applicationStream,
          format: fileFormat,
          level: LOG_LEVEL,
        }),
      )

      const errorStream = createStream('error.log', {
        ...ROTATION_CONFIG,
        path: LOG_DIR,
      })

      transports.push(
        new winston.transports.Stream({
          stream: errorStream,
          format: fileFormat,
          level: 'error',
        }),
      )
    }

    this.logger = winston.createLogger({
      level: LOG_LEVEL,
      transports,
      exitOnError: false,
    })

    // 异常处理
    if (LOG_FILE_ENABLED) {
      const exceptionsStream = createStream('exceptions.log', {
        ...ROTATION_CONFIG,
        path: LOG_DIR,
      })

      const rejectionsStream = createStream('rejections.log', {
        ...ROTATION_CONFIG,
        path: LOG_DIR,
      })

      this.logger.exceptions.handle(
        new winston.transports.Stream({
          stream: exceptionsStream,
          format: fileFormat,
        }),
      )

      this.logger.rejections.handle(
        new winston.transports.Stream({
          stream: rejectionsStream,
          format: fileFormat,
        }),
      )
    } else {
      this.logger.exceptions.handle(new winston.transports.Console({ format: consoleFormat }))
      this.logger.rejections.handle(new winston.transports.Console({ format: consoleFormat }))
    }
  }

  child(service: string) {
    return this.logger.child({ service })
  }

  error(message: string, meta?: any) {
    this.logger.error(message, meta)
  }

  warn(message: string, meta?: any) {
    this.logger.warn(message, meta)
  }

  info(message: string, meta?: any) {
    this.logger.info(message, meta)
  }

  http(message: string, meta?: any) {
    this.logger.http(message, meta)
  }

  verbose(message: string, meta?: any) {
    this.logger.verbose(message, meta)
  }

  debug(message: string, meta?: any) {
    this.logger.debug(message, meta)
  }

  silly(message: string, meta?: any) {
    this.logger.silly(message, meta)
  }

  getInstance() {
    return this.logger
  }
}

export const logger = new Logger()
