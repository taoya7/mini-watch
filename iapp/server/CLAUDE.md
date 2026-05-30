# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 提供项目上下文指引。

## 命令

```bash
# 开发
pnpm dev              # 启动 Hono 后端，热重载 (tsx watch, 端口 3001)
pnpm dev:client       # 启动 Vite 前端开发服务器 (端口 3000, 代理 API 到 3001)
pnpm start            # 运行编译后的 JS (需先执行 pnpm build)

# 构建
pnpm build            # 编译 TypeScript → dist/ (tsc + tsc-alias)
pnpm build:client     # 构建 Vue 前端 → front-dist/
pnpm bundle           # build:client + esbuild 打包 → dist/bundle.cjs + dist/front-dist/

# 二进制打包 (pkg)
pnpm build:binary:mac-arm     # macOS ARM64
pnpm build:binary:mac-intel   # macOS x64
pnpm build:binary:linux       # Linux x64
pnpm build:binary:windows     # Windows x64
pnpm build:binary:all         # 全平台

# 代码检查
pnpm typecheck        # TypeScript 类型检查（后端 tsc + 前端 vue-tsc）
pnpm lint             # ESLint 检查
pnpm lint:fix         # ESLint 自动修复
```

## 架构

全栈项目：**Hono**（后端 API）+ **Vue 3**（前端 SPA），最终打包为单一二进制文件。

### 项目结构

```
src/
├── index.tsx              # 服务端入口，注册路由并启动 Hono 服务
├── config/                # 配置管理，使用 Zod 校验环境变量，通过 dotenv 加载 .env
├── lib/
│   ├── create-app.ts      # Hono 应用工厂，集成中间件（CORS、安全头）
│   ├── logger/            # Winston 日志，支持控制台/文件输出
│   ├── scalar/            # Scalar API 文档集成（OpenAPI）
│   └── static.ts          # 静态资源服务（Scalar 资源 + Vue SPA + fallback）
├── api/                   # API 路由处理器
└── client/                # Vue 3 前端（Vite 项目）
    ├── index.html         # Vite 入口 HTML
    ├── main.ts            # Vue 应用入口（pinia、router、tailwind css）
    ├── app.vue            # 根布局组件（<router-view />）
    ├── pages/             # 基于文件的自动路由（unplugin-vue-router）
    ├── router/            # Vue Router 实例，支持 HMR
    ├── store/             # Pinia 状态管理
    ├── types/             # 自动生成的类型声明（auto-imports.d.ts、components.d.ts）
    └── env.d.ts           # Vite/Vue 类型声明

scripts/
└── build.ts               # esbuild 打包配置 + 复制 front-dist 到 dist/
```

### 前端技术栈

- **Vue 3** + **Vue Router**（基于文件的自动路由，由 `unplugin-vue-router` 驱动）
- **Pinia** 状态管理
- **shadcn-vue** UI 组件（基于 Radix Vue，组件源码在 `src/client/components/ui/`，通过 `npx shadcn-vue add <component>` 添加）
- **Tailwind CSS v4**（通过 `@tailwindcss/vite` 插件集成）
- **VueUse** 组合式工具库
- **unplugin-auto-import** — `ref`、`computed`、`onMounted`、`useRoute`、`useFetch` 等 API 自动导入，无需手动 import

### 关键模式

**路径别名**：
- 后端：`@/` → `src/`（tsconfig.json）
- 前端：`@client/` → `src/client/`（vite.config.ts）

**路由注册**（后端）：路由是 Hono 实例，通过 `src/index.tsx` 中的 `routes` 数组注册：
```typescript
const routes: Hono<AppBindings>[] = [health]
routes.forEach(route => app.route('/', route))
```

**路由优先级**：API 路由 → Scalar 文档 → 静态资源 → SPA fallback（`*`）

**页面路由**（前端）：在 `src/client/pages/` 下创建 `.vue` 文件即可自动注册路由：
- `pages/index.vue` → `/`
- `pages/about.vue` → `/about`
- `pages/users/[id].vue` → `/users/:id`

**配置管理**：环境变量通过 `src/config/schema.ts` 中的 Zod schema 校验

**日志**：使用 `@/lib/logger` 中的 `logger` 或 `createLogger('ServiceName')`

### TypeScript 配置

两个 tsconfig 文件（通过 project references 关联）：
- `tsconfig.json` — 后端（Hono JSX：`jsx: "react-jsx"`，`jsxImportSource: "hono/jsx"`）
- `tsconfig.client.json` — 前端（Vue：`jsx: "preserve"`，无 jsxImportSource）

`src/client/` 目录在后端 tsconfig 中被排除，避免 JSX 配置冲突。

### 构建流程

```
pnpm build:client  →  Vite 构建 Vue SPA → front-dist/
pnpm bundle        →  build:client + esbuild 打包后端 → dist/bundle.cjs + 复制 front-dist → dist/front-dist/
pnpm build:binary  →  bundle + pkg 打包二进制（front-dist 作为 pkg assets 内嵌）
```

### 构建产物

- `pnpm build` → `dist/*.js`（ESM，用于 `pnpm start`）
- `pnpm build:client` → `front-dist/`（Vue SPA，资源在 `_assets/` 下）
- `pnpm bundle` → `dist/bundle.cjs` + `dist/front-dist/`（单一 CJS 文件，供 pkg 打包）

### 开发工作流

1. 终端 1：`pnpm dev` — Hono 后端运行在端口 3001
2. 终端 2：`pnpm dev:client` — Vite 前端运行在端口 3000（代理 `/api` 和 `/assets` 到 3001）
3. 浏览器打开 `http://localhost:3000`

## 代码风格

使用 @antfu/eslint-config，启用 Vue 支持：
- 单引号，无分号
- 2 空格缩进
- 文件名使用 kebab-case（包括 `.vue` 文件）
- 多行末尾逗号
