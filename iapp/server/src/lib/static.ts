import type { Hono } from 'hono'
import type { AppBindings } from '@/lib/create-app'

import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs'
import path from 'node:path'

import { serveStatic } from '@hono/node-server/serve-static'
import { createLogger } from '@/lib/logger'

const logger = createLogger('Static')

const MIME_TYPES: Record<string, string> = {
  css: 'text/css',
  js: 'application/javascript',
  json: 'application/json',
  png: 'image/png',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  gif: 'image/gif',
  svg: 'image/svg+xml',
  ico: 'image/x-icon',
  woff: 'font/woff',
  woff2: 'font/woff2',
  ttf: 'font/ttf',
  eot: 'application/vnd.ms-fontobject',
  txt: 'text/plain',
  webp: 'image/webp',
  webmanifest: 'application/manifest+json',
  xml: 'application/xml',
}

/**
 * 获取 front-dist 目录的绝对路径
 */
function getFrontDistPath(): string {
  if (typeof __dirname !== 'undefined') {
    const pkgPath = path.resolve(__dirname, 'front-dist')
    if (existsSync(pkgPath)) {
      return pkgPath
    }
  }
  return path.resolve(process.cwd(), 'front-dist')
}

// ============ 启动时一次性读取 ============
const frontDistPath = getFrontDistPath()

// 读取 manifest.json（Vite 构建产物映射）
function loadManifest(): Record<string, any> | null {
  const manifestPath = path.join(frontDistPath, '.vite', 'manifest.json')
  if (!existsSync(manifestPath))
    return null
  return JSON.parse(readFileSync(manifestPath, 'utf-8'))
}

// 缓存 index.html 内容
function loadIndexHTML(): string | null {
  const indexPath = path.join(frontDistPath, 'index.html')
  if (!existsSync(indexPath))
    return null
  return readFileSync(indexPath, 'utf-8')
}

// 获取 public 文件（front-dist 根目录下的非 _assets、非 index.html 文件）
function getPublicFiles(): string[] {
  if (!existsSync(frontDistPath))
    return []
  return readdirSync(frontDistPath)
    .filter(f => {
      if (f.startsWith('.') || f.startsWith('_') || f === 'index.html')
        return false
      return statSync(path.join(frontDistPath, f)).isFile()
    })
    .map(f => `/${f}`)
}

const manifest = loadManifest()
const indexHTML = loadIndexHTML()
const publicFiles = getPublicFiles()

/**
 * 静态文件处理器
 */
function createStaticFileHandler() {
  return async (c: any) => {
    const filePath = path.join(frontDistPath, c.req.path)
    try {
      const content = readFileSync(filePath)
      const ext = filePath.split('.').pop()
      const contentType = MIME_TYPES[ext || ''] || 'application/octet-stream'
      return c.body(content, 200, {
        'Content-Type': contentType,
        'Cache-Control': 'public, max-age=31536000, immutable',
      })
    } catch {
      return c.notFound()
    }
  }
}

/**
 * 设置静态资源路由
 */
export function setupStatic(app: Hono<AppBindings>) {
  // Scalar 静态资源: src/assets -> /assets
  app.use('/assets/*', serveStatic({
    root: path.resolve(process.cwd(), 'src'),
    rewriteRequestPath: p => p,
  }))

  // 禁止访问 .vite 目录（manifest 等构建元数据）
  app.all('/.vite/*', c => c.text('Forbidden', 403))

  if (!manifest)
    return

  const handleStaticFile = createStaticFileHandler()

  // _assets（Vite 构建的 JS/CSS，基于 manifest）
  app.get('/_assets/*', handleStaticFile)

  // public 文件（icon.svg 等）
  for (const file of publicFiles) {
    app.get(file, handleStaticFile)
  }

  const assetCount = Object.keys(manifest).length
  logger.info(`front-dist: ${frontDistPath}`)
  logger.info(`Manifest: ${assetCount} entries`)
  logger.info(`Public: ${publicFiles.join(', ') || '(none)'}`)
}

/**
 * SPA fallback: 所有未匹配路由返回缓存的 index.html
 */
export function setupSpaFallback(app: Hono<AppBindings>) {
  app.get('*', async c => {
    if (indexHTML) {
      return c.html(indexHTML)
    }
    return c.text('Front-end not built. Run: pnpm build:client', 404)
  })
}
