import { cpSync, existsSync } from 'node:fs'
import { resolve } from 'node:path'
import { build } from 'esbuild'

const srcDir = resolve(import.meta.dirname, '../src')

await build({
  entryPoints: ['src/index.tsx'],
  bundle: true,
  platform: 'node',
  format: 'cjs',
  outfile: 'dist/bundle.cjs',
  alias: {
    '@': srcDir,
  },
  define: {
    'process.env.NODE_ENV': '"production"',
  },
})

// 复制前端构建产物到 dist/front-dist
const frontDist = resolve(import.meta.dirname, '../front-dist')
const targetDir = resolve(import.meta.dirname, '../dist/front-dist')

if (existsSync(frontDist)) {
  cpSync(frontDist, targetDir, { recursive: true })
  console.log('Front-end assets copied to dist/front-dist/')
} else {
  console.warn('Warning: front-dist/ not found. Run pnpm build:client first.')
}

console.log('Build completed!')
