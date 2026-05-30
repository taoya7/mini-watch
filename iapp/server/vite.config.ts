import { resolve } from 'node:path'
import tailwindcss from '@tailwindcss/vite'
import vue from '@vitejs/plugin-vue'
import dayjs from 'dayjs'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { VueRouterAutoImports } from 'unplugin-vue-router'
import VueRouter from 'unplugin-vue-router/vite'
import { defineConfig } from 'vite'
import { createHtmlPlugin as viteHtmlPlugin } from 'vite-plugin-html'

export default defineConfig({
  root: 'src/client',
  publicDir: resolve(__dirname, 'public'),
  plugins: [
    VueRouter({
      routesFolder: 'src/client/pages',
      exclude: ['src/client/pages/**/components/*'],
    }),
    vue(),
    tailwindcss(),
    Components({
      directoryAsNamespace: true,
      dts: resolve(__dirname, 'src/client/types/components.d.ts'),
      dirs: ['src/components'],
    }),
    viteHtmlPlugin({
      minify: true,
    }),
    AutoImport({
      imports: [
        'vue',
        VueRouterAutoImports,
        '@vueuse/core',
        'pinia',
      ],
      dts: resolve(__dirname, 'src/client/types/auto-imports.d.ts'),
    }),
  ],
  define: {
    __BUILD_TIME__: JSON.stringify(dayjs().format('YYYY/MM/DD HH:mm')),
  },
  resolve: {
    alias: {
      '@client': resolve(__dirname, 'src/client'),
      // shadcn-vue CLI 生成的组件里直接用 'src/client/...'，给它一个别名指到项目根
      src: resolve(__dirname, 'src'),
    },
  },
  build: {
    outDir: resolve(__dirname, 'front-dist'),
    emptyOutDir: true,
    assetsDir: '_assets',
    manifest: true,
  },
  server: {
    host: '0.0.0.0',
    port: 3000,
    allowedHosts: ['test.t8s.ink', `mini-watch.t8s.ink`],
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        ws: true,
        changeOrigin: true,
      },
      '/assets': 'http://localhost:3001',
    },
  },
})
