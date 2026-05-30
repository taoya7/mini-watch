import { spawn, type ChildProcessByStdio } from 'node:child_process'
import { existsSync } from 'node:fs'
import type { Readable } from 'node:stream'
import { logger } from './logger'

const log = logger.child('mac-extras')

/**
 * macOS / Apple Silicon 补采：CPU/GPU 温度、GPU 利用率
 * 通过 macmon (https://github.com/vladkens/macmon) — sudoless，JSON 流式输出
 */
export interface MacExtras {
  gpuUsage: number | null
  cpuTempC: number | null
  gpuTempC: number | null
  fanRpm: number | null
  // macmon 给的内存数据更接近 Activity Monitor 的口径
  ramUsedBytes: number | null
  ramTotalBytes: number | null
  swapUsedBytes: number | null
  swapTotalBytes: number | null
}

const EMPTY: MacExtras = {
  gpuUsage: null,
  cpuTempC: null,
  gpuTempC: null,
  fanRpm: null,
  ramUsedBytes: null,
  ramTotalBytes: null,
  swapUsedBytes: null,
  swapTotalBytes: null,
}

// macmon 常见安装路径
const MACMON_CANDIDATES = [
  '/opt/homebrew/bin/macmon',
  '/usr/local/bin/macmon',
]

let macmonProc: ChildProcessByStdio<null, Readable, Readable> | null = null
let lastSnapshot: MacExtras = EMPTY
let restartTimer: NodeJS.Timeout | null = null

function findMacmon(): string | null {
  for (const p of MACMON_CANDIDATES) if (existsSync(p)) return p
  return null
}

/** 启动 macmon 长连接流；幂等 */
export function startMacExtrasStream() {
  if (process.platform !== 'darwin') return
  if (macmonProc) return
  const bin = findMacmon()
  if (!bin) {
    log.info('macmon not found, GPU temp/usage unavailable')
    return
  }
  log.info(`spawn ${bin} pipe -i 2000`)
  try {
    const proc = spawn(bin, ['pipe', '-i', '2000'], { stdio: ['ignore', 'pipe', 'pipe'] })
    macmonProc = proc

    let buf = ''
    proc.stdout.on('data', (chunk: Buffer) => {
      buf += chunk.toString('utf-8')
      let nl: number
      // eslint-disable-next-line no-cond-assign
      while ((nl = buf.indexOf('\n')) !== -1) {
        const line = buf.slice(0, nl).trim()
        buf = buf.slice(nl + 1)
        if (line) onLine(line)
      }
    })

    proc.stderr.on('data', (chunk: Buffer) => {
      log.warn(`macmon stderr: ${chunk.toString('utf-8').slice(0, 200)}`)
    })

    proc.on('exit', (code, signal) => {
      log.warn(`macmon exited code=${code} signal=${signal}`)
      macmonProc = null
      lastSnapshot = EMPTY
      scheduleRestart()
    })
  }
  catch (e) {
    log.warn(`spawn failed: ${String(e)}`)
    scheduleRestart()
    return
  }
}

function scheduleRestart() {
  if (restartTimer) return
  restartTimer = setTimeout(() => {
    restartTimer = null
    startMacExtrasStream()
  }, 5000)
  restartTimer.unref?.()
}

function onLine(raw: string) {
  try {
    const j = JSON.parse(raw)
    const cpuT = j?.temp?.cpu_temp_avg
    const gpuT = j?.temp?.gpu_temp_avg
    // gpu_usage = [freqMHz, fraction 0..1]
    const gpuU = Array.isArray(j?.gpu_usage) ? j.gpu_usage[1] : null
    const mem = j?.memory ?? {}
    // 用户自定义字段 fans_number：可能是 number / number[] / 嵌套对象
    const fanRpm = pickFanRpm(j?.fans_number)
    lastSnapshot = {
      cpuTempC: typeof cpuT === 'number' ? round1(cpuT) : null,
      gpuTempC: typeof gpuT === 'number' ? round1(gpuT) : null,
      gpuUsage: typeof gpuU === 'number' ? round1(gpuU * 100) : null,
      fanRpm,
      ramUsedBytes: typeof mem.ram_usage === 'number' ? mem.ram_usage : null,
      ramTotalBytes: typeof mem.ram_total === 'number' ? mem.ram_total : null,
      swapUsedBytes: typeof mem.swap_usage === 'number' ? mem.swap_usage : null,
      swapTotalBytes: typeof mem.swap_total === 'number' ? mem.swap_total : null,
    }
  }
  catch {}
}

/** fans_number 字段尽量宽容：number / [number] / [{rpm}] / {rpm|value|speed} */
function pickFanRpm(v: unknown): number | null {
  const ok = (n: unknown): n is number =>
    typeof n === 'number' && Number.isFinite(n)
  if (ok(v)) return Math.round(v)
  const fromObj = (x: unknown): number | null => {
    if (ok(x)) return x
    if (x && typeof x === 'object') {
      const o = x as Record<string, unknown>
      if (ok(o.rpm)) return o.rpm
      if (ok(o.value)) return o.value
      if (ok(o.speed)) return o.speed
    }
    return null
  }
  if (Array.isArray(v) && v.length > 0) {
    const nums = v.map(fromObj).filter((n): n is number => n != null)
    if (nums.length > 0) return Math.round(Math.max(...nums))
  }
  const single = fromObj(v)
  return single != null ? Math.round(single) : null
}

function round1(n: number) { return Math.round(n * 10) / 10 }

/** 返回最近一次的 macmon 快照（即时，无 await） */
export function collectMacExtras(): MacExtras {
  return lastSnapshot
}

export function stopMacExtrasStream() {
  if (restartTimer) { clearTimeout(restartTimer); restartTimer = null }
  if (macmonProc) {
    try { macmonProc.kill('SIGTERM') }
    catch {}
    macmonProc = null
  }
}

// 进程退出时清理
process.once('SIGINT', stopMacExtrasStream)
process.once('SIGTERM', stopMacExtrasStream)
process.once('exit', stopMacExtrasStream)
