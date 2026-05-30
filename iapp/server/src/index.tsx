import type { Hono } from 'hono'
import type { AppBindings } from '@/lib/create-app'

import { serve } from '@hono/node-server'
import { config } from '@/config'
import { collectBaseInfo } from '@/lib/base-info'
import { startMacExtrasStream } from '@/lib/mac-extras'
import { loadHistory } from '@/lib/system-stats'
import createApp from '@/lib/create-app'
import { logger } from '@/lib/logger'
import { setupScalar } from '@/lib/scalar'
import { setupSpaFallback, setupStatic } from '@/lib/static'
import health from './api/health'
import signalLight from './api/signal-light'
import { attachWebSocket } from './api/websocket'

// ============ 创建应用 ============
const app = createApp()

// 启动时异步采集主机信息进 cache + 加载历史 stats（fire-and-forget，避免顶层 await 导致 cjs 打包失败）
void collectBaseInfo()
void loadHistory()
// macmon 长连接流（macOS 专属，无 sudo 也行）
startMacExtrasStream()

// 定义路由
const routes: Hono<AppBindings>[] = [
  health,
  signalLight,
]

// API 路由
routes.forEach(route => {
  app.route('/', route)
})

// 挂 WebSocket（必须在 serve 之前注册路由，serve 之后调用 injectWebSocket）
const injectWebSocket = attachWebSocket(app)

// 设置静态资源
setupStatic(app)

// 设置 Scalar API 文档
setupScalar(app)

// SPA fallback (放在所有路由之后)
setupSpaFallback(app)

const port = config.PORT || (config.isDevelopment ? 3001 : 3000)
logger.info(`Server is running on http://localhost:${port}`)
logger.info(`API Docs: http://localhost:${port}/api/_docs/doc.html`)
logger.info(`WebSocket:  ws://localhost:${port}/api/ws`)

const server = serve({
  fetch: app.fetch,
  port,
})

// 把 ws 协议升级注入到底层 HTTP server
injectWebSocket(server)
