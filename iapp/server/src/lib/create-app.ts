import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { secureHeaders } from 'hono/secure-headers'

/**
 * App Bindings - 定义 Hono 应用的上下文类型
 */
export interface AppBindings {
}
/**
 * 创建 Hono 路由实例
 */
export function createRouter() {
  return new Hono<AppBindings>({
    strict: false,
  })
}

/**
 * 创建并配置 Hono 应用
 */
export default function createApp() {
  const app = new Hono<AppBindings>()
  // ============ 安全中间件 ============
  app.use('*', secureHeaders())
  // ============ CORS 配置 ============
  app.use('*', cors({
    origin: [],
    credentials: true,
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
    allowHeaders: ['Content-Type', 'Authorization'],
    exposeHeaders: ['Content-Length'],
    maxAge: 600,
  }))
  return app
}
