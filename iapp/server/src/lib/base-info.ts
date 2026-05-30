import { exec as execCb } from 'node:child_process'
import os from 'node:os'
import { promisify } from 'node:util'
import { storage } from './cache'
import { logger } from './logger'

const exec = promisify(execCb)
const log = logger.child('base-info')

export const KEY_BASE_INFO = 'system:base_info'

/** 主机基础信息 — 与 iapp/lib/types/base_info.dart 对应 */
export interface BaseInfo {
  hostname: string
  /** 当前 OS 登录用户名 */
  username: string
  platform: NodeJS.Platform
  arch: string
  osName: string
  osVersion: string
  model: string | null
  chip: string
  cpuCores: number
  memoryGB: number
  /** OS 启动时间戳（ms） */
  bootTime: number
  /** OS 已运行毫秒数（采集时刻） */
  uptimeMs: number
  /** 本服务启动时间戳（ms） */
  serverStartedAt: number
}

/** macOS 漂亮型号名：MacBookPro18,3 / Mac15,9 等 */
async function macModel(): Promise<string | null> {
  try {
    const { stdout } = await exec('sysctl -n hw.model')
    return stdout.trim() || null
  }
  catch { return null }
}

/** OS 显示名 */
function osName(p: NodeJS.Platform) {
  switch (p) {
    case 'darwin': return 'macOS'
    case 'win32': return 'Windows'
    case 'linux': return 'Linux'
    default: return p
  }
}

/** 从 Darwin release（如 23.5.0）粗略反推 macOS 主版本 */
function macReleaseToVersion(release: string): string {
  const major = Number.parseInt(release.split('.')[0] ?? '0', 10)
  // Darwin major - 9 = macOS major（macOS 10.4 = Darwin 8 起的偏移随版本变化）
  // 现行（macOS 14 Sonoma = Darwin 23 / macOS 15 = Darwin 24）：major - 9
  const macMajor = major >= 20 ? major - 9 : major
  const minorPatch = release.split('.').slice(1).join('.')
  return `${macMajor}.${minorPatch}`
}

// 模块级 promise：保证多次 collectBaseInfo() 只触发一次实际采集
let _collectPromise: Promise<BaseInfo> | null = null

/** 采集并写 cache（幂等：并发调用合并为同一个 Promise） */
export function collectBaseInfo(): Promise<BaseInfo> {
  if (_collectPromise) return _collectPromise
  _collectPromise = _doCollect()
  return _collectPromise
}

async function _doCollect(): Promise<BaseInfo> {
  const platform = os.platform()
  const release = os.release()
  const cpus = os.cpus()
  const uptimeMs = os.uptime() * 1000
  const now = Date.now()

  const info: BaseInfo = {
    hostname: os.hostname().replace(/\.local$/, ''),
    username: os.userInfo().username,
    platform,
    arch: os.arch(),
    osName: osName(platform),
    osVersion: platform === 'darwin' ? macReleaseToVersion(release) : release,
    model: platform === 'darwin' ? await macModel() : null,
    chip: cpus[0]?.model ?? 'unknown',
    cpuCores: cpus.length,
    memoryGB: Math.round(os.totalmem() / 1024 ** 3),
    bootTime: now - uptimeMs,
    uptimeMs,
    serverStartedAt: now,
  }

  await storage.setItem(KEY_BASE_INFO, info)
  log.info(`collected: ${info.hostname} · ${info.osName} ${info.osVersion} · ${info.memoryGB}GB`)
  return info
}

/** 取最新缓存值（实时刷新 uptimeMs）；首次调用会触发采集并等待 */
export async function getBaseInfo(): Promise<BaseInfo | null> {
  // 还没采集 / 正在采集 → 都等同一个 Promise 完成
  await collectBaseInfo()
  const cached = await storage.getItem<BaseInfo>(KEY_BASE_INFO)
  if (!cached) return null
  // bootTime 不变，uptimeMs 按当前时间重算，避免长跑时显示过期
  return {
    ...cached,
    uptimeMs: Date.now() - cached.bootTime,
  }
}
