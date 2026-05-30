<script setup lang="ts">
import { useWsStore } from '@client/store/ws'
import { Badge } from '@client/components/ui/badge'

const wsStore = useWsStore()
const { status, onlineCount } = storeToRefs(wsStore)
wsStore.init()

const dotClass = computed(() => {
  if (status.value === 'open') return 'bg-emerald-500'
  if (status.value === 'connecting') return 'bg-amber-500 animate-pulse'
  return 'bg-zinc-300'
})

const label = computed(() => {
  if (status.value === 'open') return '已连接'
  if (status.value === 'connecting') return '连接中…'
  return '已断开'
})
</script>

<template>
  <div class="rounded-xl border border-zinc-200 bg-white p-4 shadow-sm">
    <div class="mb-2 text-xs font-medium uppercase tracking-wide text-zinc-500">
      WS 连接
    </div>
    <div class="flex items-center gap-2">
      <span class="h-2.5 w-2.5 rounded-full" :class="dotClass" />
      <span class="text-sm font-semibold text-zinc-900">{{ label }}</span>
      <Badge class="ml-auto border-zinc-200 bg-zinc-50 text-zinc-600">
        在线 {{ onlineCount }}
      </Badge>
    </div>
  </div>
</template>
