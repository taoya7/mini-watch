import type { FC } from 'hono/jsx'
import type { AppBindings } from '@/lib/create-app'
import { Hono } from 'hono'
import { openAPIRouteHandler } from 'hono-openapi'

import { securitySchemes } from './constants'

interface ScalarSource {
  url: string
  title: string
}

const sources: ScalarSource[] = [
  {
    url: `/api/_docs/docs.json`,
    title: 'API',
  },
]

/**
 * Scalar 配置
 */
const scalarConfig = {
  theme: 'mars',
  hideSearch: true,
  showToolbar: 'never',
  hideDownloadButton: true,
  hideClientButton: true,
  forceDarkModeState: 'light',
  favicon: '/icon.svg',
  layout: 'modern',
  hideModels: true,
  defaultHttpClient: {
    targetKey: 'shell',
    clientKey: 'curl',
  },
  persistAuth: true,
  withDefaultFonts: true,
  authentication: {
    preferredSecurityScheme: 'ApiKeyAuth',
  },
  sources,
}

/**
 * Scalar 文档页面组件
 */
const ScalarPage: FC = () => {
  const initScript = `Scalar.createApiReference('#app', ${JSON.stringify(scalarConfig)})`

  return (
    <html lang="zh-CN">
      <head>
        <title>API 文档</title>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="stylesheet" href="/assets/scalar/style.min.css" />
      </head>
      <body>
        <div id="app" />
        <script src="/assets/scalar/standalone.min.js" />
        <script dangerouslySetInnerHTML={{ __html: initScript }} />
      </body>
    </html>
  )
}

/**
 * 设置 Scalar API 文档路由
 */
export function setupScalar(app: Hono<AppBindings>) {
  const docsApp = new Hono().basePath('/api/_docs')

  // Scalar 文档页面
  docsApp.get('/doc.html', c => c.html(<ScalarPage />))

  // OpenAPI JSON 文档
  docsApp.get('/docs.json', openAPIRouteHandler(app, {
    documentation: {
      info: {
        title: 'API',
        version: '1.0.0',
        description: 'API Documentation',
      },
      components: {
        securitySchemes,
      },
    },
  }))

  app.route('/', docsApp)
}
