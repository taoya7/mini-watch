import path from 'node:path'

import { z } from 'zod'

export const configSchema = z.object({
  // 内置 - 计算属性
  isProduction: z.coerce.boolean().optional(),
  isDevelopment: z.coerce.boolean().optional(),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('production'),

  // 服务器配置
  PORT: z.coerce.number().min(1).max(65535).optional(),
  URL: z.string().optional(),

  // 日志配置
  LOG_LEVEL: z.enum(['error', 'warn', 'info', 'http', 'verbose', 'debug', 'silly']).default('debug'),
  LOG_DIR: z.string().default(path.resolve(process.cwd(), 'logs')),
  LOG_CONSOLE_ENABLED: z.coerce.boolean().default(true),
  LOG_FILE_ENABLED: z.coerce.boolean().default(false),
})

export type Config = Omit<z.infer<typeof configSchema>, 'isProduction' | 'isDevelopment'> & {
  isProduction: boolean
  isDevelopment: boolean
}
