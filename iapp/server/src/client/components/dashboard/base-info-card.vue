<script setup lang="ts">
import { useWsStore } from '@client/store/ws'

const wsStore = useWsStore()
const { baseInfo } = storeToRefs(wsStore)

const refresh = () => wsStore.send({ type: 'getBaseInfo' })

const rows = computed(() => {
  const b = baseInfo.value
  if (!b) return []
  const totalH = Math.floor(b.uptimeMs / 3600_000)
  const d = Math.floor(totalH / 24)
  const h = totalH % 24
  const boot = new Date(b.bootTime)
  const bootStr = `${boot.getMonth() + 1}月${boot.getDate()}日 ${String(boot.getHours()).padStart(2, '0')}:${String(boot.getMinutes()).padStart(2, '0')}`
  return [
    { k: '用户', v: b.username },
    { k: '主机名', v: b.hostname },
    { k: '型号', v: b.model ?? '—' },
    { k: '芯片', v: `${b.chip} · ${b.cpuCores} 核` },
    { k: '内存', v: `${b.memoryGB} GB` },
    { k: '系统', v: `${b.osName} ${b.osVersion}` },
    { k: '架构', v: `${b.platform}/${b.arch}` },
    { k: '开机时间', v: bootStr },
    { k: '已运行', v: d > 0 ? `${d}d ${h}h` : `${h}h` },
  ]
})
</script>

<template>
  <div class="rounded-xl border border-zinc-200 bg-white p-4 shadow-sm">
    <div class="mb-3 flex items-center justify-between">
      <span class="text-xs font-medium uppercase tracking-wide text-zinc-500">
        主机信息
      </span>
      <button
        class="text-xs text-zinc-500 hover:text-zinc-900"
        @click="refresh"
      >
        刷新
      </button>
    </div>
    <div v-if="!baseInfo" class="text-sm text-zinc-400">
      等待 base_info…
    </div>
    <!-- 每个字段独立 cell，窄屏 2 列、平板 3 列、宽屏 4 列 -->
    <div
      v-else
      class="grid grid-cols-2 gap-x-4 gap-y-3 sm:grid-cols-3 lg:grid-cols-4"
    >
      <div v-for="row in rows" :key="row.k">
        <div class="text-[10px] uppercase tracking-wide text-zinc-400">
          {{ row.k }}
        </div>
        <div class="truncate text-sm font-semibold text-zinc-900">
          {{ row.v }}
        </div>
      </div>
    </div>
  </div>
</template>
