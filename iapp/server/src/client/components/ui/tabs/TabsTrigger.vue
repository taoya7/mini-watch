<script setup lang="ts">
import type { TabsTriggerProps } from 'reka-ui'
import type { HTMLAttributes } from 'vue'
import { cn } from '@client/lib/utils'
import { TabsTrigger, useForwardProps } from 'reka-ui'

const props = defineProps<TabsTriggerProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...rest } = props
  return rest
})

const forwarded = useForwardProps(delegatedProps)
</script>

<template>
  <TabsTrigger
    v-bind="forwarded"
    :class="cn(
      'inline-flex items-center justify-center whitespace-nowrap rounded-md px-3 py-1 text-sm font-medium transition-all',
      'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-zinc-400 disabled:pointer-events-none disabled:opacity-50',
      'data-[state=active]:bg-white data-[state=active]:text-zinc-900 data-[state=active]:shadow-sm',
      props.class,
    )"
  >
    <slot />
  </TabsTrigger>
</template>
