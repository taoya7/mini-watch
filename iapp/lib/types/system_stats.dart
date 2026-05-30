import 'dart:math' as math;

/// 系统状态快照 — 与 server/src/lib/system-stats.ts 对应
class SystemStats {
  const SystemStats({
    required this.cpu,
    required this.gpu,
    required this.memory,
    required this.temp,
    required this.disk,
    required this.network,
    required this.fan,
  });

  final CpuStats cpu;
  final GpuStats gpu;
  final MemoryStats memory;
  final TempStats temp;
  final DiskStats disk;
  final NetworkStats network;
  final FanStats fan;

  factory SystemStats.fromJson(Map<String, dynamic> j) => SystemStats(
        cpu: CpuStats.fromJson(_map(j['cpu'])),
        gpu: GpuStats.fromJson(_map(j['gpu'])),
        memory: MemoryStats.fromJson(_map(j['memory'])),
        temp: TempStats.fromJson(_map(j['temp'])),
        disk: DiskStats.fromJson(_map(j['disk'])),
        network: NetworkStats.fromJson(_map(j['network'])),
        fan: FanStats.fromJson(_map(j['fan'])),
      );
}

Map<String, dynamic> _map(Object? v) =>
    v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
double? _dn(Object? v) => v is num ? v.toDouble() : null;
int _i(Object? v) => (v as num?)?.toInt() ?? 0;
int? _in(Object? v) => v is num ? v.toInt() : null;

class CpuStats {
  const CpuStats({
    required this.usage,
    required this.loadAvg,
    required this.cores,
    required this.tempC,
  });
  final double usage;
  final double loadAvg;
  final int cores;
  final double? tempC;
  factory CpuStats.fromJson(Map<String, dynamic> j) => CpuStats(
        usage: _d(j['usage']),
        loadAvg: _d(j['loadAvg']),
        cores: _i(j['cores']),
        tempC: _dn(j['tempC']),
      );
}

class GpuStats {
  const GpuStats({this.usage, this.tempC, this.cores, this.model});
  final double? usage;
  final double? tempC;
  final int? cores;
  final String? model;
  factory GpuStats.fromJson(Map<String, dynamic> j) => GpuStats(
        usage: _dn(j['usage']),
        tempC: _dn(j['tempC']),
        cores: _in(j['cores']),
        model: j['model'] as String?,
      );
}

class MemoryStats {
  const MemoryStats({
    required this.pressure,
    required this.usedGB,
    required this.totalGB,
    required this.swapUsedGB,
  });
  final double pressure;
  final double usedGB;
  final double totalGB;
  final double swapUsedGB;
  factory MemoryStats.fromJson(Map<String, dynamic> j) => MemoryStats(
        pressure: _d(j['pressure']),
        usedGB: _d(j['usedGB']),
        totalGB: _d(j['totalGB']),
        swapUsedGB: _d(j['swapUsedGB']),
      );
}

class TempStats {
  const TempStats({this.cpu, this.gpu, this.disk, this.ambient});
  final double? cpu;
  final double? gpu;
  final double? disk;
  final double? ambient;
  factory TempStats.fromJson(Map<String, dynamic> j) => TempStats(
        cpu: _dn(j['cpu']),
        gpu: _dn(j['gpu']),
        disk: _dn(j['disk']),
        ambient: _dn(j['ambient']),
      );
}

class DiskStats {
  const DiskStats({
    required this.totalGB,
    required this.usedGB,
    required this.availGB,
    required this.usedPct,
  });
  final double totalGB;
  final double usedGB;
  final double availGB;
  final double usedPct;
  factory DiskStats.fromJson(Map<String, dynamic> j) => DiskStats(
        totalGB: _d(j['totalGB']),
        usedGB: _d(j['usedGB']),
        availGB: _d(j['availGB']),
        usedPct: _d(j['usedPct']),
      );
}

class NetworkStats {
  const NetworkStats({
    required this.rxKBs,
    required this.txKBs,
    required this.iface,
  });
  final double rxKBs;
  final double txKBs;
  final String iface;
  factory NetworkStats.fromJson(Map<String, dynamic> j) => NetworkStats(
        rxKBs: _d(j['rxKBs']),
        txKBs: _d(j['txKBs']),
        iface: j['iface'] as String? ?? '',
      );
}

class FanStats {
  const FanStats({this.rpm, this.load});
  final int? rpm;
  final double? load;
  factory FanStats.fromJson(Map<String, dynamic> j) => FanStats(
        rpm: _in(j['rpm']),
        load: _dn(j['load']),
      );
}

// ─── 健康度评估 ───────────────────────────────────────────────────

/// 健康度计算：基于 CPU/GPU 使用率、内存压力、温度、磁盘的加权扣分
/// 总分 100；权重和 = 100；额外温度过热做单独扣分
extension SystemStatsHealth on SystemStats {
  /// 健康分 0..100
  double get healthScore {
    final cpuP = cpu.usage.clamp(0.0, 100.0) * 0.30;
    final gpuP = (gpu.usage ?? 0).clamp(0.0, 100.0) * 0.15;
    final memP = memory.pressure.clamp(0.0, 100.0) * 0.30;
    // 磁盘只有超过 70% 才开始扣（最多扣 15 分）
    final diskUsed = disk.usedPct.clamp(0.0, 100.0);
    final diskP = diskUsed > 70 ? (diskUsed - 70) * 0.5 : 0.0;
    // 温度超过 60°C 才扣，每超 1°C 扣 1 分，封顶 25 分
    final maxTemp = math.max(cpu.tempC ?? 0, gpu.tempC ?? 0);
    final tempP = maxTemp > 60 ? math.min(25.0, (maxTemp - 60)) : 0.0;
    final score = 100 - (cpuP + gpuP + memP + diskP + tempP);
    return score.clamp(0.0, 100.0);
  }

  /// 文字评级
  String get healthLabel {
    final s = healthScore;
    if (s >= 85) return '优秀';
    if (s >= 70) return '良好';
    if (s >= 50) return '一般';
    if (s >= 30) return '偏差';
    return '紧张';
  }

  /// 最紧迫的问题描述；无问题返回 null
  String? get healthIssue {
    if ((cpu.tempC ?? 0) >= 85) return 'CPU 高温';
    if ((gpu.tempC ?? 0) >= 85) return 'GPU 高温';
    if (memory.pressure >= 75) return '内存压力偏高';
    if (cpu.usage >= 85) return 'CPU 高负载';
    if ((gpu.usage ?? 0) >= 85) return 'GPU 高负载';
    if (disk.usedPct >= 90) return '磁盘空间紧张';
    return null;
  }
}

