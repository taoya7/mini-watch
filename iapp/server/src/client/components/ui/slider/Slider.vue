<script setup lang="ts">
import type { HTMLAttributes } from 'vue'
import {
  SliderRange,
  SliderRoot,
  type SliderRootEmits,
  type SliderRootProps,
  SliderThumb,
  SliderTrack,
  useForwardPropsEmits,
} from 'reka-ui'
import { cn } from 'src/client/lib/utils'

const props = defineProps<SliderRootProps & { class?: HTMLAttributes['class'] }>()
const emits = defineEmits<SliderRootEmits>()

const forwarded = useForwardPropsEmits(props, emits)
</script>

<template>
  <SliderRoot
    :class="cn(
      'relative flex w-full touch-none select-none items-center data-[orientation=vertical]:flex-col data-[orientation=vertical]:h-full data-[orientation=vertical]:w-auto',
      props.class,
    )"
    v-bind="forwarded"
  >
    <SliderTrack class="relative h-1.5 w-full grow overflow-hidden rounded-full bg-zinc-200 data-[orientation=vertical]:w-1.5">
      <SliderRange class="absolute h-full bg-zinc-900 data-[orientation=vertical]:w-full" />
    </SliderTrack>
    <SliderThumb
      v-for="(_, i) in (Array.isArray(modelValue) ? modelValue.length : 1)"
      :key="i"
      class="block h-4 w-4 rounded-full border border-zinc-200 bg-white shadow transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-zinc-300 disabled:pointer-events-none disabled:opacity-50"
    />
  </SliderRoot>
</template>
