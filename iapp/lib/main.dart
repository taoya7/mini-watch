import 'package:flutter/material.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'pages/home_pager.dart';
import 'pages/settings_page.dart';
import 'store/base_info_store.dart';
import 'store/signal_light_store.dart';
import 'store/system_stats_store.dart';
import 'store/ws_store.dart';
import 'styles/theme_controller.dart';
import 'styles/theme_scope.dart';
import 'types/base_info.dart';
import 'types/system_stats.dart';

Future<void> main() async {
  // 等绑定就绪后读取持久化主题，避免首帧闪一下默认主题再切回来
  WidgetsFlutterBinding.ensureInitialized();
  await themeController.load();
  // 起一个 WebSocket 长连接（断线会自动重连）
  wsStore.connect();
  // PC 控制台远程下发主题指令
  wsStore.addMessageListener(_handleRemoteCommand);
  runApp(const MyApp());
}

/// 处理服务端下发的远程指令
void _handleRemoteCommand(Object? msg) {
  if (msg is! Map) return;
  switch (msg['type']) {
    case 'theme_change':
      final id = msg['theme_id'];
      if (id is String) themeController.setById(id);
      break;
    case 'base_info':
      final data = msg['data'];
      if (data is Map) {
        baseInfoStore.update(BaseInfo.fromJson(data.cast<String, dynamic>()));
      }
      break;
    case 'system_stats':
      final data = msg['data'];
      if (data is Map) {
        systemStatsStore.update(
            SystemStats.fromJson(data.cast<String, dynamic>()));
      }
      break;
    case 'stats_history':
      final data = msg['data'];
      if (data is List) systemStatsStore.loadHistory(data);
      break;
    case 'brightness_change':
      final v = msg['value'];
      if (v is num) {
        // 0..100 → 0.0..1.0；插件容忍越界但 clamp 保险
        final p = (v.toDouble() / 100).clamp(0.0, 1.0);
        ScreenBrightness.instance.setApplicationScreenBrightness(p);
      }
      break;
    case 'volume_change':
      final v = msg['value'];
      if (v is num) {
        // 0..100 → 0.0..1.0
        final p = (v.toDouble() / 100).clamp(0.0, 1.0);
        FlutterVolumeController.setVolume(p);
      }
      break;
    case 'signal_light':
      final agg = msg['aggregate'];
      if (agg is String) {
        signalLightStore.apply(
          aggregate: agg,
          activeSessions: (msg['active_sessions'] as num?)?.toInt() ?? 0,
          signal: msg['signal'] as String?,
          sessionId: msg['session_id'] as String?,
        );
      }
      break;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder 监听切换 → 重建 ThemeScope（InheritedWidget）
    // → 所有 context.theme 的 widget Element 标脏 → 即使是 const 也重建
    return ListenableBuilder(
      listenable: themeController,
      builder: (_, __) => ThemeScope(
        theme: themeController.current,
        child: MaterialApp(
          title: 'iapp',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(useMaterial3: true),
          initialRoute: '/',
          routes: {
            '/': (_) => const HomePager(),
            '/settings': (_) => const SettingsPage(),
          },
        ),
      ),
    );
  }
}
