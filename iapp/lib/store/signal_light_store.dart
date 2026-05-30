import 'package:flutter/foundation.dart';

/// 灯语聚合状态（来自服务端 ws）
enum SignalLightState {
  idle,        // 绿灯常亮：所有 session 空闲
  working,     // 三色循环：thinking / working / tool_done
  attention,   // 黄灯闪：permission / attention / done
  blocked,     // 红灯闪：blocked
}

class SignalLightStore extends ChangeNotifier {
  SignalLightStore._();
  static final instance = SignalLightStore._();

  SignalLightState _state = SignalLightState.idle;
  int _activeSessions = 0;
  String? _lastSignal;
  String? _lastSessionId;

  SignalLightState get state => _state;
  int get activeSessions => _activeSessions;
  String? get lastSignal => _lastSignal;
  String? get lastSessionId => _lastSessionId;

  void apply({
    required String aggregate,
    int activeSessions = 0,
    String? signal,
    String? sessionId,
  }) {
    final next = _parse(aggregate);
    final changed = next != _state
        || _activeSessions != activeSessions
        || _lastSignal != signal
        || _lastSessionId != sessionId;
    _state = next;
    _activeSessions = activeSessions;
    _lastSignal = signal;
    _lastSessionId = sessionId;
    if (changed) notifyListeners();
  }

  static SignalLightState _parse(String s) => switch (s) {
        'blocked' => SignalLightState.blocked,
        'attention' || 'permission' || 'done' => SignalLightState.attention,
        'working' || 'thinking' || 'tool_done' => SignalLightState.working,
        _ => SignalLightState.idle,
      };
}

SignalLightStore get signalLightStore => SignalLightStore.instance;
