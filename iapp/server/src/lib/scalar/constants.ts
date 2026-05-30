/**
 * OpenAPI Security Schemes Configuration
 */
export const securitySchemes = {
  ApiKeyAuth: {
    type: 'apiKey' as const,
    in: 'header' as const,
    name: 'X-API-Key',
    description: 'API Key Authentication',
  },
}
