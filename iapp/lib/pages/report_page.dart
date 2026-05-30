import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../components/earth_sphere.dart';
import '../components/fan_shader.dart';
import '../components/top_bar.dart';
import '../components/ui/progress_bar.dart';
import '../store/base_info_store.dart';
import '../store/system_stats_store.dart';
import '../styles/theme_scope.dart';
import '../types/system_stats.dart';

/// 系统报告 — 暖琥珀调，直方图 / 波形图 / 健康度地球
class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final isLandscape = c.maxWidth > c.maxHeight;
            // 统一 12px 横向内边距：TopBar 与卡片左右严格对齐
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                children: [
                  const TopBar(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: isLandscape
                        ? _landscape(context)
                        : _portrait(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _landscape(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              const Expanded(child: _HealthCard()),
              const SizedBox(width: 10),
              Expanded(child: _cpu(context)),
              const SizedBox(width: 10),
              Expanded(child: _gpu(context)),
              const SizedBox(width: 10),
              Expanded(child: _mem(context)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _temp()),
              const SizedBox(width: 10),
              Expanded(child: _disk()),
              const SizedBox(width: 10),
              Expanded(child: _net()),
              const SizedBox(width: 10),
              Expanded(child: _fan()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _portrait(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 130, child: _HealthCard()),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            // 偏扁的比例：让 7 张卡 + 健康卡能在 4 行内放下
            childAspectRatio: 1.3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _cpu(context),
              _gpu(context),
              _mem(context),
              _temp(),
              _disk(),
              _net(),
              _fan(),
            ],
          ),
        ),
      ],
    );
  }

  // 卡片实例：全部绑 systemStatsStore，无数据时显示占位
  Widget _cpu(BuildContext context) => ListenableBuilder(
        listenable: systemStatsStore,
        builder: (_, __) {
          final cpu = systemStatsStore.last?.cpu;
          // 直方图最多 12 根（按 12 核一一对应）；取最近 12 个采样点
          final buf = systemStatsStore.cpuUsage;
          final tail = buf.length <= 12
              ? buf
              : buf.sublist(buf.length - 12);
          return _ChartCard(
            label: 'CPU',
            icon: LucideIcons.cpu,
            tag: cpu?.tempC != null
                ? '${cpu!.tempC!.toStringAsFixed(0)}°C'
                : '—',
            primary: cpu?.usage.toStringAsFixed(1) ?? '0.0',
            unit: '%',
            sub: cpu != null
                ? '负载 ${cpu.loadAvg.toStringAsFixed(1)} / ${cpu.cores} 核'
                : '',
            chart: _ChartType.histogram,
            data: tail.isEmpty ? const [0.0] : List.of(tail),
            accent: context.theme.accent,
          );
        },
      );

  Widget _gpu(BuildContext context) => ListenableBuilder(
        listenable: systemStatsStore,
        builder: (_, __) {
          final gpu = systemStatsStore.last?.gpu;
          return _ChartCard(
            label: 'GPU',
            icon: LucideIcons.microchip,
            tag: gpu?.tempC != null
                ? '${gpu!.tempC!.toStringAsFixed(0)}°C'
                : '—',
            primary: gpu?.usage?.toStringAsFixed(1) ?? '—',
            unit: '%',
            sub: gpu?.cores != null
                ? '${gpu!.cores} GPU 核'
                : gpu?.model ?? '',
            chart: _ChartType.sparkline,
            data: systemStatsStore.gpuUsage.isEmpty
                ? const [0.0]
                : List.of(systemStatsStore.gpuUsage),
            accent: context.theme.accent,
          );
        },
      );

  Widget _mem(BuildContext context) => ListenableBuilder(
        listenable: systemStatsStore,
        builder: (_, __) {
          final m = systemStatsStore.last?.memory;
          final danger = (m?.pressure ?? 0) >= 70;
          return _ChartCard(
            label: '内存',
            icon: LucideIcons.memoryStick,
            tag: m != null ? '压力 ${m.pressure.toStringAsFixed(0)}%' : '—',
            primary: m?.pressure.toStringAsFixed(0) ?? '0',
            unit: '%',
            sub: m != null
                ? '${m.usedGB.toStringAsFixed(2)} GB · 交换 ${m.swapUsedGB.toStringAsFixed(1)} GB'
                : '',
            chart: _ChartType.sparkline,
            data: systemStatsStore.memPressure.isEmpty
                ? const [0.0]
                : List.of(systemStatsStore.memPressure),
            accent: danger ? context.theme.danger : context.theme.accent,
            tagDanger: danger,
          );
        },
      );

  Widget _temp() => const _TempCard();
  Widget _disk() => const _DiskCard();
  Widget _net() => const _NetworkCard();
  Widget _fan() => const _FanCard();
}

// ─── 卡片壳 ───────────────────────────────────────────────────────────

class _Shell extends StatelessWidget {
  const _Shell({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.theme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _CardHead extends StatelessWidget {
  const _CardHead({
    required this.label,
    this.icon,
    this.tag,
    this.tagDanger = false,
    this.leadingDot,
  });

  final String label;
  final IconData? icon;
  final String? tag;
  final bool tagDanger;
  final Color? leadingDot;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: context.theme.accent),
          const SizedBox(width: 5),
        ],
        if (leadingDot != null) ...[
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: leadingDot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            color: context.theme.textSub,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
        const Spacer(),
        if (tag != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: tagDanger
                  ? const Color(0x33E56B4C)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              tag!,
              style: TextStyle(
                color: tagDanger ? context.theme.danger : context.theme.textSub,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }
}

// ─── 健康度卡（含太阳球） ────────────────────────────────────────────

class _HealthCard extends StatelessWidget {
  const _HealthCard();

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Stack(
        children: [
          // 右侧蓝色地球（GLSL shader）
          const Positioned(
            right: -10,
            top: -8,
            width: 96,
            height: 96,
            child: EarthSphere(),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.heartPulse,
                      size: 12, color: context.theme.accent),
                  const SizedBox(width: 5),
                  Text(
                    '健康度',
                    style: TextStyle(
                      color: context.theme.textSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 健康度数字 + 文字评级 + 问题描述：全部从 systemStatsStore 计算
              ListenableBuilder(
                listenable: systemStatsStore,
                builder: (_, __) {
                  final s = systemStatsStore.last;
                  final score = s?.healthScore;
                  final label = s?.healthLabel ?? '...';
                  final issue = s?.healthIssue;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: TextSpan(
                            text: score != null
                                ? score.toStringAsFixed(0)
                                : '--',
                            style: TextStyle(
                              color: context.theme.textMain,
                              fontSize: 44,
                              fontWeight: FontWeight.w700,
                              height: 1,
                              letterSpacing: -2,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                            children: [
                              TextSpan(
                                text: ' $label',
                                style: TextStyle(
                                  color: context.theme.textSub,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        issue ?? '系统正常',
                        style: TextStyle(
                          color: issue != null
                              ? context.theme.danger
                              : context.theme.textSub,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              // 运行时长从 base_info 实时读
              ListenableBuilder(
                listenable: baseInfoStore,
                builder: (_, __) {
                  final info = baseInfoStore.info;
                  if (info == null) {
                    return Text(
                      '已运行 -',
                      style: TextStyle(
                          color: context.theme.textDim, fontSize: 10),
                    );
                  }
                  final boot = DateTime.fromMillisecondsSinceEpoch(
                      info.bootTime);
                  final since = '${boot.month}月${boot.day}日';
                  return Text(
                    '已运行 ${info.uptimeLabel}  ·  自 $since',
                    style: TextStyle(
                        color: context.theme.textDim, fontSize: 10),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 通用图表卡（直方图 / 波形） ──────────────────────────────────────

enum _ChartType { histogram, sparkline }

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.label,
    required this.primary,
    required this.unit,
    required this.sub,
    required this.chart,
    required this.data,
    required this.accent,
    this.tag,
    this.tagDanger = false,
    this.icon,
  });

  final String label;
  final String? tag;
  final bool tagDanger;
  final String primary;
  final String unit;
  final String sub;
  final _ChartType chart;
  final List<double> data;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHead(label: label, icon: icon, tag: tag, tagDanger: tagDanger),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                text: primary,
                style: TextStyle(
                  color: context.theme.textMain,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: -1,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
                children: [
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      color: context.theme.textDim,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: chart == _ChartType.histogram
                  ? _HistogramPainter(values: data, color: accent)
                  : _SparklinePainter(values: data, color: accent),
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.theme.textSub, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  _HistogramPainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const gap = 3.0;
    final w = (size.width - gap * (values.length - 1)) / values.length;
    final base = Paint()..color = color.withValues(alpha: 0.15);
    final bar = Paint()..color = color;
    for (var i = 0; i < values.length; i++) {
      final x = i * (w + gap);
      final h = size.height * values[i].clamp(0.05, 1.0);
      // 背景柱
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, w, size.height),
          const Radius.circular(2),
        ),
        base,
      );
      // 实际柱
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, w, h),
          const Radius.circular(2),
        ),
        bar,
      );
    }
  }

  @override
  bool shouldRepaint(_HistogramPainter old) => old.values != values;
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});
  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final path = Path();
    final fillPath = Path();
    final stepX = size.width / (values.length - 1);
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - size.height * values[i].clamp(0.0, 1.0);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // 平滑曲线
        final px = (i - 1) * stepX;
        final py =
            size.height - size.height * values[i - 1].clamp(0.0, 1.0);
        final mx = (px + x) / 2;
        path.cubicTo(mx, py, mx, y, x, y);
        fillPath.cubicTo(mx, py, mx, y, x, y);
      }
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..close();
    // 渐变填充
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    // 描边
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.values != values;
}

// ─── 温度卡 ───────────────────────────────────────────────────────────

class _TempCard extends StatelessWidget {
  const _TempCard();

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: ListenableBuilder(
        listenable: systemStatsStore,
        builder: (_, __) {
          final t = systemStatsStore.last?.temp;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHead(label: '温度', icon: LucideIcons.thermometer),
              const SizedBox(height: 8),
              _row(context, 'CPU', t?.cpu),
              const SizedBox(height: 10),
              _row(context, 'GPU', t?.gpu),
              const Spacer(),
            ],
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, String label, double? v) {
    final hasV = v != null;
    final p = hasV ? (v / 100).clamp(0.0, 1.0) : 0.0;
    // 进度条用主题色；温度过高才改用 danger 提示
    final c = !hasV
        ? context.theme.textDim
        : v >= 80
            ? context.theme.danger
            : context.theme.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                    color: context.theme.textSub, fontSize: 11)),
            const Spacer(),
            Text(hasV ? '${v.toStringAsFixed(0)} °C' : '— °C',
                style: TextStyle(
                  color: context.theme.textMain,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                )),
          ],
        ),
        const SizedBox(height: 6),
        ProgressBar(value: p, color: c),
      ],
    );
  }
}

// ─── 磁盘卡 ───────────────────────────────────────────────────────────

class _DiskCard extends StatelessWidget {
  const _DiskCard();

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: ListenableBuilder(
        listenable: systemStatsStore,
        builder: (_, __) {
          final d = systemStatsStore.last?.disk;
          final totalTB = (d?.totalGB ?? 0) / 1024;
          final usedTB = (d?.usedGB ?? 0) / 1024;
          final availGB = d?.availGB ?? 0;
          final p = d != null && d.totalGB > 0 ? d.usedGB / d.totalGB : 0.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHead(
                label: '磁盘',
                icon: LucideIcons.hardDrive,
                tag: d != null ? '${totalTB.toStringAsFixed(2)} TB' : '—',
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    text: availGB.toStringAsFixed(0),
                    style: TextStyle(
                      color: context.theme.textMain,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    children: [
                      TextSpan(
                        text: ' GB 可用',
                        style: TextStyle(
                          color: context.theme.textDim,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              ProgressBar(value: p, color: context.theme.accent),
              const SizedBox(height: 6),
              Text(
                d != null
                    ? '已用 ${usedTB.toStringAsFixed(2)} TB  ·  ${(p * 100).toStringAsFixed(0)}%'
                    : '',
                style: TextStyle(color: context.theme.textSub, fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── 网络卡 ───────────────────────────────────────────────────────────

class _NetworkCard extends StatelessWidget {
  const _NetworkCard();

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: ListenableBuilder(
        listenable: systemStatsStore,
        builder: (_, __) {
          final n = systemStatsStore.last?.network;
          final hist = systemStatsStore.netRx.isEmpty
              ? const [0.0]
              : List.of(systemStatsStore.netRx);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHead(
                label: '网络',
                icon: LucideIcons.wifi,
                tag: n?.iface ?? '—',
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    text: (n?.rxKBs ?? 0).toStringAsFixed(1),
                    style: TextStyle(
                      color: context.theme.textMain,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: -1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    children: [
                      TextSpan(
                        text: ' KB/s',
                        style: TextStyle(
                          color: context.theme.textDim,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _SparklinePainter(
                      values: hist, color: context.theme.accent),
                ),
              ),
              Text(
                n != null
                    ? '↑ ${n.txKBs.toStringAsFixed(1)} KB/s'
                    : '',
                style: TextStyle(color: context.theme.textSub, fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── 风扇卡 ───────────────────────────────────────────────────────────

/// 只读卡片：macOS 自动调速，不开放用户切换模式
class _FanCard extends StatelessWidget {
  const _FanCard();

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: Stack(
        children: [
          // 右上角着色器风扇水印
          Positioned(
            right: -16,
            top: -16,
            width: 56,
            height: 56,
            child: IgnorePointer(
              child: FanShader(
                color: context.theme.accent.withValues(alpha: 0.16),
                speed: 1.0,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: systemStatsStore,
            builder: (_, __) {
              final fan = systemStatsStore.last?.fan;
              final rpm = fan?.rpm;
              final load = fan?.load;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHead(
                    label: '风扇',
                    icon: LucideIcons.fan,
                    tag: load != null
                        ? '负载 ${load.toStringAsFixed(0)}%'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        text: rpm?.toString() ?? '—',
                        style: TextStyle(
                          color: context.theme.textMain,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          letterSpacing: -1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        children: [
                          TextSpan(
                            text: ' RPM',
                            style: TextStyle(
                              color: context.theme.textDim,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: context.theme.ok,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '自动',
                        style: TextStyle(
                          color: context.theme.textMain,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'macOS 接管调速',
                    style:
                        TextStyle(color: context.theme.textSub, fontSize: 10),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
