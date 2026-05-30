<script setup lang="ts">
import type { Component } from 'vue'
import { Slider } from '@client/components/ui/slider'

const props = withDefaults(defineProps<{
  /** 卡片标题 */
  label: string
  /** 服务端推来的真实值 */
  value: number
  /** 图标组件（lucide-vue-next） */
  icon?: Component
  /** 是否禁用（连接断开时） */
  disabled?: boolean
  min?: number
  max?: number
  step?: number
}>(), {
  min: 0,
  max: 100,
  step: 1,
})

const emit = defineEmits<{ commit: [value: number] }>()

// 本地 ref：拖动时即时显示，松手才回传
const local = ref<number[]>([props.value])
let dragging = false

watch(() => props.value, (v) => {
  if (!dragging) local.value = [v]
})

function onChange(v: number[] | undefined) {
  if (!v) return
  dragging = true
  local.value = v
}

function onCommit(v: number[] | undefined) {
  dragging = false
  if (!v) return
  emit('commit', v[0])
}
</script>

<template>
  <div class="flex flex-col items-center">
    <!-- 顶部标题 -->
    <div class="mb-2 flex items-center gap-1 text-[11px] font-medium uppercase tracking-wide text-zinc-500">
      <component :is="icon" v-if="icon" class="size-3.5" />
      <span>{{ label }}</span>
    </div>

    <!-- 纵向滑条 -->
    <div class="my-2 h-36">
      <Slider
        :model-value="local"
        :min="min"
        :max="max"
        :step="step"
        :disabled="disabled"
        orientation="vertical"
        @update:model-value="onChange"
        @value-commit="onCommit"
      />
    </div>

    <!-- 当前值 -->
    <span class="font-mono text-sm font-semibold tabular-nums text-zinc-900">
      {{ local[0] }}<span class="text-xs text-zinc-400">%</span>
    </span>
  </div>
</template>
