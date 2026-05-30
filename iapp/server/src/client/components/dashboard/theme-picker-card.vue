<script setup lang="ts">
import { useWsStore } from '@client/store/ws'
import { themes } from '@client/lib/themes'

const wsStore = useWsStore()
const { status, currentThemeId } = storeToRefs(wsStore)

function pickTheme(id: string) {
  wsStore.send({ type: 'theme_change', theme_id: id })
}
</script>

<template>
  <div class="rounded-xl border border-zinc-200 bg-white p-4 shadow-sm">
    <div class="mb-3 flex items-center justify-between">
      <span class="text-xs font-medium uppercase tracking-wide text-zinc-500">
        主题色
      </span>
      <span v-if="status !== 'open'" class="text-xs text-zinc-400">
        连接断开，操作不可用
      </span>
    </div>
    <div class="flex flex-wrap gap-2">
      <button
        v-for="t in themes"
        :key="t.id"
        :disabled="status !== 'open'"
        class="group flex items-center gap-2 rounded-lg border px-3 py-1.5 text-sm transition disabled:cursor-not-allowed disabled:opacity-50"
        :class="t.id === currentThemeId
          ? 'border-zinc-900 bg-zinc-900 text-white shadow'
          : 'border-zinc-200 bg-white text-zinc-700 hover:border-zinc-400'"
        @click="pickTheme(t.id)"
      >
        <span
          class="h-3.5 w-3.5 rounded-full ring-1 ring-black/10"
          :style="{ backgroundColor: t.accent }"
        />
        <span class="font-medium">{{ t.name }}</span>
      </button>
    </div>
  </div>
</template>
