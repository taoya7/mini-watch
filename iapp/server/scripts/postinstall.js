#!/usr/bin/env node

import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)
const rootDir = path.resolve(__dirname, '..')

// 读取 package.json
const packageJsonPath = path.join(rootDir, 'package.json')
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf-8'))
const projectName = packageJson.name

console.log(`\n📦 正在配置项目: ${projectName}\n`)

// 检查并复制 .env 文件
const envPath = path.join(rootDir, '.env')
const envExamplePath = path.join(rootDir, '.env.example')

if (!fs.existsSync(envPath)) {
  if (fs.existsSync(envExamplePath)) {
    try {
      fs.copyFileSync(envExamplePath, envPath)
      console.log('✅ 已从 .env.example 创建 .env 文件')
    }
    catch (error) {
      console.error('❌ 创建 .env 文件失败:', error.message)
    }
  }
  else {
    console.warn('⚠️  未找到 .env.example 文件，跳过 .env 创建')
  }
}
else {
  console.log('ℹ️  .env 文件已存在，跳过创建')
}

console.log(`\n🎉 项目配置完成！\n`)
