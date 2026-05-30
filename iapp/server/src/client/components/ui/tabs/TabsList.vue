<script setup lang="ts">
import type { TabsListProps } from 'reka-ui'
import type { HTMLAttributes } from 'vue'
import { cn } from '@client/lib/utils'
import { TabsList } from 'reka-ui'

const props = defineProps<TabsListProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...rest } = props
  return rest
})
</script>

<template>
  <TabsList
    v-bind="delegatedProps"
    :class="cn(
      'inline-flex h-9 w-fit items-center justify-center rounded-lg bg-zinc-100 p-1 text-zinc-500',
      props.class,
    )"
  >
    <slot />
  </TabsList>
</template>
