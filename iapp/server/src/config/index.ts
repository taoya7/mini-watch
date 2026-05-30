import type { Config } from './schema'
import fs from 'node:fs'

import path from 'node:path'
import { parseArgs } from 'node:util'

import dotenv from 'dotenv'
import { configSchema } from './schema'

// 加载 .env 文件
const envPath = path.resolve(process.cwd(), '.env')
if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath, debug: false })
}

// 解析命令行参数，优先级高于环境变量（支持 --port 3001 / --port=3001 / -p 3001）
function parseCliArgs(): Record<string, string> {
  const overrides: Record<string, string> = {}
  try {
    const { values } = parseArgs({
      args: process.argv.slice(2),
      options: {
        port: { type: 'string', short: 'p' },
      },
      strict: false,
      allowPositionals: true,
    })
    if (values.port != null)
      overrides.PORT = String(values.port)
  } catch {
    // 忽略未知参数，避免二进制因多余 flag 退出
  }
  return overrides
}

function loadConfig(): Config {
  try {
    const parsed = configSchema.parse({
      ...process.env,
      ...parseCliArgs(),
    })

    // 添加计算属性
    const config = {
      ...parsed,
      isProduction: parsed.NODE_ENV === 'production',
      isDevelopment: parsed.NODE_ENV === 'development',
    }

    return config as Config
  } catch (error) {
    console.error('Configuration validation failed:', error)
    process.exit(1)
  }
}

export const config = loadConfig()
export type { Config } from './schema'
