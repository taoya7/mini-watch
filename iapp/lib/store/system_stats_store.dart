import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../types/system_stats.dart';

/// 系统状态 store：最新快照 + 各指标历史（给 sparkline / histogram 用）
class SystemStatsStore extends ChangeNotifier {
  SystemStatsStore._();
  static final instance = SystemStatsStore._();

  /// 历史保留点数（5s 间隔，30 点 ≈ 2.5 分钟）
  static const int historyLen = 30;

  SystemStats? _last;
  SystemStats? get last => _last;

  // 归一化到 0..1 的滚动数组
  final List<double> cpuUsage = [];
  final List<double> gpuUsage = [];
  final List<double> memPressure = [];
  final List<double> netRx = [];
  final List<double> netTx = [];

  void update(SystemStats s) {
    _last = s;
    _push(cpuUsage, s.cpu.usage / 100);
    _push(gpuUsage, (s.gpu.usage ?? 0) / 100);
    _push(memPressure, s.memory.pressure / 100);
    _push(netRx, _logNorm(s.network.rxKBs));
    _push(netTx, _logNorm(s.network.txKBs));
    notifyListeners();
  }

  /// 用服务端推过来的历史快照预填 sparkline buffer
  /// data 形如：[{ts, cpu, gpu, mem, rx, tx}, ...]
  void loadHistory(List<dynamic> data) {
    cpuUsage.clear();
    gpuUsage.clear();
    memPressure.clear();
    netRx.clear();
    netTx.clear();
    for (final item in data.take(historyLen)) {
      if (item is! Map) continue;
      final m = item.cast<String, dynamic>();
      _push(cpuUsage, ((m['cpu'] as num?) ?? 0).toDouble() / 100);
      _push(gpuUsage, ((m['gpu'] as num?) ?? 0).toDouble() / 100);
      _push(memPressure, ((m['mem'] as num?) ?? 0).toDouble() / 100);
      _push(netRx, _logNorm(((m['rx'] as num?) ?? 0).toDouble()));
      _push(netTx, _logNorm(((m['tx'] as num?) ?? 0).toDouble()));
    }
    notifyListeners();
  }

  void _push(List<double> buf, double v) {
    final c = v.isNaN ? 0.0 : v.clamp(0.0, 1.0).toDouble();
    buf.add(c);
    if (buf.length > historyLen) buf.removeAt(0);
  }

  /// 网络 KB/s 对数归一：1KB/s 起步，10MB/s 封顶
  double _logNorm(double kbs) {
    if (kbs <= 1) return 0;
    return (math.log(kbs) / math.log(10000)).clamp(0.0, 1.0);
  }
}

SystemStatsStore get systemStatsStore => SystemStatsStore.instance;
