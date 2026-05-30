/**
 * 基于 unstorage 的 KV 存储
 * https://unstorage.unjs.io/
 * https://unstorage.unjs.io/drivers
 */

import { createStorage } from 'unstorage'
import memoryDriver from 'unstorage/drivers/memory'
// import redisDriver from 'unstorage/drivers/redis'

// 创建 storage 实例
export const storage = createStorage({
  driver: memoryDriver(),
})
