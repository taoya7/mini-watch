<script setup lang="ts">
import { Button } from '@client/components/ui/button'

const stack = [
  { label: '后端', value: 'Hono' },
  { label: '前端', value: 'Vue 3 + Vite' },
  { label: 'UI', value: 'shadcn-vue' },
  { label: 'CSS', value: 'Tailwind CSS' },
]
</script>

<template>
  <div class="relative flex min-h-screen items-center justify-center overflow-hidden bg-zinc-50">
    <div class="pointer-events-none absolute inset-0">
      <div class="absolute -right-32 -top-32 h-96 w-96 rounded-full bg-sky-200/50 blur-3xl" />
      <div class="absolute -bottom-32 -left-32 h-96 w-96 rounded-full bg-violet-200/50 blur-3xl" />
    </div>

    <div class="relative z-10 w-[90%] max-w-[400px]">
      <div class="mb-10 text-center">
        <h1 class="mb-2 text-3xl font-bold tracking-tight text-zinc-900">
          关于
        </h1>
        <p class="text-sm text-zinc-500">
          Hono + Vue 3 全栈单体应用
        </p>
      </div>

      <div class="overflow-hidden rounded-xl border border-zinc-200 bg-white shadow-sm">
        <div
          v-for="(item, i) in stack"
          :key="item.label"
          class="flex items-center"
          :class="i < stack.length - 1 ? 'border-b border-zinc-100' : ''"
        >
          <div class="w-20 shrink-0 px-4 py-3 text-xs font-medium uppercase tracking-wider text-zinc-400">
            {{ item.label }}
          </div>
          <div class="px-4 py-3 text-sm text-zinc-700">
            {{ item.value }}
          </div>
        </div>
      </div>

      <div class="mt-8 text-center">
        <router-link to="/">
          <Button variant="ghost" size="sm">
            ← 返回首页
          </Button>
        </router-link>
      </div>
    </div>
  </div>
</template>
