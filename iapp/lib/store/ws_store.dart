import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

enum WsStatus { idle, connecting, connected, disconnected, error }

/// WebSocket 单例：连接、重连、心跳、消息回调
class WsStore extends ChangeNotifier {
  WsStore._();
  static final instance = WsStore._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _heartbeat;
  Timer? _reconnect;

  WsStatus _status = WsStatus.idle;
  WsStatus get status => _status;

  /// 最近一条收到的消息（JSON 解码后，失败时为原始字符串）
  Object? _lastMessage;
  Object? get lastMessage => _lastMessage;

  /// 业务侧订阅入口：每收到一条消息就触发
  final _listeners = <void Function(Object?)>{};
  void addMessageListener(void Function(Object?) cb) => _listeners.add(cb);
  void removeMessageListener(void Function(Object?) cb) =>
      _listeners.remove(cb);

  /// 主动连接（已连或正连返回 false）
  bool connect() {
    if (_status == WsStatus.connecting || _status == WsStatus.connected) {
      return false;
    }
    _setStatus(WsStatus.connecting);
    try {
      _channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl));
      _sub = _channel!.stream.listen(
        _onData,
        onDone: _onDone,
        onError: _onError,
        cancelOnError: false,
      );
      _setStatus(WsStatus.connected);
      _startHeartbeat();
      return true;
    } catch (e) {
      _setStatus(WsStatus.error);
      _scheduleReconnect();
      return false;
    }
  }

  /// 主动断开
  void disconnect() {
    _reconnect?.cancel();
    _reconnect = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _setStatus(WsStatus.idle);
  }

  /// 发送：Map/List 自动 JSON 编码，String 原样发
  void send(Object data) {
    if (_status != WsStatus.connected || _channel == null) return;
    final payload = data is String ? data : jsonEncode(data);
    _channel!.sink.add(payload);
  }

  // ─── 内部 ─────────────────────────────────────

  void _onData(dynamic raw) {
    Object? msg;
    try {
      msg = jsonDecode(raw as String);
    } catch (_) {
      msg = raw;
    }
    _lastMessage = msg;
    notifyListeners();
    for (final cb in _listeners) cb(msg);
  }

  void _onDone() {
    _setStatus(WsStatus.disconnected);
    _heartbeat?.cancel();
    _scheduleReconnect();
  }

  void _onError(Object _) {
    _setStatus(WsStatus.error);
    _heartbeat?.cancel();
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 25), (_) {
      send({'type': 'ping', 'ts': DateTime.now().millisecondsSinceEpoch});
    });
  }

  void _scheduleReconnect() {
    _reconnect?.cancel();
    _reconnect = Timer(const Duration(seconds: 3), connect);
  }

  void _setStatus(WsStatus s) {
    if (_status == s) return;
    _status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// 便捷访问
WsStore get wsStore => WsStore.instance;
