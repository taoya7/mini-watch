/// 全局配置
class AppConfig {
  AppConfig._();

  /// HTTP API 基地址
  static const apiBaseUrl = 'https://mini-watch.t8s.ink/api';

  /// WebSocket 地址（由 apiBaseUrl 推导：https → wss，http → ws）
  static String get wsUrl {
    final base = apiBaseUrl
        .replaceFirst(RegExp(r'^https://'), 'wss://')
        .replaceFirst(RegExp(r'^http://'), 'ws://');
    return '$base/ws';
  }
}
