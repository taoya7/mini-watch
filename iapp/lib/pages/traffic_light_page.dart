import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../components/aura_background.dart';
import '../components/breathing_container.dart';
import '../components/light_shader.dart';
import '../store/signal_light_store.dart';
import '../styles/theme_scope.dart';

/// 红绿灯页：3 盏 GLSL 灯横向排布
/// 受 SignalLightStore 控制（来自服务端 Claude hook 上报）
///
/// 灯语：
///   idle      → 绿灯常亮
///   working   → 黄灯慢闪呼吸
///   attention → 三灯全灭（仅右下角提示"需要关注"）
///   blocked   → 红灯快闪
class TrafficLightPage extends StatefulWidget {
  const TrafficLightPage({super.key});

  @override
  State<TrafficLightPage> createState() => _TrafficLightPageState();
}

class _TrafficLightPageState extends State<TrafficLightPage>
    with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFE83A2A);
  static const _yellow = Color(0xFFFFB300);
  static const _green = Color(0xFF3CC55B);

  // 0..1 循环的相位驱动器（呼吸 / 闪烁都从它取）
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// 慢闪呼吸：正弦在 0.15..1.0 之间往返（约 1.2s 一个完整呼吸）
  double get _breath {
    final s = (math.sin(_ctrl.value * 2 * math.pi) + 1) / 2; // 0..1
    return 0.15 + s * 0.85;
  }

  /// 快闪：约 0.5s 亮灭一次（亮 1.0 / 灭 0.1）
  double get _flash {
    return (_ctrl.value * 4) % 1 < 0.5 ? 1.0 : 0.1;
  }

  /// 返回每盏灯的亮度（0..1）
  ({double red, double yellow, double green}) _intensities(
      SignalLightState s) {
    return switch (s) {
      SignalLightState.idle => (red: 0, yellow: 0, green: 1.0),
      SignalLightState.working => (red: 0, yellow: _breath, green: 0),
      SignalLightState.attention => (red: 0, yellow: 0, green: 0),
      SignalLightState.blocked => (red: _flash, yellow: 0, green: 0),
    };
  }

  /// 当前状态对应的主色（背景 / 状态条共用）
  Color _stateColor(SignalLightState s) => switch (s) {
        SignalLightState.idle => _green,
        SignalLightState.working => _yellow,
        SignalLightState.attention => _yellow,
        SignalLightState.blocked => _red,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.bg,
      body: Stack(
        children: [
          // 背景色跟随当前灯态
          Positioned.fill(
            child: ListenableBuilder(
              listenable: signalLightStore,
              builder: (_, __) => AuraBackground(
                color: _stateColor(signalLightStore.state),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, c) {
                final isLandscape = c.maxWidth > c.maxHeight;
            // 竖屏窄，灯小一点；横屏宽，灯大一点
            final lightSize = isLandscape ? 96.0 : 64.0;
            final gap = isLandscape ? 24.0 : 16.0;
            final padH = isLandscape ? 36.0 : 24.0;
            final padV = isLandscape ? 28.0 : 20.0;
            return ListenableBuilder(
              listenable: signalLightStore,
              builder: (_, __) {
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    final s = signalLightStore.state;
                    final lit = _intensities(s);
                    return Stack(
                      children: [
                        // 灯居中
                        Center(
                          child: BreathingContainer(
                            // 仅「运行中」给外壳呼吸边框，颜色跟随灯态
                            active: s == SignalLightState.working,
                            color: _stateColor(s),
                            borderRadius: BorderRadius.circular(60),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: padH, vertical: padV),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111111),
                                borderRadius: BorderRadius.circular(60),
                                border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.06)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _light(_red, lit.red, lightSize),
                                  SizedBox(width: gap),
                                  _light(_yellow, lit.yellow, lightSize),
                                  SizedBox(width: gap),
                                  _light(_green, lit.green, lightSize),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // 状态信息固定右下角
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _statusBar(context),
                        ),
                      ],
                    );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBar(BuildContext context) {
    final s = signalLightStore.state;
    final label = switch (s) {
      SignalLightState.idle => '空闲',
      SignalLightState.working => '工作中',
      SignalLightState.attention => '需要关注',
      SignalLightState.blocked => '已阻塞',
    };
    final color = switch (s) {
      SignalLightState.idle => _green,
      SignalLightState.working => _yellow,
      SignalLightState.attention => _yellow,
      SignalLightState.blocked => _red,
    };
    final sessions = signalLightStore.activeSessions;
    final signal = signalLightStore.lastSignal;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            // 半透明毛玻璃：随灯态主色微染
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: context.theme.textMain,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (signal != null) ...[
            const SizedBox(width: 8),
            Text(
              signal,
              style: TextStyle(
                color: context.theme.textDim,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
          const SizedBox(width: 12),
          Text(
            '$sessions 会话',
            style: TextStyle(color: context.theme.textSub, fontSize: 11),
          ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _light(Color color, double intensity, double size) {
    // 发光强度跟随亮度
    final glow = intensity.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: glow > 0.2
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55 * glow),
                    blurRadius: 32 * glow,
                    spreadRadius: 4 * glow,
                  ),
                  BoxShadow(
                    color: color.withValues(alpha: 0.25 * glow),
                    blurRadius: 60 * glow,
                    spreadRadius: 10 * glow,
                  ),
                ]
              : null,
        ),
        child: ClipOval(
          child: LightShader(color: color, intensity: intensity),
        ),
      ),
    );
  }
}
