<script setup lang="ts">
import { useWsStore } from '@client/store/ws'
import { navTargets } from '@client/lib/nav'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@client/components/ui/select'

const wsStore = useWsStore()
const { status, currentPage } = storeToRefs(wsStore)

function onSelect(id: string) {
  wsStore.send({ type: 'goto_page', page_id: id })
}

const placeholder = computed(() => currentPage.value?.name ?? '选择目标页')
</script>

<template>
  <div class="rounded-xl border border-zinc-200 bg-white p-4 shadow-sm">
    <div class="mb-3 flex items-center justify-between">
      <span class="text-xs font-medium uppercase tracking-wide text-zinc-500">
        页面切换
      </span>
      <span v-if="status !== 'open'" class="text-xs text-zinc-400">
        连接断开，操作不可用
      </span>
    </div>
    <Select
      :model-value="currentPage?.id ?? undefined"
      :disabled="status !== 'open'"
      @update:model-value="(v) => typeof v === 'string' && onSelect(v)"
    >
      <SelectTrigger>
        <SelectValue :placeholder="placeholder" />
      </SelectTrigger>
      <SelectContent>
        <SelectItem v-for="p in navTargets" :key="p.id" :value="p.id">
          {{ p.name }}
        </SelectItem>
      </SelectContent>
    </Select>
  </div>
</template>
