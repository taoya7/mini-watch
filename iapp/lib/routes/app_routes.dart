/// 手机端路由注册表 — 所有 page 在此声明
///
/// id: 与服务端通信用，stable kebab/snake case
/// name: UI 显示中文名
/// path: Navigator 路由名（用于 push/pop）
class AppRoute {
  const AppRoute({
    required this.id,
    required this.name,
    required this.path,
  });

  final String id;
  final String name;
  final String path;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
      };

  @override
  String toString() => 'AppRoute(id: $id, name: $name)';
}

/// 全部已声明的页面 — 改这里增减页面
class AppRoutes {
  AppRoutes._();

  // HomePager 的横向 PageView 页（按 index 顺序）
  static const home = AppRoute(
    id: 'home',
    name: '系统报告',
    path: '/',
  );
  static const trafficLight = AppRoute(
    id: 'traffic_light',
    name: '红绿灯',
    path: '/traffic-light',
  );
  static const agent = AppRoute(
    id: 'agent',
    name: '智能体',
    path: '/agent',
  );

  // Navigator 栈上的 modal 页
  static const settings = AppRoute(
    id: 'settings',
    name: '设置',
    path: '/settings',
  );

  /// PageView 顺序（HomePager 用）
  static const pagerPages = <AppRoute>[home, trafficLight, agent];

  /// 按 index 查
  static AppRoute byIndex(int i) =>
      pagerPages[i.clamp(0, pagerPages.length - 1)];

  /// 按 id 查
  static AppRoute? byId(String id) {
    for (final r in const [home, trafficLight, agent, settings]) {
      if (r.id == id) return r;
    }
    return null;
  }
}
