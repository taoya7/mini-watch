import { mkdir, readFile, writeFile } from 'node:fs/promises'
import { existsSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import si from 'systeminformation'
import { logger } from './logger'
import { collectMacExtras } from './mac-extras'

const log = logger.child('system-stats')

/** 单次系统快照 — 与 iapp/lib/types/system_stats.dart 对应 */
export interface SystemStats {
  cpu: { usage: number, loadAvg: number, cores: number, tempC: number | null }
  gpu: { usage: number | null, tempC: number | null, cores: number | null, model: string | null }
  memory: { pressure: number, usedGB: number, totalGB: number, swapUsedGB: number }
  temp: { cpu: number | null, gpu: number | null, disk: number | null, ambient: number | null }
  disk: { totalGB: number, usedGB: number, availGB: number, usedPct: number }
  network: { rxKBs: number, txKBs: number, iface: string }
  fan: { rpm: number | null, load: number | null }
}

/** 历史点（精简后写盘 / 给前端画 chart 用） */
export interface HistoryPoint {
  ts: number
  cpu: number
  gpu: number | null
  mem: number
  rx: number
  tx: number
}

const HISTORY_MAX = 240 // 5s × 240 = 20 分钟
const HISTORY_FILE = resolve(process.cwd(), 'data/stats-history.json')
let history: HistoryPoint[] = []

// 节流写盘
let writeTimer: NodeJS.Timeout | null = null
function scheduleWrite() {
  if (writeTimer) return
  writeTimer = setTimeout(async () => {
    writeTimer = null
    try {
      await mkdir(dirname(HISTORY_FILE), { recursive: true })
      await writeFile(HISTORY_FILE, JSON.stringify(history))
    }
    catch (e) {
      log.warn(`persist history failed: ${String(e)}`)
    }
  }, 5_000)
  writeTimer.unref?.()
}

export async function loadHistory(): Promise<void> {
  try {
    if (!existsSync(HISTORY_FILE)) return
    const raw = await readFile(HISTORY_FILE, 'utf-8')
    const arr = JSON.parse(raw)
    if (Array.isArray(arr)) {
      history = arr.slice(-HISTORY_MAX)
      log.info(`history loaded: ${history.length} points`)
    }
  }
  catch (e) {
    log.warn(`history load failed: ${String(e)}`)
  }
}

export function getHistory(): HistoryPoint[] {
  return history
}

function pushHistory(s: SystemStats) {
  history.push({
    ts: Date.now(),
    cpu: s.cpu.usage,
    gpu: s.gpu.usage,
    mem: s.memory.pressure,
    rx: s.network.rxKBs,
    tx: s.network.txKBs,
  })
  if (history.length > HISTORY_MAX) history = history.slice(-HISTORY_MAX)
  scheduleWrite()
}

// ─── 采集 ─────────────────────────────────────
export async function collectSystemStats(): Promise<SystemStats> {
  const [load, mem, fsList, netList, temp, graphics] = await Promise.all([
    si.currentLoad(),
    si.mem(),
    si.fsSize(),
    si.networkStats(),
    si.cpuTemperature(),
    si.graphics().catch(() => null),
  ])
  // macmon 是流式后台进程，这里只取缓存
  const extras = collectMacExtras()

  // macOS APFS：/ 是只读系统卷，用户数据卷在 /System/Volumes/Data，才是真实容器大小
  const root = process.platform === 'darwin'
    ? (fsList.find(d => d.mount === '/System/Volumes/Data')
       ?? fsList.find(d => d.mount === '/')
       ?? fsList[0]
       ?? null)
    : (fsList.find(d => d.mount === '/') ?? fsList[0] ?? null)
  const net = netList.find(n => n.iface !== 'lo0' && n.iface !== 'lo') ?? netList[0]

  // 优先用系统给的 available，回退到 size - used
  const totalGB = root ? root.size / 1024 ** 3 : 0
  const availGB = root && typeof root.available === 'number'
    ? root.available / 1024 ** 3
    : totalGB - (root ? root.used / 1024 ** 3 : 0)
  const usedGB = Math.max(0, totalGB - availGB)

  const firstGpu = graphics?.controllers?.[0]
  // mac-extras 优先（sudo + powermetrics 才有），缺失退回 systeminformation
  const cpuTempC = extras.cpuTempC ?? (temp?.main != null ? round1(temp.main) : null)
  const gpuTempC = extras.gpuTempC
    ?? (firstGpu?.temperatureGpu != null ? round1(firstGpu.temperatureGpu) : null)
    ?? (temp?.chipset != null ? round1(temp.chipset) : null)
  const gpuUsage = extras.gpuUsage
    ?? (firstGpu?.utilizationGpu != null ? round1(firstGpu.utilizationGpu) : null)

  const stats: SystemStats = {
    cpu: {
      usage: round1(load.currentLoad ?? 0),
      loadAvg: round2(load.avgLoad ?? 0),
      cores: load.cpus?.length ?? 0,
      tempC: cpuTempC,
    },
    gpu: {
      usage: gpuUsage,
      tempC: gpuTempC,
      cores: firstGpu?.cores ?? null,
      model: firstGpu?.model ?? null,
    },
    memory: (() => {
      // macmon 给的 ram_usage 跟 Activity Monitor 一致（wired + active + compressed）
      // systeminformation 的 available 包含 cache，算出来偏低（21% 那种）
      const totalBytes = extras.ramTotalBytes ?? mem.total
      const usedBytes = extras.ramUsedBytes
        ?? Math.max(0, mem.total - (typeof mem.available === 'number'
          ? mem.available
          : (mem.free + (mem.buffcache ?? 0))))
      const swapUsedBytes = extras.swapUsedBytes ?? mem.swapused
      return {
        pressure: totalBytes > 0 ? round1((usedBytes / totalBytes) * 100) : 0,
        usedGB: round2(usedBytes / 1024 ** 3),
        totalGB: round2(totalBytes / 1024 ** 3),
        swapUsedGB: round2(swapUsedBytes / 1024 ** 3),
      }
    })(),
    temp: {
      cpu: cpuTempC,
      gpu: gpuTempC,
      disk: null,
      ambient: null,
    },
    disk: {
      totalGB: round2(totalGB),
      usedGB: round2(usedGB),
      availGB: round2(availGB),
      usedPct: totalGB > 0 ? round1((usedGB / totalGB) * 100) : 0,
    },
    network: {
      rxKBs: round1((net?.rx_sec ?? 0) / 1024),
      txKBs: round1((net?.tx_sec ?? 0) / 1024),
      iface: net?.iface ?? '-',
    },
    fan: {
      rpm: extras.fanRpm,
      load: null,
    },
  }
  return stats
}

function round1(n: number) { return Math.round(n * 10) / 10 }
function round2(n: number) { return Math.round(n * 100) / 100 }

// ─── 周期推送 ─────────────────────────────────────
let pumpTimer: NodeJS.Timeout | null = null

export function isPumpRunning(): boolean {
  return pumpTimer != null
}

/** 启动周期采集；should() 返回 false 时自动停 */
export function startStatsPump(
  intervalMs: number,
  push: (s: SystemStats) => void,
  should: () => boolean,
) {
  if (pumpTimer) return
  log.info(`pump start, interval=${intervalMs}ms`)
  pumpTimer = setInterval(async () => {
    if (!should()) {
      stopStatsPump()
      return
    }
    try {
      const stats = await collectSystemStats()
      pushHistory(stats)
      push(stats)
    }
    catch (e) {
      log.warn(`collect failed: ${String(e)}`)
    }
  }, intervalMs)
  pumpTimer.unref?.()
}

export function stopStatsPump() {
  if (pumpTimer) {
    clearInterval(pumpTimer)
    pumpTimer = null
    log.info('pump stop')
  }
}
