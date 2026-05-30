import 'package:flutter/material.dart';

/// 统一进度条：固定高度 4、圆角自适应、可选渐变填充
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 4,
    this.gradient = true,
  });

  /// 进度 0–1
  final double value;

  /// 主色
  final Color color;

  /// 条高
  final double height;

  /// 是否使用主色渐变（默认开）
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final p = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Stack(
        children: [
          Container(
            height: height,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          FractionallySizedBox(
            widthFactor: p,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: gradient
                    ? LinearGradient(
                        colors: [color.withValues(alpha: 0.55), color],
                      )
                    : null,
                color: gradient ? null : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
