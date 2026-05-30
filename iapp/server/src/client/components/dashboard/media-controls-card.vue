<script setup lang="ts">
import { Sun, Volume2 } from 'lucide-vue-next'
import VerticalSlider from '@client/components/dashboard/vertical-slider.vue'
import { useWsStore } from '@client/store/ws'

const wsStore = useWsStore()
const { status, brightness, volume } = storeToRefs(wsStore)

function onBrightness(value: number) {
  wsStore.send({ type: 'brightness_change', value })
}

function onVolume(value: number) {
  wsStore.send({ type: 'volume_change', value })
}
</script>

<template>
  <div class="rounded-xl border border-zinc-200 bg-white p-3 shadow-sm">
    <span class="text-xs font-medium uppercase tracking-wide text-zinc-500">
      媒体控制
    </span>
    <div class="mt-2 flex items-start justify-around">
      <VerticalSlider
        label="屏幕亮度"
        :icon="Sun"
        :value="brightness"
        :min="1"
        :max="100"
        :disabled="status !== 'open'"
        @commit="onBrightness"
      />
      <div class="w-px self-stretch bg-zinc-100" />
      <VerticalSlider
        label="音量"
        :icon="Volume2"
        :value="volume"
        :min="0"
        :max="100"
        :disabled="status !== 'open'"
        @commit="onVolume"
      />
    </div>
  </div>
</template>
