<script setup lang="ts">
import type { TabsContentProps } from 'reka-ui'
import type { HTMLAttributes } from 'vue'
import { cn } from '@client/lib/utils'
import { TabsContent } from 'reka-ui'

const props = defineProps<TabsContentProps & { class?: HTMLAttributes['class'] }>()

const delegatedProps = computed(() => {
  const { class: _, ...rest } = props
  return rest
})
</script>

<template>
  <TabsContent
    v-bind="delegatedProps"
    :class="cn('flex-1 focus-visible:outline-none', props.class)"
  >
    <slot />
  </TabsContent>
</template>
