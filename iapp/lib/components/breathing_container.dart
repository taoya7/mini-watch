import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

/// 呼吸边框容器 —— 端口自 demo0505-01 的 CSS `cta-card-breathe`
/// （多层 box-shadow 在弱/强之间无限往返，非着色器）。
///
/// - [active] 为 true 时：边框环 + 两层外发光按 1.8s 一个周期呼吸；
/// - 为 false 时：平滑回落到无光静止态（0.6s 过渡）。
class BreathingContainer extends StatefulWidget {
  const BreathingContainer({
    super.key,
    required this.color,
    required this.borderRadius,
    required this.child,
    this.active = true,
  });

  /// 发光主色（红绿灯页传当前灯态色）
  final Color color;
  final BorderRadius borderRadius;
  final Widget child;

  /// 是否进入呼吸（运行中=true）
  final bool active;

  @override
  State<BreathingContainer> createState() => _BreathingContainerState();
}

class _BreathingContainerState extends State<BreathingContainer>
    with SingleTickerProviderStateMixin {
  // 半程 0.9s → 一来一回 1.8s 一个完整呼吸，对齐 CSS keyframe
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(BreathingContainer old) {
    super.didUpdateWidget(old);
    if (widget.active && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.active && _ctrl.isAnimating) {
      _ctrl.stop();
      // 平滑回落到静止（对应 CSS 的 transition .6s）
      _ctrl.animateBack(0, duration: const Duration(milliseconds: 600));
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// level 0 = 无光静止，1 = 最强；呼吸时在 [0.45, 1.0] 区间往返
  BoxDecoration _deco(double level) {
    final c = widget.color;
    return BoxDecoration(
      borderRadius: widget.borderRadius,
      border: Border.all(
        // 边框环：主要靠它体现呼吸
        color: c.withValues(alpha: lerpDouble(0.0, 0.55, level)!),
        width: 1.2,
      ),
      boxShadow: [
        // 仅一层很淡的近距外发光，blur/spread 收小
        BoxShadow(
          color: c.withValues(alpha: lerpDouble(0.0, 0.22, level)!),
          blurRadius: lerpDouble(8, 18, level)!,
          spreadRadius: lerpDouble(-2, 0, level)!,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      child: widget.child,
      builder: (context, child) {
        // ease-in-out + 限定呼吸下限，避免每次掉到全暗显得一闪一闪
        final t = Curves.easeInOut.transform(_ctrl.value);
        final level = widget.active ? lerpDouble(0.45, 1.0, t)! : t;
        return DecoratedBox(decoration: _deco(level), child: child);
      },
    );
  }
}
