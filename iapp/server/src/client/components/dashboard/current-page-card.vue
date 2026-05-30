<script setup lang="ts">
import { useWsStore } from '@client/store/ws'

const wsStore = useWsStore()
const { currentPage } = storeToRefs(wsStore)
</script>

<template>
  <div class="rounded-xl border border-zinc-200 bg-white p-4 shadow-sm">
    <div class="mb-2 text-xs font-medium uppercase tracking-wide text-zinc-500">
      手机端当前页面
    </div>
    <div v-if="currentPage" class="space-y-0.5">
      <div class="text-sm font-semibold text-zinc-900">
        {{ currentPage.name }}
      </div>
      <div class="font-mono text-xs text-zinc-400">
        {{ currentPage.id }} · index {{ currentPage.index ?? '-' }}
      </div>
    </div>
    <div v-else class="text-sm text-zinc-400">
      暂无上报
    </div>
  </div>
</template>
