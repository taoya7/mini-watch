/// 主机基础信息 — 与 server/src/lib/base-info.ts 对应
class BaseInfo {
  const BaseInfo({
    required this.hostname,
    required this.username,
    required this.platform,
    required this.arch,
    required this.osName,
    required this.osVersion,
    required this.model,
    required this.chip,
    required this.cpuCores,
    required this.memoryGB,
    required this.bootTime,
    required this.uptimeMs,
    required this.serverStartedAt,
  });

  final String hostname;
  final String username;
  final String platform;
  final String arch;
  final String osName;
  final String osVersion;
  final String? model;
  final String chip;
  final int cpuCores;
  final int memoryGB;
  final int bootTime;
  final int uptimeMs;
  final int serverStartedAt;

  factory BaseInfo.fromJson(Map<String, dynamic> j) => BaseInfo(
        hostname: j['hostname'] as String? ?? '',
        username: j['username'] as String? ?? '',
        platform: j['platform'] as String? ?? '',
        arch: j['arch'] as String? ?? '',
        osName: j['osName'] as String? ?? '',
        osVersion: j['osVersion'] as String? ?? '',
        model: j['model'] as String?,
        chip: j['chip'] as String? ?? '',
        cpuCores: (j['cpuCores'] as num?)?.toInt() ?? 0,
        memoryGB: (j['memoryGB'] as num?)?.toInt() ?? 0,
        bootTime: (j['bootTime'] as num?)?.toInt() ?? 0,
        uptimeMs: (j['uptimeMs'] as num?)?.toInt() ?? 0,
        serverStartedAt: (j['serverStartedAt'] as num?)?.toInt() ?? 0,
      );

  /// 设备名（hostname's MacBook Pro 风格）
  String get deviceLabel {
    final h = hostname.isEmpty ? 'My' : "$hostname's";
    final m = model ?? osName;
    return '$h $m';
  }

  /// 顶栏左侧：用户名 · 芯片
  String get userChipLabel {
    final u = username.isEmpty ? '?' : username;
    final c = chip.isEmpty ? '-' : chip;
    return '$u · $c';
  }

  /// 顶栏左侧：主机名 · 内存大小
  String get hostMemoryLabel {
    final h = hostname.isEmpty ? '?' : hostname;
    final m = memoryGB > 0 ? '$memoryGB GB' : '-';
    return '$h · $m';
  }

  /// 系统标签：macOS 26.4
  String get osLabel => '$osName $osVersion';

  /// 启动时间 → 距今 xx 天 xx 小时
  String get uptimeLabel {
    final totalH = uptimeMs ~/ 3600000;
    final d = totalH ~/ 24;
    final h = totalH % 24;
    if (d > 0) return '${d}d ${h}h';
    return '${h}h';
  }
}
