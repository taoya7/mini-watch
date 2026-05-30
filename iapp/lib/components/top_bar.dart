import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../store/base_info_store.dart';
import '../styles/theme_scope.dart';

/// 顶部状态栏：OS 版本 + WiFi/蜂窝 + 电池 + 实时时钟 + 设置
/// 网络和电量直接读设备状态，不走 ws
class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  Timer? _clockTimer;
  Timer? _batteryPoll;
  DateTime _now = DateTime.now();

  final Battery _battery = Battery();
  int? _batteryLevel;
  BatteryState? _batteryState;
  StreamSubscription<BatteryState>? _batterySub;

  final Connectivity _connectivity = Connectivity();
  List<ConnectivityResult> _conn = const [];
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _initBattery();
    _initConnectivity();
  }

  Future<void> _initBattery() async {
    await _refreshBattery();
    _batterySub = _battery.onBatteryStateChanged.listen((s) async {
      if (!mounted) return;
      setState(() => _batteryState = s);
      _refreshBattery();
    });
    // 电量百分比变化不会主动触发事件，30s 轮询一下
    _batteryPoll = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshBattery(),
    );
  }

  Future<void> _refreshBattery() async {
    try {
      final lvl = await _battery.batteryLevel;
      final st = await _battery.batteryState;
      if (mounted) {
        setState(() {
          _batteryLevel = lvl;
          _batteryState = st;
        });
      }
    } catch (_) {}
  }

  Future<void> _initConnectivity() async {
    try {
      final c = await _connectivity.checkConnectivity();
      if (mounted) setState(() => _conn = c);
    } catch (_) {}
    _connSub = _connectivity.onConnectivityChanged.listen((c) {
      if (mounted) setState(() => _conn = c);
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _batteryPoll?.cancel();
    _batterySub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  String get _time {
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(_now.hour)}:${pad(_now.minute)}:${pad(_now.second)}';
  }

  ({IconData icon, String? label}) get _connDisplay {
    if (_conn.contains(ConnectivityResult.wifi)) {
      return (icon: Icons.wifi, label: null);
    }
    if (_conn.contains(ConnectivityResult.ethernet)) {
      return (icon: Icons.lan_outlined, label: null);
    }
    if (_conn.contains(ConnectivityResult.mobile)) {
      // Flutter 无法区分 3G/4G/5G，统一显示"蜂窝"
      return (icon: Icons.signal_cellular_alt, label: '4G');
    }
    if (_conn.contains(ConnectivityResult.vpn)) {
      return (icon: Icons.vpn_lock, label: null);
    }
    if (_conn.contains(ConnectivityResult.bluetooth)) {
      return (icon: Icons.bluetooth, label: null);
    }
    return (icon: Icons.signal_wifi_off, label: null);
  }

  IconData get _batteryIcon {
    if (_batteryState == BatteryState.charging) {
      return Icons.battery_charging_full;
    }
    final lvl = _batteryLevel ?? 0;
    if (lvl >= 90) return Icons.battery_full;
    if (lvl >= 70) return Icons.battery_6_bar;
    if (lvl >= 50) return Icons.battery_5_bar;
    if (lvl >= 30) return Icons.battery_3_bar;
    if (lvl >= 15) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  @override
  Widget build(BuildContext context) {
    final conn = _connDisplay;
    return ListenableBuilder(
      listenable: baseInfoStore,
      builder: (_, __) {
        final info = baseInfoStore.info;
        final leftLabel = info?.hostMemoryLabel ?? '';
        final osVersion = info?.osLabel ?? '';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左：主机名 · 内存
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    leftLabel,
                    style: TextStyle(
                      color: context.theme.textMain,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
              // 右：OS / 网络 / 电池 / 时钟 / 设置
              Row(mainAxisSize: MainAxisSize.min, children: [
              if (osVersion.isNotEmpty) ...[
                Text(
                  osVersion,
                  style: TextStyle(
                    color: context.theme.textSub,
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (conn.label != null) ...[
                Text(
                  conn.label!,
                  style: TextStyle(
                    color: context.theme.textSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 3),
              ],
              Icon(conn.icon, size: 12, color: context.theme.textSub),
              const SizedBox(width: 10),
              Icon(_batteryIcon, size: 14, color: context.theme.textSub),
              if (_batteryLevel != null) ...[
                const SizedBox(width: 2),
                Text(
                  '${_batteryLevel}%',
                  style: TextStyle(
                    color: context.theme.textSub,
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Text(
                _time,
                style: TextStyle(
                  color: context.theme.textMain,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/settings'),
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.settings_outlined,
                  size: 14,
                  color: context.theme.textSub,
                ),
              ),
              ]),
            ],
          ),
        );
      },
    );
  }
}
