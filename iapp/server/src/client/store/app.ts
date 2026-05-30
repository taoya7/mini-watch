import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAppStore = defineStore('app', () => {
  const title = ref('Hono App')

  return {
    title,
  }
})
