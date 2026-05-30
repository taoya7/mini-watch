import type { NavTarget } from '@client/types/nav'

/** 可远程下发跳转的手机端页面 — 与 iapp/lib/routes/app_routes.dart 一致 */
export const navTargets: NavTarget[] = [
  { id: 'home', name: '系统报告' },
  { id: 'traffic_light', name: '红绿灯' },
  { id: 'agent', name: '智能体' },
]
