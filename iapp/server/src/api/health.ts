import { describeRoute } from 'hono-openapi'
import { createRouter } from '@/lib/create-app'

const router = createRouter()

router.get(
  '/api/health',
  describeRoute({
    description: '健康检查接口，返回服务状态、时间戳和运行时间',
    tags: ['系统'],
    responses: {
      200: {
        description: '服务健康状态',
        content: {
          'application/json': {
            schema: {
              type: 'object',
              properties: {
                status: {
                  type: 'string',
                  example: 'ok',
                },
                timestamp: {
                  type: 'string',
                  example: '2025-11-11T12:34:56.789Z',
                },
                uptime: {
                  type: 'number',
                  example: 123.456,
                },
              },
            },
          },
        },
      },
    },
  }),
  c => {
    return c.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    })
  },
)

export default router
