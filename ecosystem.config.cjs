// PM2 部署配置（放项目根，与 Makefile 同级）
// 启动 esbuild 打出的 iapp/server/dist/bundle.cjs（端口 4600）
// 用法：make deploy-server（会先 pnpm bundle 再 pm2 startOrReload）
const path = require('node:path')

const distDir = path.join(__dirname, 'iapp/server/dist')

module.exports = {
  apps: [
    {
      name: 'mini-watch-server',
      script: path.join(distDir, 'bundle.cjs'),
      // cwd 设为 dist：data/ 持久化、front-dist 静态资源均相对此目录
      cwd: distDir,
      interpreter: 'node',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_restarts: 10,
      watch: false,
      env: {
        NODE_ENV: 'production',
        PORT: 4600,
      },
    },
  ],
}
