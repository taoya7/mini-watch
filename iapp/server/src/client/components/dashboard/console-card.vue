<script setup lang="ts">
import { useConsoleStore } from '@client/store/console'

const consoleStore = useConsoleStore()
const { logs } = storeToRefs(consoleStore)
</script>

<template>
  <div class="rounded-xl border border-zinc-200 bg-zinc-950 p-4 shadow-sm">
    <div class="mb-2 flex items-center justify-between">
      <span class="text-xs font-medium uppercase tracking-wide text-zinc-400">
        控制台
      </span>
      <button class="text-xs text-zinc-400 hover:text-zinc-200" @click="consoleStore.clear">
        清空
      </button>
    </div>
    <div class="h-[60vh] overflow-y-auto font-mono text-xs leading-relaxed">
      <div v-if="!logs.length" class="text-zinc-500">
        等待消息…
      </div>
      <div
        v-for="item in logs"
        :key="item.id"
        class="flex gap-3 border-b border-zinc-800/50 py-1.5 last:border-0"
      >
        <span class="shrink-0 text-zinc-500">{{ item.time }}</span>
        <span class="break-all text-emerald-300">{{ item.raw }}</span>
      </div>
    </div>
  </div>
</template>
